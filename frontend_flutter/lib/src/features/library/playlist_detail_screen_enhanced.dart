import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../core/config/app_config.dart';
import '../../core/utils/image_utils.dart';
import '../../data/models/models.dart';
import '../../data/repositories/repository.dart';
import '../../widgets/app_page.dart';
import '../../widgets/async_value_widget.dart';
import '../../widgets/track_collection.dart';
import '../auth/controllers/auth_controller.dart';
import '../../music_player/music_player_controller.dart';

final playlistDetailProvider =
    FutureProvider.autoDispose.family<PlaylistDetail, String>((ref, playlistId) {
  final repository = ref.watch(repositoryProvider);
  return repository.getPlaylistDetail(playlistId);
});

class PlaylistDetailScreen extends ConsumerStatefulWidget {
  const PlaylistDetailScreen({super.key, required this.playlistId});

  final String playlistId;

  @override
  ConsumerState<PlaylistDetailScreen> createState() =>
      _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends ConsumerState<PlaylistDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(playlistDetailProvider(widget.playlistId));
    final session = ref.watch(authControllerProvider).session;
    final isOwner = session != null &&
        detail.valueOrNull?.userId != null &&
        session.id == detail.valueOrNull!.userId;

    return AppPage(
      title: 'Playlist',
      child: AsyncValueWidget(
        value: detail,
        data: (data) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header với ảnh bìa và thông tin
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _PlaylistCoverImage(
                      data: data.playlist.coverBase64,
                      name: data.playlist.name,
                      width: 150,
                      height: 150,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.playlist.name,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        if (data.playlist.description != null &&
                            data.playlist.description!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            data.playlist.description!,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: Colors.white70),
                          ),
                        ],
                        const SizedBox(height: 16),
                        Text(
                          '${data.tracks.length} bài hát',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          children: [
                            if (isOwner) ...[
                              ElevatedButton.icon(
                                onPressed: () => _showEditDialog(
                                    context, ref, data, widget.playlistId),
                                icon: const Icon(Icons.edit),
                                label: const Text('Chỉnh sửa'),
                              ),
                              ElevatedButton.icon(
                                onPressed: () => _showDeleteConfirm(
                                    context, ref, widget.playlistId),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red),
                                icon: const Icon(Icons.delete),
                                label: const Text('Xóa'),
                              ),
                            ],
                            ElevatedButton.icon(
                              onPressed: () => _showAddTrackDialog(
                                  context, ref, widget.playlistId),
                              icon: const Icon(Icons.add),
                              label: const Text('Thêm bài hát'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              // Danh sách bài hát
              if (data.tracks.isEmpty)
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.music_off, size: 64, color: Colors.grey[600]),
                      const SizedBox(height: 16),
                      Text(
                        'Playlist trống',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.grey[400],
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Thêm bài hát vào playlist để bắt đầu',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[500],
                            ),
                      ),
                    ],
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: data.tracks.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final track = data.tracks[index];
                    return ListTile(
                      leading: _TrackCoverImage(data: track.imageBase64),
                      title: Text(
                        track.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(track.artistName ?? 'BoxMusic'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!track.isPublic)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'VIP',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.amber,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          IconButton(
                            icon: const Icon(Icons.play_arrow),
                            onPressed: () {
                              final player = ref.read(
                                  musicPlayerControllerProvider.notifier);
                              player.playTracks(data.tracks, startIndex: index);
                            },
                          ),
                          if (isOwner)
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _showRemoveTrackConfirm(
                                  context, ref, widget.playlistId, track.id),
                            ),
                        ],
                      ),
                      onTap: () => context.go('/track/${track.id}'),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showEditDialog(
    BuildContext context,
    WidgetRef ref,
    PlaylistDetail data,
    String playlistId,
  ) async {
    final nameController = TextEditingController(text: data.playlist.name);
    final descriptionController =
        TextEditingController(text: data.playlist.description ?? '');
    final repository = ref.read(repositoryProvider);
    String? coverBase64 = data.playlist.coverBase64;

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Chỉnh sửa playlist'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Tên playlist *'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Mô tả'),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (coverBase64 != null && coverBase64!.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _PlaylistCoverImage(
                          data: coverBase64,
                          name: nameController.text,
                          width: 80,
                          height: 80,
                        ),
                      )
                    else
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.image, color: Colors.grey),
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Ảnh bìa (tùy chọn)'),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final picker = ImagePicker();
                              final image = await picker.pickImage(
                                source: ImageSource.gallery,
                              );
                              if (image != null) {
                                final bytes = await image.readAsBytes();
                                setState(() {
                                  coverBase64 = 'data:image/jpeg;base64,${base64Encode(bytes)}';
                                });
                              }
                            },
                            icon: const Icon(Icons.image),
                            label: const Text('Chọn ảnh'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vui lòng nhập tên playlist')),
                  );
                  return;
                }
                try {
                  await repository.updatePlaylist(playlistId, {
                    'name': nameController.text.trim(),
                    'description': descriptionController.text.trim(),
                    'isPublic': true,
                    if (coverBase64 != null && coverBase64 != data.playlist.coverBase64)
                      'cover': coverBase64,
                  });
                  if (!context.mounted) return;
                  Navigator.of(context).pop();
                  ref.invalidate(playlistDetailProvider(playlistId));
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi: $e')),
                  );
                }
              },
              child: const Text('Cập nhật'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteConfirm(
    BuildContext context,
    WidgetRef ref,
    String playlistId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa playlist'),
        content: const Text(
          'Bạn có chắc chắn muốn xóa playlist này? Thao tác này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final repository = ref.read(repositoryProvider);
        await repository.deletePlaylist(playlistId);
        if (!context.mounted) return;
        final session = ref.read(authControllerProvider).session;
        if (session != null) {
          context.go('/library/${session.id}');
        } else {
          context.go('/');
        }
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  Future<void> _showAddTrackDialog(
    BuildContext context,
    WidgetRef ref,
    String playlistId,
  ) async {
    final searchQueryController = TextEditingController();
    final repository = ref.read(repositoryProvider);
    List<TrackSummary> searchResults = [];
    bool isLoading = false;

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Thêm bài hát vào playlist'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: searchQueryController,
                  decoration: const InputDecoration(
                    labelText: 'Tìm kiếm bài hát',
                    hintText: 'Nhập tên bài hát...',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onSubmitted: (query) async {
                    if (query.trim().isEmpty) return;
                    setState(() => isLoading = true);
                    try {
                      final results = await repository.search(query);
                      final detail = ref.read(
                          playlistDetailProvider(playlistId).future);
                      final playlistDetail = await detail;
                      final existingTrackIds = playlistDetail.tracks
                          .map((t) => t.id)
                          .toSet();
                      setState(() {
                        searchResults = results.tracks
                            .where((t) => !existingTrackIds.contains(t.id))
                            .toList();
                        isLoading = false;
                      });
                    } catch (e) {
                      setState(() => isLoading = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Lỗi: $e')),
                      );
                    }
                  },
                ),
                const SizedBox(height: 16),
                if (isLoading)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  )
                else if (searchResults.isEmpty && searchQueryController.text.isNotEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Không tìm thấy bài hát nào'),
                  )
                else if (searchResults.isNotEmpty)
                  SizedBox(
                    height: 300,
                    child: ListView.builder(
                      itemCount: searchResults.length,
                      itemBuilder: (context, index) {
                        final track = searchResults[index];
                        return ListTile(
                          leading: _TrackCoverImage(data: track.imageBase64),
                          title: Text(
                            track.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(track.artistName ?? 'BoxMusic'),
                          trailing: IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () async {
                              // Check VIP permission trước khi thêm
                              final session = ref.read(authControllerProvider).session;
                              if (session != null && !track.isPublic && session.isNormal) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Bạn cần nâng cấp VIP để thêm bài hát VIP vào playlist'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                                return;
                              }
                              
                              try {
                                await repository.addTrackToPlaylist(
                                    playlistId, track.id);
                                if (!context.mounted) return;
                                Navigator.of(context).pop();
                                ref.invalidate(playlistDetailProvider(playlistId));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Đã thêm bài hát vào playlist')),
                                );
                              } catch (e) {
                                if (!context.mounted) return;
                                final errorMsg = e.toString();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      errorMsg.contains('nâng cấp') || errorMsg.contains('VIP')
                                          ? 'Bạn cần nâng cấp VIP để thêm bài hát VIP vào playlist'
                                          : 'Lỗi: $e'
                                    ),
                                    backgroundColor: errorMsg.contains('nâng cấp') || errorMsg.contains('VIP')
                                        ? Colors.orange
                                        : Colors.red,
                                  ),
                                );
                              }
                            },
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Đóng'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showRemoveTrackConfirm(
    BuildContext context,
    WidgetRef ref,
    String playlistId,
    String trackId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa bài hát'),
        content: const Text(
          'Bạn có chắc chắn muốn xóa bài hát này khỏi playlist?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final repository = ref.read(repositoryProvider);
        await repository.removeTrackFromPlaylist(playlistId, trackId);
        if (!context.mounted) return;
        ref.invalidate(playlistDetailProvider(playlistId));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa bài hát khỏi playlist')),
        );
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }
}

class _TrackCoverImage extends StatelessWidget {
  const _TrackCoverImage({this.data, this.width = 48, this.height = 48});

  final String? data;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final imageData = data;
    if (imageData == null || imageData.isEmpty) {
      return SizedBox(
        width: width,
        height: height,
        child: const Icon(Icons.music_note),
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
      
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          imageUrl,
          width: width,
          height: height,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return SizedBox(
              width: width,
              height: height,
              child: Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                  strokeWidth: 2,
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return SizedBox(
              width: width,
              height: height,
              child: const Icon(Icons.music_note),
            );
          },
        ),
      );
    }

    // Kiểm tra nếu là relative path (bắt đầu bằng /)
    if (imageData.startsWith('/')) {
      final baseUrl = AppConfig.apiBaseUrl.replaceAll('/api', '');
      final imageUrl = '$baseUrl$imageData';
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          imageUrl,
          width: width,
          height: height,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return SizedBox(
              width: width,
              height: height,
              child: Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                  strokeWidth: 2,
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return SizedBox(
              width: width,
              height: height,
              child: const Icon(Icons.music_note),
            );
          },
        ),
      );
    }

    // Thử decode base64
    final bytes = tryDecodeBase64Image(imageData);
    if (bytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(
          bytes,
          width: width,
          height: height,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return SizedBox(
              width: width,
              height: height,
              child: const Icon(Icons.music_note),
            );
          },
        ),
      );
    }

    // Fallback về default icon
    return SizedBox(
      width: width,
      height: height,
      child: const Icon(Icons.music_note),
    );
  }
}

