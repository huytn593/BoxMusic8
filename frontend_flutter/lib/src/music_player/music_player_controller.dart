import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../data/models/models.dart';
import '../data/repositories/repository.dart';
import '../features/auth/controllers/auth_controller.dart';

final musicPlayerControllerProvider =
    StateNotifierProvider<MusicPlayerController, MusicPlayerState>((ref) {
  final repository = ref.watch(repositoryProvider);
  return MusicPlayerController(repository, ref);
});

const kErrorRequireLogin = 'Vui lòng đăng nhập để nghe bài hát này';
const kErrorRequireVip = 'Bạn cần nâng cấp VIP để nghe bài hát này';

class MusicPlayerState {
  const MusicPlayerState({
    required this.playlist,
    required this.currentIndex,
    required this.isPlaying,
    required this.position,
    required this.duration,
    required this.loading,
    this.errorMessage,
  });

  factory MusicPlayerState.initial() => const MusicPlayerState(
        playlist: [],
        currentIndex: 0,
        isPlaying: false,
        position: Duration.zero,
        duration: Duration.zero,
        loading: false,
      );

  final List<TrackSummary> playlist;
  final int currentIndex;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final bool loading;
  final String? errorMessage;

  TrackSummary? get currentTrack =>
      playlist.isEmpty ? null : playlist[currentIndex];

  MusicPlayerState copyWith({
    List<TrackSummary>? playlist,
    int? currentIndex,
    bool? isPlaying,
    Duration? position,
    Duration? duration,
    bool? loading,
    String? errorMessage,
  }) {
    return MusicPlayerState(
      playlist: playlist ?? this.playlist,
      currentIndex: currentIndex ?? this.currentIndex,
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      loading: loading ?? this.loading,
      errorMessage: errorMessage,
    );
  }
}

class MusicPlayerController extends StateNotifier<MusicPlayerState> {
  MusicPlayerController(this._repository, this._ref)
      : _audioPlayer = AudioPlayer(),
        super(MusicPlayerState.initial()) {
    _subscriptions.add(
      _audioPlayer.playerStateStream.listen((playerState) {
        // Chỉ cập nhật isPlaying, không thay đổi các field khác để tránh rebuild không cần thiết
        if (state.isPlaying != (playerState.playing &&
            playerState.processingState != ProcessingState.completed)) {
          state = state.copyWith(
            isPlaying: playerState.playing &&
                playerState.processingState != ProcessingState.completed,
          );
        }
      }),
    );

    _subscriptions.add(
      _audioPlayer.positionStream.listen(
        (position) => state = state.copyWith(position: position),
      ),
    );

    _subscriptions.add(
      _audioPlayer.durationStream.listen(
        (duration) =>
            state = state.copyWith(duration: duration ?? Duration.zero),
      ),
    );

    _subscriptions.add(
      _audioPlayer.processingStateStream.listen((processingState) {
        if (processingState == ProcessingState.completed) {
          next();
        }
      }),
    );
  }

  final Repository _repository;
  final Ref _ref;
  final AudioPlayer _audioPlayer;
  final _subscriptions = <StreamSubscription<dynamic>>[];

  /// Get current user session
  UserSession? get _userSession {
    final authState = _ref.read(authControllerProvider);
    return authState.session;
  }

  /// Check if user can access VIP track
  /// Người dùng chưa đăng nhập vẫn nghe được nhạc public
  bool _canAccessVipTrack(TrackSummary track) {
    // Public tracks - everyone can access (kể cả chưa đăng nhập)
    if (track.isPublic) return true;
    
    // VIP tracks - need VIP, Premium, or Admin role (phải đăng nhập)
    final session = _userSession;
    if (session == null) return false;
    return session.canAccessVipTracks;
  }

  Future<void> playTracks(
    List<TrackSummary> tracks, {
    int startIndex = 0,
  }) async {
    if (tracks.isEmpty) return;
    startIndex = startIndex.clamp(0, tracks.length - 1);
    state = state.copyWith(
      playlist: List.unmodifiable(tracks),
      currentIndex: startIndex,
      loading: true,
      errorMessage: null,
    );
    await _loadCurrentTrack();
  }

