import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/utils/image_utils.dart' show tryDecodeBase64Image, buildAvatarProvider;
import '../../data/models/models.dart';
import '../../data/repositories/repository.dart';
import '../../features/auth/controllers/auth_controller.dart';
import '../../music_player/music_player_controller.dart';
import '../../widgets/app_page.dart';
import '../../widgets/async_value_widget.dart';

final searchProvider =
    FutureProvider.autoDispose.family<SearchResults, String>((ref, query) async {
  if (query.isEmpty) {
    return const SearchResults(tracks: [], users: []);
  }
  final repository = ref.watch(repositoryProvider);
  return repository.search(query);
});

final followingStatusProvider =
    FutureProvider.autoDispose.family<bool, String>((ref, followingId) async {
  if (followingId.isEmpty) return false;
  final session = ref.watch(authControllerProvider).session;
  if (session == null) return false;
  final repository = ref.watch(repositoryProvider);
  // Backend endpoint chỉ cần followingId, tự lấy followerId từ JWT
  return repository.checkFollowing(session.id, followingId);
});

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key, this.initialQuery = ''});

  final String initialQuery;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _controller;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
    _query = widget.initialQuery;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(searchProvider(_query));

    return AppPage(
      title: 'Tìm kiếm',
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Bài hát, nghệ sĩ, playlist...',
                hintStyle: const TextStyle(fontSize: 14),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => _runSearch(_controller.text),
                ),
              ),
              onSubmitted: _runSearch,
            ),
            const SizedBox(height: 24),
            Expanded(
              child: AsyncValueWidget(
                value: results,
                data: (data) => _SearchResultsList(results: data),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _runSearch(String value) {
    final query = value.trim();
    if (query.isEmpty) return;
    if (query == _query) {
      ref.invalidate(searchProvider(query));
    }
    setState(() => _query = query);
  }
}

class _SearchResultsList extends ConsumerWidget {
  const _SearchResultsList({required this.results});

  final SearchResults results;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(musicPlayerControllerProvider.notifier);
    if (results.tracks.isEmpty && results.users.isEmpty) {
      return const Center(child: Text('Không tìm thấy kết quả'));
    }
    return ListView(
      children: [
        if (results.tracks.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bài hát',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              ...results.tracks.map(
                (track) => ListTile(
                  leading: CircleAvatar(
                    backgroundImage: _trackImage(track.imageBase64),
                  ),
                  title: Text(
                    track.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(track.artistName ?? 'BoxMusic'),
                  trailing: IconButton(
                    icon: const Icon(Icons.play_arrow),
                    onPressed: () => controller.playTracks(
                      results.tracks,
                      startIndex: results.tracks.indexOf(track),
                    ),
                  ),
                  onTap: () => context.go('/track/${track.id}'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        if (results.users.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Người dùng',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              ...results.users.map(
                (user) {
                  final session = ref.watch(authControllerProvider).session;
                  final isCurrentUser = session?.id == user.id;
                  // Chỉ watch provider khi cần thiết và có session
                  // Sử dụng followingId làm key thay vì Map để tránh rebuild không cần thiết
                  final followingStatus = !isCurrentUser && session != null
                      ? ref.watch(followingStatusProvider(user.id))
                      : null;
                  
                  return ListTile(
                    key: ValueKey('user_${user.id}'),
                    leading: CircleAvatar(
                      backgroundImage: _avatarImage(user.avatarBase64),
                    ),
                    title: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        user.fullname,
                        style: const TextStyle(fontSize: 16),
                        maxLines: 1,
                      ),
                    ),
                    subtitle: Text('@${user.username ?? 'BoxMusic'}'),
                    trailing: !isCurrentUser && session != null
                        ? _FollowButton(
                            userId: user.id,
                            session: session!,
                            followingStatus: followingStatus!,
                          )
                        : null,
                    onTap: () => context.go('/personal-profile/${user.id}'),
                  );
                },
              ),
            ],
          ),
      ],
    );
  }

  ImageProvider _trackImage(String? data) {
    // Ưu tiên decode base64 (giữ hành vi cũ)
    final bytes = tryDecodeBase64Image(data);
    if (bytes != null) return MemoryImage(bytes);

    if (data == null || data.isEmpty) {
      return const AssetImage('assets/images/default-music.jpg');
    }

    // URL tuyệt đối
    if (data.startsWith('http://') || data.startsWith('https://')) {
      String imageUrl = data;
      final baseUrl = AppConfig.apiBaseUrl.replaceAll('/api', '');
      if (imageUrl.contains('localhost:') || imageUrl.contains('127.0.0.1:')) {
        final uri = Uri.parse(imageUrl);
        imageUrl = '$baseUrl${uri.path}';
      }
      return NetworkImage(imageUrl);
    }

    // Đường dẫn tương đối từ backend
    if (data.startsWith('/')) {
      final baseUrl = AppConfig.apiBaseUrl.replaceAll('/api', '');
      return NetworkImage('$baseUrl$data');
    }

    // Fallback
    return const AssetImage('assets/images/default-music.jpg');
  }

  ImageProvider _avatarImage(String? data) {
    return buildAvatarProvider(data);
  }
}

class _FollowButton extends ConsumerStatefulWidget {
  const _FollowButton({
    required this.userId,
    required this.session,
    required this.followingStatus,
  });

  final String userId;
  final UserSession session;
  final AsyncValue<bool> followingStatus;

  @override
  ConsumerState<_FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends ConsumerState<_FollowButton> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return AsyncValueWidget(
      value: widget.followingStatus,
      data: (isFollowing) => TextButton(
        onPressed: _isProcessing ? null : () => _handleFollow(isFollowing),
        child: _isProcessing
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(isFollowing ? 'Đang theo dõi' : 'Theo dõi'),
      ),
      loading: const SizedBox(
        width: 80,
        height: 36,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (error, stack) => TextButton(
        onPressed: _isProcessing ? null : () => _handleFollow(false),
        child: const Text('Theo dõi'),
      ),
    );
  }

  Future<void> _handleFollow(bool isFollowing) async {
    if (_isProcessing) return;
    
    setState(() => _isProcessing = true);
    
    try {
      final repository = ref.read(repositoryProvider);
      if (isFollowing) {
        await repository.unfollowUser(widget.userId);
      } else {
        await repository.followUser(widget.userId);
      }
      
      // Refresh following status
      ref.invalidate(followingStatusProvider(widget.userId));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isFollowing ? 'Đã bỏ theo dõi' : 'Đã theo dõi'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }
}

