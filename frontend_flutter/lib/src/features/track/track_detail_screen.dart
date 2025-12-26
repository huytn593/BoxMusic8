import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/utils/image_utils.dart' show tryDecodeBase64Image, buildAvatarProvider;
import '../../data/models/models.dart';
import '../../data/repositories/repository.dart';
import '../../music_player/music_player_controller.dart';
import '../../widgets/app_page.dart';
import '../../widgets/async_value_widget.dart';
import '../auth/controllers/auth_controller.dart';

final trackInfoProvider =
    FutureProvider.autoDispose.family<TrackSummary, String>((ref, trackId) async {
  final repository = ref.watch(repositoryProvider);
  return repository.getTrackSummary(trackId);
});

final commentsProvider =
    FutureProvider.autoDispose.family<List<CommentItem>, String>((ref, trackId) {
  final repository = ref.watch(repositoryProvider);
  return repository.getComments(trackId);
});

final favoriteStatusProvider =
    FutureProvider.autoDispose.family<bool, String>((ref, trackId) async {
  final repository = ref.watch(repositoryProvider);
  return repository.isFavorite(trackId);
});

class TrackDetailScreen extends ConsumerWidget {
  const TrackDetailScreen({super.key, required this.trackId});

  final String trackId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final track = ref.watch(trackInfoProvider(trackId));

    return AppPage(
      title: 'Chi tiết bài hát',
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: AsyncValueWidget(
          value: track,
          data: (track) => _TrackDetailBody(track: track),
        ),
      ),
    );
  }
}

class _TrackDetailBody extends ConsumerWidget {
  const _TrackDetailBody({required this.track});

  final TrackSummary track;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authControllerProvider).session;
    final controller = ref.read(musicPlayerControllerProvider.notifier);
    
    // Chỉ load favorite và comments nếu có trackId hợp lệ và user đã đăng nhập
    final favorite = track.id.isNotEmpty && session != null
        ? ref.watch(favoriteStatusProvider(track.id))
        : null;
    final comments = track.id.isNotEmpty
        ? ref.watch(commentsProvider(track.id))
        : null;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        // Layout responsive: Stack trên màn hình nhỏ, Row trên màn hình lớn
        LayoutBuilder(
          builder: (context, constraints) {
            // Nếu màn hình nhỏ hơn 600px, dùng Column layout
            if (constraints.maxWidth < 600) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 200,
                        height: 200,
                        child: _TrackCover(data: track.imageBase64),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _TrackInfo(
                    track: track,
                    favorite: favorite,
                    session: session,
                    controller: controller,
                  ),
                ],
              );
            }
            // Màn hình lớn: dùng Row layout
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 160,
                    height: 160,
                    child: _TrackCover(data: track.imageBase64),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: _TrackInfo(
                    track: track,
                    favorite: favorite,
                    session: session,
                    controller: controller,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 32),
        Text(
          'Bình luận',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        _CommentInput(trackId: track.id),
        const SizedBox(height: 16),
        if (comments != null)
          AsyncValueWidget(
            value: comments,
            data: (items) => items.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: Text(
                        'Chưa có bình luận nào',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(color: Colors.white12),
                    itemBuilder: (context, index) {
                      final comment = items[index];
                      final session = ref.watch(authControllerProvider).session;
                      final canDelete = session != null && 
                          (session.id == comment.userId || session.isAdmin);
                      
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: _avatarProvider(comment.avatarBase64),
                        ),
                        title: Text(comment.authorName),
                        subtitle: Text(
                          comment.content,
                          // Không giới hạn số dòng, text sẽ tự wrap
                        ),
                        isThreeLine: true, // Cho phép subtitle wrap nhiều dòng
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _formatDate(comment.createdAt),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.white54,
                                  ),
                            ),
                            if (canDelete) ...[
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 20),
                                color: Colors.red,
                                onPressed: () => _deleteComment(context, ref, comment.id, track.id),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
            loading: const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'Không thể tải bình luận',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ),
          )
        else
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: Text(
                'Không thể tải bình luận',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }

  Future<void> _deleteComment(
    BuildContext context,
    WidgetRef ref,
    String commentId,
    String trackId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa bình luận'),
        content: const Text('Bạn có chắc chắn muốn xóa bình luận này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(repositoryProvider).deleteComment(commentId);
      if (!context.mounted) return;
      ref.invalidate(commentsProvider(trackId));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xóa bình luận')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể xóa bình luận: $error')),
      );
    }
  }
}

class _TrackInfo extends ConsumerWidget {
  const _TrackInfo({
    required this.track,
    required this.favorite,
    required this.session,
    required this.controller,
  });

