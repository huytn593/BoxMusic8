import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/config/app_config.dart';
import '../../core/utils/image_utils.dart';
import '../../data/models/models.dart';
import '../../data/repositories/repository.dart';
import '../../music_player/music_player_controller.dart';
import '../../widgets/app_page.dart';
import '../../widgets/async_value_widget.dart';
import '../../widgets/track_collection.dart';
import '../auth/controllers/auth_controller.dart';

final favoriteTracksProvider =
    FutureProvider.autoDispose<List<TrackSummary>>((ref) {
  final repository = ref.watch(repositoryProvider);
  return repository.getFavoriteTracks();
});

final historyProvider =
    FutureProvider.autoDispose.family<List<TrackSummary>, String>((ref, userId) {
  final repository = ref.watch(repositoryProvider);
  return repository.getHistory(userId);
});

final playlistsProvider =
    FutureProvider.autoDispose.family<List<PlaylistSummary>, String>((ref, userId) {
  final repository = ref.watch(repositoryProvider);
  return repository.getUserPlaylists(userId);
});

final playlistDetailProvider =
    FutureProvider.autoDispose.family<PlaylistDetail, String>((ref, playlistId) {
  final repository = ref.watch(repositoryProvider);
  return repository.getPlaylistDetail(playlistId);
});

final artistTracksProvider =
    FutureProvider.autoDispose.family<List<TrackSummary>, String>((ref, profileId) {
  final repository = ref.watch(repositoryProvider);
  return repository.getTracksByArtist(profileId);
});