class _PlaylistCoverImage extends StatelessWidget {
  const _PlaylistCoverImage({
    this.data,
    required this.name,
    this.width = 56,
    this.height = 56,
  });

  final String? data;
  final String name;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final imageData = data;
    if (imageData == null || imageData.isEmpty) {
      return CircleAvatar(
        radius: width / 2,
        child: Text(
          name.characters.first.toUpperCase(),
        ),
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
      
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          imageUrl,
          width: width,
          height: height,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return SizedBox(
              width: width,
              height: height,
              child: Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                  strokeWidth: 2,
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return CircleAvatar(
              radius: width / 2,
              child: Text(
                name.characters.first.toUpperCase(),
              ),
            );
          },
        ),
      );
    }

    // Kiểm tra nếu là relative path (bắt đầu bằng /)
    if (imageData.startsWith('/')) {
      final baseUrl = AppConfig.apiBaseUrl.replaceAll('/api', '');
      final imageUrl = '$baseUrl$imageData';
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          imageUrl,
          width: width,
          height: height,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return SizedBox(
              width: width,
              height: height,
              child: Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                  strokeWidth: 2,
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return CircleAvatar(
              radius: width / 2,
              child: Text(
                name.characters.first.toUpperCase(),
              ),
            );
          },
        ),
      );
    }

    // Thử decode base64
    final bytes = tryDecodeBase64Image(imageData);
    if (bytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(
          bytes,
          width: width,
          height: height,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return CircleAvatar(
              radius: width / 2,
              child: Text(
                name.characters.first.toUpperCase(),
              ),
            );
          },
        ),
      );
    }

    // Fallback về avatar với chữ cái đầu
    return CircleAvatar(
      radius: width / 2,
      child: Text(
        name.characters.first.toUpperCase(),
      ),
    );
  }
}