  Future<void> _loadCurrentTrack() async {
    final track = state.currentTrack;
    if (track == null) {
      state = state.copyWith(loading: false);
      return;
    }

    // Check VIP permission (tương tự React checkVipPermission)
    if (!_canAccessVipTrack(track)) {
      state = state.copyWith(
        loading: false,
        isPlaying: false,
        errorMessage: _userSession == null ? kErrorRequireLogin : kErrorRequireVip,
      );
      return;
    }

    try {
      final audioUrl = track.audioUrl ?? await _repository.getTrackAudioUrl(track.id);
      
      if (kDebugMode) {
        print('🎵 [MusicPlayer] Loading audio from: $audioUrl');
      }
      
      // Lưu lịch sử phát
      try {
      await _repository.savePlayHistory(track.id);
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ [MusicPlayer] Failed to save play history: $e');
        }
        // Không block playback nếu lưu history thất bại
      }
      
      // Load và play audio
      await _audioPlayer.setUrl(audioUrl);
      
      if (kDebugMode) {
        print('✅ [MusicPlayer] Audio URL set successfully');
      }
      
      await _audioPlayer.play();
      
      if (kDebugMode) {
        print('✅ [MusicPlayer] Audio playback started');
      }
      
      // Tăng play count (không block nếu thất bại)
      try {
      await _repository.increasePlayCount(track.id);
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ [MusicPlayer] Failed to increase play count: $e');
        }
      }
      
