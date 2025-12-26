import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/storage/token_storage.dart';
import '../../features/auth/controllers/auth_controller.dart';
import '../../music_player/music_player_controller.dart';
import '../models/models.dart';

final repositoryProvider = Provider<Repository>((ref) {
  final client = ref.watch(apiClientProvider);
  return Repository(client, ref);
});

class Repository {
  Repository(this._client, this._ref);

  final ApiClient _client;
  final Ref _ref;

  Dio get _dio => _client.dio;

  Future<T> _guard<T>(Future<T> Function() runner) async {
    try {
      return await runner();
    } on DioException catch (error) {
      // Kiểm tra nếu error.error đã là ApiException (từ interceptor)
      final cause = error.error;
      if (cause is ApiException) {
        // Tự động logout khi 401 (session hết hạn)
        if (cause.statusCode == 401) {
          await _handleSessionExpired();
        }
        throw cause;
      }
      
      // Convert DioException thành ApiException
      final apiException = ApiException.fromDio(error);
      
      // Tự động logout khi 401 (session hết hạn)
      if (apiException.statusCode == 401) {
        await _handleSessionExpired();
      }
      
      throw apiException;
    } on ApiException catch (error) {
      // Nếu đã là ApiException rồi thì throw trực tiếp
      if (error.statusCode == 401) {
        await _handleSessionExpired();
      }
      rethrow;
    } catch (error) {
      // Xử lý các lỗi khác (không phải DioException)
      throw ApiException(
        error.toString(),
        statusCode: null,
      );
    }
  }

  /// Guard cho các API call không quan trọng (như savePlayHistory, increasePlayCount)
  /// Không trigger session expired khi có lỗi 401 để tránh navigate về home
  Future<T> _guardSilent<T>(Future<T> Function() runner) async {
    try {
      return await runner();
    } on DioException catch (error) {
      // Kiểm tra nếu error.error đã là ApiException (từ interceptor)
      final cause = error.error;
      if (cause is ApiException) {
        // Không gọi _handleSessionExpired() cho các API call không quan trọng
        // Chỉ throw exception để caller có thể handle
        throw cause;
      }
      
      // Convert DioException thành ApiException
      final apiException = ApiException.fromDio(error);
      // Không gọi _handleSessionExpired() - chỉ throw exception
      throw apiException;
    } on ApiException catch (error) {
      // Không gọi _handleSessionExpired() - chỉ rethrow
      rethrow;
    } catch (error) {
      // Xử lý các lỗi khác (không phải DioException)
      throw ApiException(
        error.toString(),
        statusCode: null,
      );
    }
  }

  /// Xử lý khi session hết hạn (401) - tự động logout và reset state
  /// Không gọi API logout để tránh vòng lặp, chỉ clear local state
  Future<void> _handleSessionExpired() async {
    // Reset auth state (không gọi API logout để tránh vòng lặp)
    // clearSessionOnly() sẽ clear storage và reset state
    final authController = _ref.read(authControllerProvider.notifier);
    await authController.clearSessionOnly(); // Clear session mà không gọi API
    
    // Reset music player state
    try {
      final musicPlayer = _ref.read(musicPlayerControllerProvider.notifier);
      musicPlayer.reset();
    } catch (_) {
      // Ignore if music player not initialized
    }
  }

  Future<AuthLoginResponse> login({
    required String username,
    required String password,
  }) {
    return _guard(() async {
      final res = await _dio.post<Map<String, dynamic>>(
        '/api/Auth/login',
        data: {'username': username, 'password': password},
      );
      return AuthLoginResponse.fromJson(res.data ?? const {});
    });
  }

  Future<void> logout() async {
    // Logout không throw exception - luôn thành công (kể cả khi backend lỗi)
    try {
      await _dio.post('/api/Auth/logout');
    } catch (_) {
      // Ignore logout errors - vẫn clear session
    }
  }

  Future<void> register(Map<String, dynamic> payload) {
    return _guard(() => _dio.post('/api/Auth/register', data: payload));
  }

  Future<void> sendOtp(String email) {
    return _guard(
      () => _dio.post('/api/Auth/send-otp', data: {'email': email}),
    );
  }