  final TrackSummary track;
  final AsyncValue<bool>? favorite;
  final UserSession? session;
  final MusicPlayerController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          track.title,
          style: Theme.of(context).textTheme.headlineMedium,
          // Không giới hạn số dòng, text sẽ tự wrap
        ),
        const SizedBox(height: 8),
        Text(
          track.artistName ?? 'BoxMusic',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white70),
          // Không giới hạn số dòng, text sẽ tự wrap
        ),
        if (track.genres.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: track.genres.map((genre) => Chip(
              label: Text(genre),
              labelStyle: const TextStyle(fontSize: 12),
            )).toList(),
          ),
        ],
        if (track.playCount != null || track.likeCount != null) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              if (track.playCount != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.play_arrow, size: 16, color: Colors.white70),
                    const SizedBox(width: 4),
                    Text(
                      '${track.playCount}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              if (track.likeCount != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.favorite, size: 16, color: Colors.white70),
                    const SizedBox(width: 4),
                    Text(
                      '${track.likeCount}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            ElevatedButton.icon(
              onPressed: () => controller.playTracks([track]),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Phát'),
            ),
            if (favorite != null)
              favorite!.when(
                data: (isFavorite) => IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? Colors.red : Colors.white,
                  ),
                  onPressed: () async {
                    try {
                      await ref.read(repositoryProvider).toggleFavorite(track.id);
                      ref.invalidate(favoriteStatusProvider(track.id));
                      // Invalidate track info để refresh like count
                      ref.invalidate(trackInfoProvider(track.id));
                    } catch (_) {
                      // Ignore errors
                    }
                  },
                ),
                loading: () => const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                error: (_, __) => IconButton(
                  icon: const Icon(Icons.favorite_border),
                  onPressed: null,
                ),
              )
            else
              IconButton(
                icon: const Icon(Icons.favorite_border),
                onPressed: null,
                tooltip: 'Đăng nhập để thêm vào yêu thích',
              ),
            if (session != null)
              TextButton(
                onPressed: () => context.go('/recommend/${session!.id}'),
                child: const Text('Xem gợi ý'),
              ),
          ],
        ),
      ],
    );
  }
}

class _TrackCover extends StatelessWidget {
  const _TrackCover({this.data});

  final String? data;

  @override
  Widget build(BuildContext context) {
    final imageData = data;
    if (imageData == null || imageData.isEmpty) {
      return Image.asset(
        'assets/images/default-music.jpg',
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Image.asset(
            'assets/images/default-music.jpg',
            fit: BoxFit.contain,
          );
        },
      );
    }

    // Kiểm tra nếu là URL (http:// hoặc https://)
    if (imageData.startsWith('http://') || imageData.startsWith('https://')) {
      // Thay thế localhost trong URL bằng host từ ConfigService
      String imageUrl = imageData;
      final baseUrl = AppConfig.apiBaseUrl.replaceAll('/api', '');
      if (imageUrl.contains('localhost:') || imageUrl.contains('127.0.0.1:')) {
        // Extract path từ URL (ví dụ: /cover_images/abc.jpg)
        final uri = Uri.parse(imageUrl);
        final path = uri.path;
        // Build lại URL với host từ ConfigService
        imageUrl = '$baseUrl$path';
      }
      
      return Image.network(
        imageUrl,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Image.asset(
            'assets/images/default-music.jpg',
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Image.asset(
                'assets/images/default-music.jpg',
                fit: BoxFit.contain,
              );
            },
          );
        },
      );
    }

    // Kiểm tra nếu là relative path (bắt đầu bằng /)
    if (imageData.startsWith('/')) {
      final baseUrl = AppConfig.apiBaseUrl.replaceAll('/api', '');
      final imageUrl = '$baseUrl$imageData';
      return Image.network(
        imageUrl,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Image.asset(
            'assets/images/default-music.jpg',
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Image.asset(
                'assets/images/default-music.jpg',
                fit: BoxFit.contain,
              );
            },
          );
        },
      );
    }

    // Thử decode base64
    final bytes = tryDecodeBase64Image(imageData);
    if (bytes != null) {
      return Image.memory(
        bytes,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Image.asset(
            'assets/images/default-music.jpg',
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Image.asset(
                'assets/images/default-music.jpg',
                fit: BoxFit.contain,
              );
            },
          );
        },
      );
    }

    // Fallback về default image
    return Image.asset(
      'assets/images/default-music.jpg',
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Image.asset(
          'assets/images/default-music.jpg',
          fit: BoxFit.contain,
        );
      },
    );
  }
}

class _CommentInput extends ConsumerStatefulWidget {
  const _CommentInput({required this.trackId});

  final String trackId;

  @override
  ConsumerState<_CommentInput> createState() => _CommentInputState();
}

class _CommentInputState extends ConsumerState<_CommentInput> {
  final _controller = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authControllerProvider).session;
    if (session == null) {
      return const Text('Đăng nhập để tham gia bình luận.');
    }

    // Dùng LayoutBuilder để tránh overflow trên màn hình nhỏ
    return LayoutBuilder(
      builder: (context, constraints) {
        // Màn hình hẹp: xếp TextField và nút Gửi theo cột
        if (constraints.maxWidth < 480) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: 'Chia sẻ cảm nghĩ của bạn...',
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Gửi'),
                ),
              ),
            ],
          );
        }

        // Màn hình rộng: giữ layout theo hàng như cũ
        return Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: 'Chia sẻ cảm nghĩ của bạn...',
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Gửi'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submit() async {
    if (_controller.text.isEmpty) return;
    setState(() => _submitting = true);
    try {
      await ref
          .read(repositoryProvider)
          .addComment(widget.trackId, _controller.text);
      if (!mounted) return;
      _controller.clear();
      ref.invalidate(commentsProvider(widget.trackId));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể gửi bình luận: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }
}

ImageProvider<Object> _avatarProvider(String? data) {
  return buildAvatarProvider(data);
}