final playlistLimitsProvider =
    FutureProvider.autoDispose.family<PlaylistLimits, String>((ref, userId) {
  final repository = ref.watch(repositoryProvider);
  return repository.getPlaylistLimits(userId);
});

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authControllerProvider).session;
    final resolvedId = userId == 'me' ? session?.id ?? '' : userId;
    if (resolvedId.isEmpty) {
      return const AppPage(
        title: 'Thư viện',
        child: Center(child: Text('Vui lòng đăng nhập để xem thư viện.')),
      );
    }
    final playlists = ref.watch(playlistsProvider(resolvedId));
    final limits = ref.watch(playlistLimitsProvider(resolvedId));

    return AppPage(
      title: 'Thư viện',
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Playlist của bạn',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      AsyncValueWidget(
                        value: limits,
                        data: (limitsData) => Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _RoleBadge(role: limitsData.userRole),
                            Text(
                              limitsData.isUnlimited
                                  ? 'Playlist: ${limitsData.currentPlaylists} (Không giới hạn)'
                                  : 'Playlist: ${limitsData.currentPlaylists}/${limitsData.maxPlaylists} — Tối đa ${limitsData.isTracksUnlimited ? 'Không giới hạn' : limitsData.maxTracksPerPlaylist} bài/playlist',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                AsyncValueWidget(
                  value: limits,
                  data: (limitsData) => limitsData.canCreateMore
                      ? ElevatedButton.icon(
                          onPressed: () => _showCreatePlaylistDialog(context, ref, resolvedId),
                    icon: const Icon(Icons.add),
                    label: const Text('Playlist mới'),
                        )
                      : const SizedBox.shrink(), // Ẩn nút nếu hết giới hạn
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: AsyncValueWidget(
                value: playlists,
                data: (data) => data.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.music_note, size: 64, color: Colors.grey[600]),
                            const SizedBox(height: 16),
                            Text(
                              'Chưa có playlist nào',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.grey[400],
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tạo playlist đầu tiên để sắp xếp những bài hát yêu thích của bạn',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: data.length,
                        itemBuilder: (context, index) {
                          final playlist = data[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              leading: _PlaylistCoverImage(
                                data: playlist.coverBase64,
                                name: playlist.name,
                              ),
                              title: Text(playlist.name),
                              subtitle: Text('${playlist.trackCount} bài hát'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _showDeletePlaylistConfirm(
                                      context, ref, playlist.id, resolvedId),
                                  ),
                                  const Icon(Icons.chevron_right),
                                ],
                              ),
                              onTap: () => context.go('/playlist/${playlist.id}'),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeletePlaylistConfirm(
    BuildContext context,
    WidgetRef ref,
    String playlistId,
    String userId,
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
        ref.invalidate(playlistsProvider(userId));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa playlist thành công')),
        );
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  String _getRoleDisplay(String role) {
    switch (role.toLowerCase()) {
      case 'vip':
        return 'VIP';
      case 'premium':
        return 'Premium';
      case 'admin':
        return 'Admin';
      default:
        return 'Normal';
    }
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'vip':
        return Colors.amber;
      case 'premium':
        return Colors.purple;
      case 'admin':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _showCreatePlaylistDialog(
    BuildContext context,
    WidgetRef ref,
    String userId,
  ) async {
    if (userId.isEmpty) return;
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final repository = ref.read(repositoryProvider);
    String? coverBase64;
    XFile? selectedImage;

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Playlist mới'),
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
                    if (coverBase64 != null)
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
                                coverBase64 =
                                    'data:image/jpeg;base64,${base64Encode(bytes)}';
                                setState(() {});
                              }
                            },
                            icon: const Icon(Icons.image, size: 18),
                            label: const Text('Chọn ảnh'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
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
                  await repository.createPlaylist({
                    'name': nameController.text.trim(),
                    'description': descriptionController.text.trim(),
                    'isPublic': true,
                    if (coverBase64 != null) 'cover': coverBase64,
                  });
                  if (!context.mounted) return;
                  Navigator.of(context).pop();
                  ref.invalidate(playlistsProvider(userId));
                  ref.invalidate(playlistLimitsProvider(userId));
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi: $e')),
                  );
                }
              },
              child: const Text('Tạo'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Badge hiển thị role (VIP, Premium, Admin) - đồng bộ với profile screen
class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    final roleLower = role.toLowerCase();
    Color backgroundColor;
    Color textColor;
    String icon;
    String text;

    switch (roleLower) {
      case 'vip':
        backgroundColor = Colors.orange.shade700.withValues(alpha: 0.9); // Dùng orange thay vì amber để không chói
        textColor = Colors.black; // Màu đen cho chữ VIP
        icon = '👑';
        text = 'VIP';
        break;
      case 'premium':
        backgroundColor = Colors.purple.shade800.withValues(alpha: 0.8); // Tăng alpha để nổi bật hơn
        textColor = Colors.purple.shade100; // Màu sáng hơn cho text
        icon = '💎';
        text = 'Premium';
        break;
      case 'admin':
        backgroundColor = Colors.red.shade800.withValues(alpha: 0.8); // Tăng alpha để nổi bật hơn
        textColor = Colors.red.shade100; // Màu sáng hơn cho text
        icon = '⚔️';
        text = 'Admin';
        break;
      default:
        return const SizedBox.shrink(); // Không hiển thị badge cho Normal
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withValues(alpha: 0.5), width: 1.5), // Tăng độ đậm border
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            icon,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class FavoriteScreen extends ConsumerWidget {
  const FavoriteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoriteTracksProvider);
    final repository = ref.watch(repositoryProvider);

    return AppPage(
      title: 'Bài hát yêu thích',
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Những bản nhạc bạn yêu',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                TextButton(
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Xóa tất cả'),
                        content: const Text(
                          'Bạn có chắc chắn muốn xóa tất cả bài hát yêu thích? Thao tác này không thể hoàn tác.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Hủy'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                            child: const Text('Xóa tất cả'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      await repository.deleteAllFavorites();
                      ref.invalidate(favoriteTracksProvider);
                    }
                  },
                  child: const Text('Xóa tất cả'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: AsyncValueWidget(
                value: favorites,
                data: (tracks) => tracks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.favorite_border, size: 64, color: Colors.grey[600]),
                            const SizedBox(height: 16),
                            Text(
                              'Chưa có bài hát yêu thích',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.grey[400],
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Nhấn vào trái tim ở bài hát bạn thích để thêm vào đây',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: tracks.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final track = tracks[index];
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
                                  icon: const Icon(Icons.favorite, color: Colors.red),
                                  onPressed: () async {
                                    await repository.toggleFavorite(track.id);
                                    ref.invalidate(favoriteTracksProvider);
                                  },
                                ),
                              ],
                            ),
                            onTap: () => context.go('/track/${track.id}'),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key, required this.userId});

  final String userId;

  String _timeAgo(DateTime? dateTime) {
    if (dateTime == null) return 'Chưa xác định';
    final diff = DateTime.now().difference(dateTime);
    if (diff.inSeconds < 60) {
      return '${diff.inSeconds} giây trước';
    }
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} phút trước';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours} giờ trước';
    }
    if (diff.inDays < 30) {
      return '${diff.inDays} ngày trước';
    }
    if (diff.inDays < 365) {
      return '${(diff.inDays / 30).floor()} tháng trước';
    }
    return '${(diff.inDays / 365).floor()} năm trước';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authControllerProvider).session;
    final resolvedId = userId == 'me' ? session?.id ?? '' : userId;
    if (resolvedId.isEmpty) {
      return const AppPage(
        title: 'Lịch sử nghe',
        child: Center(child: Text('Vui lòng đăng nhập để xem lịch sử.')),
      );
    }
    final history = ref.watch(historyProvider(resolvedId));
    final repository = ref.watch(repositoryProvider);

    return AppPage(
      title: 'Lịch sử nghe',
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Xóa lịch sử'),
                      content: const Text(
                        'Bạn có chắc chắn muốn xóa tất cả lịch sử nghe nhạc? Thao tác này không thể hoàn tác.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Hủy'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          child: const Text('Xóa tất cả'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    await repository.deleteAllHistory();
                    ref.invalidate(historyProvider(resolvedId));
                  }
                },
                child: const Text('Xóa lịch sử'),
              ),
            ),
            Expanded(
              child: AsyncValueWidget(
                value: history,
                data: (tracks) => tracks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history, size: 64, color: Colors.grey[600]),
                            const SizedBox(height: 16),
                            Text(
                              'Chưa có lịch sử nghe nhạc',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.grey[400],
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Hãy bắt đầu khám phá và nghe những bài hát bạn yêu thích',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: tracks.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final track = tracks[index];
                          return ListTile(
                            leading: _TrackCoverImage(data: track.imageBase64),
                            title: Text(track.title),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(track.artistName ?? 'BoxMusic'),
                                if (track.lastPlay != null)
                                  Text(
                                    _timeAgo(track.lastPlay),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(color: Colors.grey[500]),
                                  ),
                              ],
                            ),
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
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () async {
                                    final confirmed = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Xóa khỏi lịch sử'),
                                        content: Text(
                                          'Bạn có chắc muốn xóa "${track.title}" khỏi lịch sử?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(context).pop(false),
                                            child: const Text('Hủy'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () =>
                                                Navigator.of(context).pop(true),
                                            style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.red),
                                            child: const Text('Xóa'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirmed == true) {
                                      await repository.deleteHistoryTrack(track.id);
                                      ref.invalidate(historyProvider(resolvedId));
                                    }
                                  },
                                ),
                              ],
                            ),
                            onTap: () => context.go('/track/${track.id}'),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class MyTrackScreen extends ConsumerStatefulWidget {
  const MyTrackScreen({super.key, required this.profileId});

  final String profileId;

  @override
  ConsumerState<MyTrackScreen> createState() => _MyTrackScreenState();
}