  Future<void> verifyOtp({
    required String email,
    required String otp,
  }) {
    return _guard(
      () => _dio.post(
        '/api/Auth/verify-otp',
        data: {'email': email, 'otp': otp},
      ),
    );
  }

  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) {
    return _guard(
      () => _dio.post(
        '/api/Auth/reset-password',
        data: {'email': email, 'otp': otp, 'newPassword': newPassword},
      ),
    );
  }

  Future<List<TrackSummary>> topPlayedTracks() {
    return _guard(() async {
      final res = await _dio.get<List<dynamic>>('/api/Track/top-played');
      return (res.data ?? const [])
          .map((e) => TrackSummary.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
    });
  }

  Future<List<TrackSummary>> topLikedTracks() {
    return _guard(() async {
      final res = await _dio.get<List<dynamic>>('/api/Track/top-like');
      return (res.data ?? const [])
          .map((e) => TrackSummary.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
    });
  }

  Future<TrackSummary> getTrackSummary(String trackId) {
    return _guard(() async {
      // Dùng track-detail endpoint như React frontend (trả về đầy đủ thông tin)
      final res =
          await _dio.get<Map<String, dynamic>>('/api/Track/track-detail/$trackId');
      final data = res.data ?? const {};
      
      // Map từ TrackInfo response sang TrackSummary
      // Backend trả về PascalCase: TrackId, Title, UploaderName, UploaderId, Genres, IsPublic, ImageBase64, LastUpdate, PlaysCount, LikesCount
      return TrackSummary(
        id: data['trackId']?.toString() ?? 
            data['TrackId']?.toString() ?? 
            data['id']?.toString() ?? 
            trackId,
        title: data['title']?.toString() ?? 
               data['Title']?.toString() ?? 
               'Tên nhạc',
        artistName: data['uploaderName']?.toString() ?? 
                    data['UploaderName']?.toString(),
        imageBase64: data['imageBase64']?.toString() ?? 
                     data['ImageBase64']?.toString(),
        isPublic: data['isPublic'] is bool
            ? data['isPublic'] as bool
            : (data['IsPublic'] is bool
                ? data['IsPublic'] as bool
                : (data['isPublic']?.toString().toLowerCase() != 'false' &&
                   data['IsPublic']?.toString().toLowerCase() != 'false')),
        playCount: data['playsCount'] is int
            ? data['playsCount'] as int
            : (data['PlaysCount'] is int
                ? data['PlaysCount'] as int
                : int.tryParse(data['playsCount']?.toString() ?? '') ??
                  int.tryParse(data['PlaysCount']?.toString() ?? '')),
        likeCount: data['likesCount'] is int
            ? data['likesCount'] as int
            : (data['LikesCount'] is int
                ? data['LikesCount'] as int
                : int.tryParse(data['likesCount']?.toString() ?? '') ??
                  int.tryParse(data['LikesCount']?.toString() ?? '')),
        genres: (data['genres'] as List?)
                ?.map((e) => e.toString())
                .toList(growable: false) ??
            (data['Genres'] as List?)
                ?.map((e) => e.toString())
                .toList(growable: false) ??
            const [],
      );
    });
  }

  Future<String> getTrackAudioUrl(String trackId) {
    return _guard(() async {
      // Backend endpoint /api/Track/audio/{id} trả về file stream
      // Cần build URL đầy đủ
      final baseUrl = AppConfig.apiBaseUrl;
      return '$baseUrl/api/Track/audio/$trackId';
    });
  }

  Future<void> increasePlayCount(String trackId) {
    // Dùng _guardSilent để không trigger session expired khi có lỗi 401
    // Vì đây là API call không quan trọng, không nên block playback hoặc navigate
    return _guardSilent(() => _dio.put('/api/Track/play-count/$trackId'));
  }

  Future<List<TrackSummary>> getTracksByArtist(String profileId) {
    return _guard(() async {
      final res =
          await _dio.get<Map<String, dynamic>>('/api/Profile/my-tracks/$profileId');
      // Response format: {tracks: [...]} (match React frontend)
      final tracks = res.data?['tracks'] as List<dynamic>? ?? const [];
      return tracks
          .map((e) => TrackSummary.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
    });
  }

  Future<List<TrackSummary>> getAllTracks() {
    return _guard(() async {
      final res = await _dio.get<List<dynamic>>('/api/Track/all-track');
      return (res.data ?? const [])
          .map((e) => TrackSummary.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
    });
  }

  Future<void> approveTrack(String trackId) {
    return _guard(() => _dio.put('/api/Track/approve/$trackId'));
  }

  Future<void> togglePublicTrack(String trackId) {
    return _guard(() => _dio.put('/api/Track/public/$trackId'));
  }

  Future<void> deleteTrack(String trackId) {
    return _guard(() => _dio.delete('/api/Track/delete/$trackId'));
  }

  Future<void> restoreTrack(String trackId) {
    return _guard(() => _dio.put('/api/Track/restore/$trackId'));
  }

  Future<int> getPendingTracksCount() {
    return _guard(() async {
      final res = await _dio.get<Map<String, dynamic>>('/api/Track/pending-count');
      return res.data?['count'] as int? ?? 0;
    });
  }

  Future<List<CommentItem>> getComments(String trackId) {
    if (trackId.isEmpty) return Future.value(const []);
    return _guard(() async {
      try {
        final res =
            await _dio.get<List<dynamic>>('/api/Comment/comments/$trackId');
        return (res.data ?? const [])
            .map((e) => CommentItem.fromJson(e as Map<String, dynamic>))
            .toList(growable: false);
      } catch (e) {
        // Nếu lỗi (404, 405, etc) thì trả về empty list
        return const [];
      }
    });
  }

  Future<void> addComment(String trackId, String content) {
    return _guard(
      () => _dio.post(
        '/api/Comment/comments',
        data: {'trackId': trackId, 'content': content},
      ),
    );
  }

  Future<void> deleteComment(String commentId) {
    return _guard(
      () => _dio.delete('/api/Comment/delete-comment/$commentId'),
    );
  }

  Future<List<TrackSummary>> getFavoriteTracks() {
    return _guard(() async {
      final res =
          await _dio.get<List<dynamic>>('/api/Favorites/my-tracks');
      return (res.data ?? const [])
          .map((e) => TrackSummary.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
    });
  }

  Future<void> toggleFavorite(String trackId) {
    return _guard(() => _dio.post('/api/Favorites/toggle/$trackId'));
  }

  Future<bool> isFavorite(String trackId) {
    if (trackId.isEmpty) return Future.value(false);
    return _guard(() async {
      try {
        final res =
            await _dio.get<Map<String, dynamic>>('/api/Favorites/check/$trackId');
        // Backend có thể trả về 'favorited' hoặc 'isFavorite'
        return res.data?['favorited'] as bool? ?? 
               res.data?['isFavorite'] as bool? ?? 
               false;
      } catch (e) {
        // Nếu lỗi (404, 401, etc) thì trả về false
        return false;
      }
    });
  }

  Future<void> deleteAllFavorites() {
    return _guard(() => _dio.delete('/api/Favorites/delete-all'));
  }

  Future<List<TrackSummary>> getHistory(String userId) {
    return _guard(() async {
      final res =
          await _dio.get<List<dynamic>>('/api/History/user/$userId');
      return (res.data ?? const [])
          .map((e) {
            final json = e as Map<String, dynamic>;
            // Backend trả về HistoryTrackResponse với lastPlay (camelCase)
            // Cần map đúng để parse lastPlay
            return TrackSummary.fromJson({
              ...json,
              'id': json['trackId'] ?? json['id'],
              'lastPlay': json['lastPlay'] ?? json['LastPlay'],
            });
          })
          .toList(growable: false);
    });
  }

  Future<void> deleteHistoryTrack(String trackId) {
    return _guard(() => _dio.delete('/api/History/delete/$trackId'));
  }

  Future<void> deleteAllHistory() {
    return _guard(() => _dio.delete('/api/History/delete-all'));
  }

  Future<void> savePlayHistory(String trackId) {
    // Dùng _guardSilent để không trigger session expired khi có lỗi 401
    // Vì đây là API call không quan trọng, không nên block playback hoặc navigate
    return _guardSilent(() => _dio.post('/api/History/play/$trackId'));
  }

  Future<List<NotificationItem>> getNotifications(String userId) {
    return _guard(() async {
      final res = await _dio
          .get<List<dynamic>>('/api/Notification/my-notification/$userId');
      return (res.data ?? const [])
          .map((e) => NotificationItem.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
    });
  }

  Future<void> markNotificationViewed(String id) {
    return _guard(() => _dio.put('/api/Notification/mark-viewed/$id'));
  }

  Future<PlaylistDetail> getPlaylistDetail(String playlistId) {
    return _guard(() async {
      final res = await _dio.get<Map<String, dynamic>>('/api/Playlist/$playlistId');
      return PlaylistDetail.fromJson(res.data ?? const {});
    });
  }

  Future<List<PlaylistSummary>> getUserPlaylists(String userId) {
    return _guard(() async {
      final res =
          await _dio.get<List<dynamic>>('/api/Playlist/user/$userId');
      return (res.data ?? const [])
          .map((e) => PlaylistSummary.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
    });
  }

  Future<void> createPlaylist(Map<String, dynamic> payload) {
    return _guard(() => _dio.post('/api/Playlist', data: payload));
  }

  Future<void> updatePlaylist(String playlistId, Map<String, dynamic> payload) {
    return _guard(
      () => _dio.put('/api/Playlist/$playlistId', data: payload),
    );
  }

  Future<void> deletePlaylist(String playlistId) {
    return _guard(() => _dio.delete('/api/Playlist/$playlistId'));
  }

  Future<void> addTrackToPlaylist(String playlistId, String trackId) {
    return _guard(
      () => _dio.post(
        '/api/Playlist/$playlistId/tracks',
        data: {'trackId': trackId},
      ),
    );
  }

  Future<void> removeTrackFromPlaylist(String playlistId, String trackId) {
    return _guard(
      () => _dio.delete('/api/Playlist/$playlistId/tracks/$trackId'),
    );
  }

  Future<PlaylistLimits> getPlaylistLimits(String userId) {
    return _guard(() async {
      final res = await _dio.get<Map<String, dynamic>>(
        '/api/Playlist/limits/$userId',
      );
      return PlaylistLimits.fromJson(res.data ?? const {});
    });
  }

  Future<ProfileData> getMyProfile(String userId) {
    return _guard(() async {
      final res = await _dio
          .get<Map<String, dynamic>>('/api/Profile/my-profile/$userId');
      return ProfileData.fromJson(res.data ?? const {});
    });
  }

  Future<ProfileData> getProfile(String userId) {
    return _guard(() async {
      final res =
          await _dio.get<Map<String, dynamic>>('/api/Profile/profile/$userId');
      return ProfileData.fromJson(res.data ?? const {});
    });
  }

  Future<void> updateProfile(String userId, Map<String, dynamic> payload) {
    return _guard(
      () => _dio.put('/api/Profile/personal/$userId', data: payload),
    );
  }

  Future<void> updateProfileAvatar(String userId, FormData data) {
    return _guard(
      () => _dio.put(
        '/api/Profile/personal-avt/$userId',
        data: data,
        options: Options(contentType: Headers.multipartFormDataContentType),
      ),
    );
  }

  Future<void> updateAddress(String userId, String address) {
    return _guard(
      () => _dio.put(
        '/api/Profile/address/$userId',
        data: {'address': address},
      ),
    );
  }

  Future<void> changePassword({
    required String userId,
    required String oldPassword,
    required String newPassword,
  }) {
    return _guard(
      () => _dio.post(
        '/api/Profile/change-password/$userId',
        data: {
          'oldPassword': oldPassword,
          'newPassword': newPassword,
        },
      ),
    );
  }

  Future<void> sendVerifyEmailOtp(String userId) {
    return _guard(() => _dio.post('/api/Profile/send-verify-email-otp/$userId'));
  }

  Future<void> verifyEmailOtp(String userId, String otp) {
    return _guard(
      () => _dio.post(
        '/api/Profile/verify-email-otp/$userId',
        data: {'otp': otp},
      ),
    );
  }

  Future<SearchResults> search(String query) {
    return _guard(() async {
      final res = await _dio.get<Map<String, dynamic>>(
        '/api/search',
        queryParameters: {'query': query},
      );
      return SearchResults.fromJson(res.data ?? const {});
    });
  }

  Future<List<TrackSummary>> recommendTracks(String userId) {
    return _guard(() async {
      final res = await _dio
          .get<List<dynamic>>('/api/Track/recommend-track/$userId');
      return (res.data ?? const [])
          .map((e) => TrackSummary.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
    });
  }

  Future<List<FollowUser>> getFollowing(String userId) {
    return _guard(() async {
      final res = await _dio
          .get<Map<String, dynamic>>('/api/Followers/FollowingList/$userId');
      final list = res.data?['followingList'] as List<dynamic>? ?? const [];
      return list
          .map((e) => FollowUser.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
    });
  }

  Future<void> followUser(String userId) {
    return _guard(() => _dio.post('/api/Followers/follow/$userId'));
  }

  Future<void> unfollowUser(String userId) {
    return _guard(() => _dio.delete('/api/Followers/unfollow/$userId'));
  }

  Future<bool> checkFollowing(String followerId, String followingId) {
    return _guard(() async {
      // Backend endpoint: /api/Followers/check/{userId}
      // Backend tự lấy followerId từ JWT token, chỉ cần truyền followingId
      final res = await _dio.get<Map<String, dynamic>>(
        '/api/Followers/check/$followingId',
      );
      return res.data?['Following'] as bool? ??
          res.data?['following'] as bool? ??
          res.data?['isFollowing'] as bool? ??
          false;
    });
  }

  Future<String> requestPaymentUrl(Map<String, dynamic> payload) {
    return _guard(() async {
      // Send as JSON object (not string) - Dio will handle serialization
      final res = await _dio.post<dynamic>(
        '/api/VnPay/create',
        data: payload,
        options: Options(
          headers: {'Content-Type': Headers.jsonContentType},
        ),
      );
      if (res.data is Map<String, dynamic>) {
        return (res.data as Map<String, dynamic>)['url']?.toString() ?? '';
      }
      return res.data?.toString() ?? '';
    });
  }

  /// Xử lý callback từ VNPay sau khi thanh toán
  /// Query params từ VNPay sẽ được truyền vào đây
  Future<Map<String, dynamic>> processPaymentReturn(Map<String, String> queryParams) {
    return _guard(() async {
      final res = await _dio.get<dynamic>(
        '/api/VnPay/return',
        queryParameters: queryParams,
      );
      if (res.data is Map<String, dynamic>) {
        return res.data as Map<String, dynamic>;
      }
      return {'success': false, 'message': 'Invalid response format'};
    });
  }

  Future<List<PaymentRecord>> getRevenueByTime({
    required String from,
    required String to,
  }) {
    return _guard(() async {
      final res = await _dio.get<List<dynamic>>(
        '/api/PaymentRecord/by-time',
        queryParameters: {'from': from, 'to': to},
      );
      return (res.data ?? const [])
          .map((e) => PaymentRecord.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
    });
  }

  Future<List<PaymentRecord>> getRevenueByTier(String tier) {
    return _guard(() async {
      final res = await _dio.get<List<dynamic>>(
        '/api/PaymentRecord/by-tier',
        queryParameters: {'tier': tier},
      );
      return (res.data ?? const [])
          .map((e) => PaymentRecord.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
    });
  }

  Future<String> uploadTrack(
    UploadTrackPayload payload, {
    void Function(int sent, int total)? onSendProgress,
  }) {
    return _guard(() async {
      // Build FormData tương tự React: append từng genre riêng
      final formData = FormData();
      
      // Append basic fields
      formData.fields.add(MapEntry('Title', payload.title));
      if (payload.album != null && payload.album!.isNotEmpty) {
        formData.fields.add(MapEntry('Album', payload.album!));
      }
      if (payload.artistId != null && payload.artistId!.isNotEmpty) {
        formData.fields.add(MapEntry('ArtistId', payload.artistId!));
      }
      
      // Append genres - mỗi genre một entry (tương tự React: genres.forEach(g => formData.append('genre', g)))
      for (final genre in payload.genres) {
        formData.fields.add(MapEntry('Genre', genre));
      }
      
      // Append cover as base64 string (React: formData.append('cover', reader.result))
      if (payload.coverBase64 != null) {
        formData.fields.add(MapEntry('Cover', payload.coverBase64!));
      }
      
      // Append isPublic (true = nhạc thường, false = VIP)
      formData.fields.add(MapEntry('IsPublic', payload.isPublic.toString()));
      
      // Append file (React: formData.append('file', values.file))
      formData.files.add(MapEntry(
        'File',
        await MultipartFile.fromFile(
          payload.filePath,
          filename: payload.filePath.split('/').last,
        ),
      ));

      final res = await _dio.post<String>(
        '/api/Track/upload',
        data: formData,
        options: Options(
          contentType: Headers.multipartFormDataContentType,
          responseType: ResponseType.plain,
        ),
        onSendProgress: onSendProgress != null
            ? (sent, total) => onSendProgress(sent, total)
            : null,
      );
      return res.data ?? 'Thành công';
    });
  }

  /// Upload avatar với progress callback
  Future<void> uploadAvatar(
    String userId,
    String filePath, {
    void Function(int sent, int total)? onSendProgress,
  }) {
    return _guard(() async {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          filePath,
          filename: filePath.split('/').last,
        ),
      });

      await _dio.put(
        '/api/Profile/personal-avt/$userId',
        data: formData,
        options: Options(
          contentType: Headers.multipartFormDataContentType,
        ),
        onSendProgress: onSendProgress != null
            ? (sent, total) => onSendProgress(sent, total)
            : null,
      );
    });
  }
}