      state = state.copyWith(
        loading: false,
        // isPlaying được cập nhật từ stream listener
        errorMessage: null,
      );
    } catch (error, stackTrace) {
      // Log chi tiết lỗi để debug
      if (kDebugMode) {
        print('❌ [MusicPlayer] Error loading/playing audio:');
        print('   Error: $error');
        print('   StackTrace: $stackTrace');
      }
      
      // Xử lý lỗi và hiển thị message thân thiện với user
      String errorMsg = 'Không thể phát nhạc. Vui lòng thử lại.';
      
      final errorStr = error.toString().toLowerCase();
      
      if (errorStr.contains('cleartext http traffic not permitted')) {
        errorMsg = 'Lỗi kết nối: Vui lòng kiểm tra cấu hình mạng';
      } else if (errorStr.contains('network') || 
                 errorStr.contains('connection') ||
                 errorStr.contains('socket') ||
                 errorStr.contains('timeout')) {
        errorMsg = 'Lỗi kết nối mạng. Vui lòng kiểm tra kết nối internet và thử lại';
      } else if (errorStr.contains('404') || 
                 errorStr.contains('not found') ||
                 errorStr.contains('file not found')) {
        errorMsg = 'Không tìm thấy file nhạc. Bài hát có thể đã bị xóa';
      } else if (errorStr.contains('401') || errorStr.contains('unauthorized')) {
        errorMsg = 'Bạn cần đăng nhập để nghe nhạc';
      } else if (errorStr.contains('403') || errorStr.contains('forbidden')) {
        errorMsg = 'Bạn không có quyền nghe bài hát này';
      } else if (errorStr.contains('500') || errorStr.contains('server error')) {
        errorMsg = 'Lỗi máy chủ. Vui lòng thử lại sau';
      } else {
        // Hiển thị lỗi chi tiết hơn trong debug mode
        if (kDebugMode) {
          errorMsg = 'Lỗi: ${error.toString()}';
        }
      }
      
      state = state.copyWith(
        loading: false,
        isPlaying: false,
        errorMessage: errorMsg,
      );
    }
  }

  Future<void> togglePlay() async {
    // Cho phép bấm play/pause ngay cả khi đang loading,
    // chỉ cần đảm bảo đã có currentTrack trong playlist
    if (state.currentTrack == null) return;
    
    // Optimistic update removed - Rely on stream listener
    
    try {
      if (!state.isPlaying) {
        // Nếu chưa có audio URL hoặc player chưa ready, cần load lại
        if (_audioPlayer.duration == null || 
            _audioPlayer.duration == Duration.zero ||
            _audioPlayer.processingState == ProcessingState.idle ||
            _audioPlayer.processingState == ProcessingState.loading) {
          // Load track (sẽ set loading = true trong _loadCurrentTrack)
          await _loadCurrentTrack();
        } else {
          // Play ngay lập tức (không await để không block UI)
          _audioPlayer.play().catchError((error) {
             if (kDebugMode) {
              print('❌ [MusicPlayer] Play failed: $error');
            }
          });
        }
      } else {
        // Pause ngay lập tức (không await để không block UI)
        _audioPlayer.pause().catchError((error) {
            if (kDebugMode) {
            print('❌ [MusicPlayer] Pause failed: $error');
          }
        });
      }
    } catch (e) {
      if (kDebugMode) {
          print('❌ [MusicPlayer] Toggle play error: $e');
      }
    }
  }

  Future<void> seek(Duration position) async {
    if (state.currentTrack == null) return;
    await _audioPlayer.seek(position);
  }

  Future<void> next() async {
    if (state.playlist.isEmpty) return;
    final nextIndex = (state.currentIndex + 1) % state.playlist.length;
    state = state.copyWith(
      currentIndex: nextIndex,
      loading: true,
      position: Duration.zero,
      duration: Duration.zero,
    );
    await _loadCurrentTrack();
  }

  Future<void> previous() async {
    if (state.playlist.isEmpty) return;
    final previousIndex = state.currentIndex == 0
        ? state.playlist.length - 1
        : state.currentIndex - 1;
    state = state.copyWith(
      currentIndex: previousIndex,
      loading: true,
      position: Duration.zero,
      duration: Duration.zero,
    );
    await _loadCurrentTrack();
  }

  /// Xử lý khi track bị xóa - dừng phát nếu đang phát track đó
  void handleTrackDeleted(String trackId) {
    final currentTrack = state.currentTrack;
    if (currentTrack?.id == trackId) {
      // Nếu đang phát track bị xóa, dừng và xóa khỏi playlist
      _audioPlayer.stop();
      final newPlaylist = state.playlist.where((t) => t.id != trackId).toList();
      if (newPlaylist.isEmpty) {
        // Nếu playlist rỗng, reset player
        reset();
      } else {
        // Nếu còn track, chuyển sang track tiếp theo hoặc track trước
        final newIndex = state.currentIndex >= newPlaylist.length
            ? newPlaylist.length - 1
            : state.currentIndex;
        state = state.copyWith(
          playlist: List.unmodifiable(newPlaylist),
          currentIndex: newIndex.clamp(0, newPlaylist.length - 1),
          isPlaying: false,
          loading: false,
          errorMessage: 'Bài hát đã bị xóa',
        );
        // Nếu còn track, load track mới
        if (newPlaylist.isNotEmpty) {
          _loadCurrentTrack();
        }
      }
    } else {
      // Nếu không phải track hiện tại, chỉ xóa khỏi playlist
      final newPlaylist = state.playlist.where((t) => t.id != trackId).toList();
      if (newPlaylist.isNotEmpty) {
        // Điều chỉnh currentIndex nếu cần
        final newIndex = state.currentIndex >= newPlaylist.length
            ? newPlaylist.length - 1
            : state.currentIndex;
        state = state.copyWith(
          playlist: List.unmodifiable(newPlaylist),
          currentIndex: newIndex.clamp(0, newPlaylist.length - 1),
        );
      } else {
        // Nếu playlist rỗng, reset player
        reset();
      }
    }
  }

  /// Reset player state - dùng khi logout hoặc session hết hạn
  Future<void> reset() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.seek(Duration.zero);
    } catch (_) {
      // Ignore errors
    }
    state = MusicPlayerState.initial();
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _audioPlayer.dispose();
    super.dispose();
  }
}