class _MyTrackScreenState extends ConsumerState<MyTrackScreen> {
  String _filterStatus = 'all'; // 'all', 'approved', 'pending'
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _deleteTrack(BuildContext context, WidgetRef ref, String trackId, String trackTitle) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa bài nhạc'),
        content: Text('Bạn có chắc chắn muốn xóa bài nhạc "$trackTitle"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Không'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Có'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final repository = ref.read(repositoryProvider);
      await repository.deleteTrack(trackId);
      
      // Xử lý trong music player nếu track đang được phát
      ref.read(musicPlayerControllerProvider.notifier).handleTrackDeleted(trackId);
      if (!context.mounted) return;
      
      // Invalidate provider để refresh danh sách
      ref.invalidate(artistTracksProvider(widget.profileId));
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xóa bài nhạc thành công')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi xóa bài nhạc: $error')),
      );
    }
  }

  List<TrackSummary> _filterTracks(List<TrackSummary> tracks) {
    return tracks.where((track) {
      // Filter theo status
      final matchStatus = _filterStatus == 'all' ||
          (_filterStatus == 'approved' && (track.isApproved == true)) ||
          (_filterStatus == 'pending' && (track.isApproved != true));

      // Filter theo search query
      final matchTitle = track.title.toLowerCase().contains(_searchQuery.toLowerCase());

      return matchStatus && matchTitle;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final tracks = ref.watch(artistTracksProvider(widget.profileId));

    return AppPage(
      title: 'Nhạc của tôi',
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: AsyncValueWidget(
          value: tracks,
          data: (allTracks) {
            final filteredTracks = _filterTracks(allTracks);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Filter và Search
                LayoutBuilder(
                  builder: (context, constraints) {
                    // Responsive: Column trên màn hình nhỏ, Row trên màn hình lớn
                    if (constraints.maxWidth < 600) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          DropdownButtonFormField<String>(
                            value: _filterStatus,
                            decoration: InputDecoration(
                              labelText: 'Lọc theo trạng thái',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            isExpanded: true,
                            items: const [
                              DropdownMenuItem(value: 'all', child: Text('Tất cả')),
                              DropdownMenuItem(value: 'approved', child: Text('Đã duyệt')),
                              DropdownMenuItem(value: 'pending', child: Text('Chưa duyệt')),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _filterStatus = value;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Tìm kiếm bài hát...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              prefixIcon: const Icon(Icons.search),
                            ),
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value;
                              });
                            },
                          ),
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            value: _filterStatus,
                            decoration: InputDecoration(
                              labelText: 'Lọc theo trạng thái',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            isExpanded: true,
                            items: const [
                              DropdownMenuItem(value: 'all', child: Text('Tất cả')),
                              DropdownMenuItem(value: 'approved', child: Text('Đã duyệt')),
                              DropdownMenuItem(value: 'pending', child: Text('Chưa duyệt')),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _filterStatus = value;
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              labelText: 'Tìm theo tên nhạc...',
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value;
                              });
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                // Danh sách nhạc
                if (filteredTracks.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Text('Không có bài nhạc nào phù hợp.'),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      itemCount: filteredTracks.length,
                      itemBuilder: (context, index) {
                        final track = filteredTracks[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                if (constraints.maxWidth < 600) {
                                  // Mobile layout: Column
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: _buildTrackImage(track.imageBase64, 100, 100),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  track.title,
                                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4),
                                                if (track.genres.isNotEmpty)
                                                  Text(
                                                    'Thể loại: ${track.genres.join(', ')}',
                                                    style: Theme.of(context).textTheme.bodySmall,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                const SizedBox(height: 4),
                                                if (track.isApproved != null)
                                                  Wrap(
                                                    spacing: 4,
                                                    children: [
                                                      Text(
                                                        'Tình trạng: ',
                                                        style: Theme.of(context).textTheme.bodySmall,
                                                      ),
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(
                                                          horizontal: 6,
                                                          vertical: 2,
                                                        ),
                                                        decoration: BoxDecoration(
                                                          color: track.isApproved == true
                                                              ? Colors.green.shade700
                                                              : Colors.orange.shade700,
                                                          borderRadius: BorderRadius.circular(4),
                                                        ),
                                                        child: Text(
                                                          track.isApproved == true ? 'Đã duyệt' : 'Chưa duyệt',
                                                          style: const TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 10,
                                                            fontWeight: FontWeight.w600,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.info_outline),
                                            tooltip: 'Xem chi tiết',
                                            onPressed: () => context.go('/track/${track.id}'),
                                          ),
                                          // Bỏ nút xóa và edit cho user
                                        ],
                                      ),
                                    ],
                                  );
                                }
                                // Desktop layout: Row
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Cover image
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: _buildTrackImage(track.imageBase64, 120, 120),
                                    ),
                                    const SizedBox(width: 16),
                                    // Track info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            track.title,
                                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 8),
                                          if (track.genres.isNotEmpty)
                                            Text(
                                              'Thể loại: ${track.genres.join(', ')}',
                                              style: Theme.of(context).textTheme.bodyMedium,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          const SizedBox(height: 4),
                                          if (track.isApproved != null)
                                            Wrap(
                                              spacing: 4,
                                              children: [
                                                Text(
                                                  'Tình trạng: ',
                                                  style: Theme.of(context).textTheme.bodyMedium,
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: track.isApproved == true
                                                        ? Colors.green.shade700
                                                        : Colors.orange.shade700,
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    track.isApproved == true ? 'Đã duyệt' : 'Chưa duyệt',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                        ],
                                      ),
                                    ),
                                    // Actions
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.info_outline),
                                          tooltip: 'Xem chi tiết',
                                          onPressed: () => context.go('/track/${track.id}'),
                                        ),
                                        // Bỏ nút xóa và edit cho user
                                      ],
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTrackImage(String? imageData, double width, double height) {
    if (imageData == null || imageData.isEmpty) {
      return Container(
        width: width,
        height: height,
        color: Colors.grey.shade800,
        child: const Icon(Icons.music_note, size: 48, color: Colors.white70),
      );
    }

    // Kiểm tra nếu là URL (http:// hoặc https://)
    if (imageData.startsWith('http://') || imageData.startsWith('https://')) {
      String imageUrl = imageData;
      final baseUrl = AppConfig.apiBaseUrl.replaceAll('/api', '');
      if (imageUrl.contains('localhost:') || imageUrl.contains('127.0.0.1:')) {
        final uri = Uri.parse(imageUrl);
        final path = uri.path;
        imageUrl = '$baseUrl$path';
      }
      
      return Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: width,
            height: height,
            color: Colors.grey.shade800,
            child: const Icon(Icons.music_note, size: 48, color: Colors.white70),
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
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: width,
            height: height,
            color: Colors.grey.shade800,
            child: const Icon(Icons.music_note, size: 48, color: Colors.white70),
          );
        },
      );
    }

    // Thử decode base64
    final bytes = tryDecodeBase64Image(imageData);
    if (bytes != null) {
      return Image.memory(
        bytes,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: width,
            height: height,
            color: Colors.grey.shade800,
            child: const Icon(Icons.music_note, size: 48, color: Colors.white70),
          );
        },
      );
    }

    // Fallback
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade800,
      child: const Icon(Icons.music_note, size: 48, color: Colors.white70),
    );
  }
}

class _TrackCoverImage extends StatelessWidget {
  const _TrackCoverImage({this.data, this.width = 56, this.height = 56});

  final String? data;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final imageData = data;
    if (imageData == null || imageData.isEmpty) {
      return Container(
        width: width,
        height: height,
        color: Colors.grey[800],
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
            return Container(
              width: width,
              height: height,
              color: Colors.grey[800],
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
            return Container(
              width: width,
              height: height,
              color: Colors.grey[800],
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
            return Container(
              width: width,
              height: height,
              color: Colors.grey[800],
              child: const Icon(Icons.music_note),
            );
          },
        ),
      );
    }

    // Fallback về default icon
    return Container(
      width: width,
      height: height,
      color: Colors.grey[800],
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

