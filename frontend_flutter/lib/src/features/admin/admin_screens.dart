import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../core/config/app_config.dart';
import '../../core/utils/image_utils.dart';
import '../../data/models/models.dart';
import '../../data/repositories/repository.dart';
import '../../music_player/music_player_controller.dart';
import '../../widgets/app_page.dart';
import '../../widgets/async_value_widget.dart';

final adminTracksProvider =
    FutureProvider.autoDispose<List<TrackSummary>>((ref) {
  final repository = ref.watch(repositoryProvider);
  return repository.getAllTracks();
});

class AdminTrackListScreen extends ConsumerStatefulWidget {
  const AdminTrackListScreen({super.key});

  @override
  ConsumerState<AdminTrackListScreen> createState() => _AdminTrackListScreenState();
}

class _AdminTrackListScreenState extends ConsumerState<AdminTrackListScreen> {
  String _filterStatus = 'all'; // 'all', 'approved', 'pending'
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleApprove(BuildContext context, WidgetRef ref, String trackId) async {
    try {
      final repository = ref.read(repositoryProvider);
      await repository.approveTrack(trackId);
      if (!context.mounted) return;
      ref.invalidate(adminTracksProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã cập nhật trạng thái duyệt')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $error')),
      );
    }
  }

  Future<void> _handleTogglePublic(BuildContext context, WidgetRef ref, String trackId) async {
    try {
      final repository = ref.read(repositoryProvider);
      await repository.togglePublicTrack(trackId);
      if (!context.mounted) return;
      ref.invalidate(adminTracksProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã cập nhật trạng thái công khai')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $error')),
      );
    }
  }

  Future<void> _handleRestore(BuildContext context, WidgetRef ref, String trackId) async {
    try {
      final repository = ref.read(repositoryProvider);
      await repository.restoreTrack(trackId);
      if (!context.mounted) return;
      ref.invalidate(adminTracksProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã mở khóa bài hát')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $error')),
      );
    }
  }

  Future<void> _handleDelete(BuildContext context, WidgetRef ref, String trackId, String trackTitle, bool isPermanentDelete) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isPermanentDelete ? 'Xác nhận xóa vĩnh viễn' : 'Xác nhận vô hiệu hóa'),
        content: Text(isPermanentDelete
            ? 'Bạn có chắc chắn muốn xóa vĩnh viễn bài hát "$trackTitle"? Hành động này không thể hoàn tác.'
            : 'Bạn có chắc chắn muốn vô hiệu hóa bài hát "$trackTitle"? Bài hát sẽ không hiển thị cho người dùng nhưng admin vẫn có thể thấy và xóa vĩnh viễn sau.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: isPermanentDelete ? Colors.red.shade900 : Colors.red),
            child: Text(isPermanentDelete ? 'Xóa vĩnh viễn' : 'Vô hiệu hóa'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final repository = ref.read(repositoryProvider);
      await repository.deleteTrack(trackId);
      if (!context.mounted) return;
      
      // Xử lý trong music player nếu track đang được phát
      try {
        final musicPlayerNotifier = ref.read(musicPlayerControllerProvider.notifier);
        musicPlayerNotifier.handleTrackDeleted(trackId);
      } catch (e) {
        // Ignore nếu music player chưa được khởi tạo hoặc có lỗi
        if (kDebugMode) {
          print('Warning: Could not handle track deletion in music player: $e');
        }
      }
      
      ref.invalidate(adminTracksProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isPermanentDelete ? 'Đã xóa bài hát vĩnh viễn' : 'Đã vô hiệu hóa bài hát')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $error')),
      );
    }
  }

  List<TrackSummary> _filterTracks(List<TrackSummary> tracks) {
    return tracks.where((track) {
      // Filter theo status (chỉ áp dụng cho bài hát do user upload)
      final matchStatus = _filterStatus == 'all' ||
          (_filterStatus == 'approved' && (track.isApproved == true)) ||
          (_filterStatus == 'pending' && (track.isApproved != true));

      // Filter theo search query
      final artistName = (track.artistName ?? '').toLowerCase();
      final title = track.title.toLowerCase();
      final matchSearch = artistName.contains(_searchQuery.toLowerCase()) ||
          title.contains(_searchQuery.toLowerCase());

      return matchStatus && matchSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final tracks = ref.watch(adminTracksProvider);

    return AppPage(
      title: 'Quản lý bài hát',
      showPrimaryNav: true,
      child: AsyncValueWidget(
        value: tracks,
        data: (allTracks) {
          final filteredTracks = _filterTracks(allTracks);
          
          // Tính stats
          final stats = {
            'total': allTracks.length,
            'approved': allTracks.where((t) => t.isApproved == true).length,
            'pending': allTracks.where((t) => t.isApproved != true).length,
          };

          return Padding(
              padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header với stats
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🎵 Quản lý bài hát',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        Text('Tổng: ${stats['total']}'),
                        Text('Đã duyệt: ${stats['approved']}'),
                        Text('Chờ duyệt: ${stats['pending']}'),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Filter và Search
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth > 600) {
                      // Màn hình lớn: Row
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
                              ),
                              items: const [
                                DropdownMenuItem(value: 'all', child: Text('Tất cả trạng thái')),
                                DropdownMenuItem(value: 'approved', child: Text('Đã duyệt')),
                                DropdownMenuItem(value: 'pending', child: Text('Chờ duyệt')),
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
                                labelText: 'Tìm theo tên nghệ sĩ hoặc tên bài hát...',
                                prefixIcon: const Icon(Icons.search),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
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
                    } else {
                      // Màn hình nhỏ: Column
                      return Column(
                        children: [
                          DropdownButtonFormField<String>(
                            value: _filterStatus,
                            decoration: InputDecoration(
                              labelText: 'Lọc theo trạng thái',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'all', child: Text('Tất cả trạng thái')),
                              DropdownMenuItem(value: 'approved', child: Text('Đã duyệt')),
                              DropdownMenuItem(value: 'pending', child: Text('Chờ duyệt')),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _filterStatus = value;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              labelText: 'Tìm theo tên nghệ sĩ hoặc tên bài hát...',
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
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
                  },
                ),
                const SizedBox(height: 24),
                // Danh sách bài hát
                Expanded(
                  child: filteredTracks.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(48),
                            child: Text('Không có bài hát nào phù hợp.'),
                          ),
                        )
                      : ListView.builder(
                          itemCount: filteredTracks.length,
                          itemBuilder: (context, index) {
                            final track = filteredTracks[index];
                            // Giả sử nếu artistName là "BoxMusic" hoặc null thì là bài hát do admin upload
                            final isUserUpload = track.artistName != null && 
                                track.artistName!.toLowerCase() != 'boxmusic' &&
                                track.artistName!.isNotEmpty;
                            
                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    if (constraints.maxWidth > 600) {
                                      // Màn hình lớn: Row layout
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
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  track.title,
                                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  'Nghệ sĩ: ${track.artistName ?? 'BoxMusic'}',
                                                  style: Theme.of(context).textTheme.bodyMedium,
                                                ),
                                                if (track.genres.isNotEmpty) ...[
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'Thể loại: ${track.genres.join(', ')}',
                                                    style: Theme.of(context).textTheme.bodySmall,
                                                  ),
                                                ],
                                                const SizedBox(height: 8),
                                                // Status badge
                                                Wrap(
                                                  spacing: 8,
                                                  runSpacing: 8,
                                                  children: [
                                                    if (track.isDeleted == true)
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 4,
                                                        ),
                                                        decoration: BoxDecoration(
                                                          color: Colors.red.shade700,
                                                          borderRadius: BorderRadius.circular(4),
                                                        ),
                                                        child: const Text(
                                                          'Đã vô hiệu hóa',
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 12,
                                                            fontWeight: FontWeight.w600,
                                                          ),
                                                        ),
                                                      ),
                                                    if (track.isDeleted == true)
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 4,
                                                        ),
                                                        decoration: BoxDecoration(
                                                          color: Colors.red.shade700,
                                                          borderRadius: BorderRadius.circular(4),
                                                        ),
                                                        child: const Text(
                                                          'Đã khóa',
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 12,
                                                            fontWeight: FontWeight.w600,
                                                          ),
                                                        ),
                                                      )
                                                    else if (isUserUpload)
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
                                                          track.isApproved == true ? 'Đã duyệt' : 'Chờ duyệt',
                                                          style: const TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 12,
                                                            fontWeight: FontWeight.w600,
                                                          ),
                                                        ),
                                                      )
                                                    else if (!isUserUpload)
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 4,
                                                        ),
                                                        decoration: BoxDecoration(
                                                          color: track.isPublic
                                                              ? Colors.blue.shade700
                                                              : Colors.amber.shade700,
                                                          borderRadius: BorderRadius.circular(4),
                                                        ),
                                                        child: Text(
                                                          track.isPublic ? 'Công khai' : 'VIP',
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
                                          const SizedBox(width: 16),
                                          // Actions
                                          Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (track.isDeleted != true) ...[
                                                if (isUserUpload)
                                                  ElevatedButton(
                                                    onPressed: () => _handleApprove(context, ref, track.id),
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: track.isApproved == true
                                                          ? Colors.orange
                                                          : Colors.green,
                                                    ),
                                                    child: Text(
                                                      track.isApproved == true ? 'Khóa' : 'Duyệt',
                                                    ),
                                                  ),
                                                // Luôn hiển thị button Set VIP/Public cho admin
                                                ElevatedButton(
                                                  onPressed: () => _handleTogglePublic(context, ref, track.id),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: track.isPublic
                                                        ? Colors.amber
                                                        : Colors.blue,
                                                  ),
                                                  child: Text(
                                                    track.isPublic ? 'Set VIP' : 'Set Public',
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                              ] else ...[
                                                // Nếu track đã bị vô hiệu hóa, hiển thị button mở khóa
                                                ElevatedButton(
                                                  onPressed: () => _handleRestore(context, ref, track.id),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.green,
                                                  ),
                                                  child: const Text('Mở khóa'),
                                                ),
                                                const SizedBox(height: 8),
                                              ],
                                              IconButton(
                                                icon: Icon(
                                                  track.isDeleted == true ? Icons.delete_forever : Icons.delete,
                                                  color: track.isDeleted == true ? Colors.red.shade900 : Colors.red,
                                                ),
                                                tooltip: track.isDeleted == true ? 'Xóa vĩnh viễn' : 'Vô hiệu hóa',
                                                onPressed: () => _handleDelete(
                                                  context,
                                                  ref,
                                                  track.id,
                                                  track.title,
                                                  track.isDeleted == true,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      );
                                    } else {
                                      // Màn hình nhỏ: Column layout
                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              // Cover image
                                              ClipRRect(
                                                borderRadius: BorderRadius.circular(8),
                                                child: _buildTrackImage(track.imageBase64, 100, 100),
                                              ),
                                              const SizedBox(width: 12),
                                              // Track info
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      track.title,
                                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      'Nghệ sĩ: ${track.artistName ?? 'BoxMusic'}',
                                                      style: Theme.of(context).textTheme.bodySmall,
                                                    ),
                                                    if (track.genres.isNotEmpty) ...[
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        'Thể loại: ${track.genres.join(', ')}',
                                                        style: Theme.of(context).textTheme.bodySmall,
                                                        maxLines: 2,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          // Status badge và Actions
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              // Status badge
                                              if (track.isDeleted == true)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.red.shade700,
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: const Text(
                                                    'Đã khóa',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                )
                                              else if (isUserUpload)
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
                                                    track.isApproved == true ? 'Đã duyệt' : 'Chờ duyệt',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                )
                                              else
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: track.isPublic
                                                        ? Colors.blue.shade700
                                                        : Colors.amber.shade700,
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    track.isPublic ? 'Công khai' : 'VIP',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              // Actions
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  if (track.isDeleted != true) ...[
                                                    if (isUserUpload)
                                                      ElevatedButton(
                                                        onPressed: () => _handleApprove(context, ref, track.id),
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor: track.isApproved == true
                                                              ? Colors.orange
                                                              : Colors.green,
                                                          padding: const EdgeInsets.symmetric(horizontal: 12),
                                                        ),
                                                        child: Text(
                                                          track.isApproved == true ? 'Khóa' : 'Duyệt',
                                                          style: const TextStyle(fontSize: 12),
                                                        ),
                                                      ),
                                                    // Luôn hiển thị button Set VIP/Public cho admin
                                                    ElevatedButton(
                                                      onPressed: () => _handleTogglePublic(context, ref, track.id),
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: track.isPublic
                                                            ? Colors.amber
                                                            : Colors.blue,
                                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                                      ),
                                                      child: Text(
                                                        track.isPublic ? 'Set VIP' : 'Set Public',
                                                        style: const TextStyle(fontSize: 12),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                  ] else ...[
                                                    // Nếu track đã bị vô hiệu hóa, hiển thị button mở khóa
                                                    ElevatedButton(
                                                      onPressed: () => _handleRestore(context, ref, track.id),
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: Colors.green,
                                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                                      ),
                                                      child: const Text(
                                                        'Mở khóa',
                                                        style: TextStyle(fontSize: 12),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                  ],
                                                  IconButton(
                                                    icon: Icon(
                                                      track.isDeleted == true ? Icons.delete_forever : Icons.delete,
                                                      color: track.isDeleted == true ? Colors.red.shade900 : Colors.red,
                                                      size: 20,
                                                    ),
                                                    tooltip: track.isDeleted == true ? 'Xóa vĩnh viễn' : 'Vô hiệu hóa',
                                                    padding: EdgeInsets.zero,
                                                    constraints: const BoxConstraints(),
                                                    onPressed: () => _handleDelete(
                                                      context,
                                                      ref,
                                                      track.id,
                                                      track.title,
                                                      track.isDeleted == true,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      );
                                    }
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
            ),
          );
        },
        loading: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(),
          ),
        ),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Lỗi: $error'),
          ),
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

class RevenueChartScreen extends ConsumerStatefulWidget {
  const RevenueChartScreen({super.key});

  @override
  ConsumerState<RevenueChartScreen> createState() => _RevenueChartScreenState();
}

class _RevenueChartScreenState extends ConsumerState<RevenueChartScreen> {
  late DateTime _from;
  late DateTime _to;
  String _selectedTier = 'VIP';
  bool _isLoading = false;
  List<PaymentRecord> _revenueByTime = [];
  List<PaymentRecord> _revenueByTier = [];

  @override
  void initState() {
    super.initState();
    _to = DateTime.now();
    _from = _to.subtract(const Duration(days: 30));
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final repository = ref.read(repositoryProvider);
      final [byTime, byTier] = await Future.wait([
        repository.getRevenueByTime(
          from: _from.toIso8601String(),
          to: _to.toIso8601String(),
        ),
        repository.getRevenueByTier(_selectedTier),
      ]);
      setState(() {
        _revenueByTime = byTime;
        _revenueByTier = byTier;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<RevenuePoint> _groupByDate(List<PaymentRecord> records) {
    final grouped = <String, double>{};
    for (final record in records) {
      final date = DateFormat('yyyy-MM-dd').format(record.paymentTime);
      grouped[date] = (grouped[date] ?? 0) + record.amount;
    }
    return grouped.entries
        .map((e) => RevenuePoint(label: e.key, amount: e.value))
        .toList()
      ..sort((a, b) => a.label.compareTo(b.label));
  }

  // Tính interval cho trục Y để tránh chồng nhau
  double? _getYAxisInterval(List<RevenuePoint> data) {
    if (data.isEmpty) return null;
    final maxAmount = data.map((e) => e.amount).reduce((a, b) => a > b ? a : b);
    final minAmount = data.map((e) => e.amount).reduce((a, b) => a < b ? a : b);
    final range = maxAmount - minAmount;
    // Chia thành khoảng 4-6 labels
    if (range > 0) {
      return range / 5;
    }
    return null;
  }

  // Tính interval cho trục X để chỉ hiển thị một số labels
  double? _getXAxisInterval(int dataLength) {
    if (dataLength <= 0) return null;
    // Hiển thị tối đa 8 labels
    if (dataLength <= 8) return 1;
    // Nếu nhiều hơn, chỉ hiển thị mỗi n labels
    return (dataLength / 8).ceilToDouble();
  }

  String _formatMoney(double value) {
    // Format ngắn gọn để tránh chồng nhau
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M ₫';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}K ₫';
    }
    return '${value.toStringAsFixed(0)} ₫';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_revenueByTime.isEmpty && _revenueByTier.isEmpty) {
      _fetchData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final chartByDate = _groupByDate(_revenueByTime);
    final chartByTier = _groupByDate(_revenueByTier);

    return AppPage(
      title: 'Thống kê doanh thu',
      showPrimaryNav: true,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Form controls
            Card(
              color: Colors.grey[900],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🤑 Thống kê doanh thu',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Tier dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedTier,
                      decoration: const InputDecoration(
                        labelText: 'Gói nâng cấp',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'VIP', child: Text('VIP')),
                        DropdownMenuItem(
                            value: 'Premium', child: Text('Premium')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedTier = value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    // Date pickers
                    Row(
                      children: [
                        Expanded(
                          child: ListTile(
                            title: const Text('Từ ngày'),
                            subtitle: Text(DateFormat('dd/MM/yyyy').format(_from)),
                            trailing: IconButton(
                              icon: const Icon(Icons.calendar_today),
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _from,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now(),
                                );
                                if (picked != null) {
                                  setState(() => _from = picked);
                                }
                              },
                            ),
                          ),
                        ),
                        Expanded(
                          child: ListTile(
                            title: const Text('Đến ngày'),
                            subtitle: Text(DateFormat('dd/MM/yyyy').format(_to)),
                            trailing: IconButton(
                              icon: const Icon(Icons.calendar_today),
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _to,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now(),
                                );
                                if (picked != null) {
                                  setState(() => _to = picked);
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _fetchData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Lọc'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Chart 1: Doanh thu theo ngày (Toàn bộ)
            Card(
              color: Colors.grey[900],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Doanh thu theo ngày (Toàn bộ)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.cyan,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 300,
                      child: chartByDate.isEmpty
                          ? const Center(
                              child: Text('Không có dữ liệu doanh thu.'),
                            )
                          : LineChart(
                              LineChartData(
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: true,
                                  getDrawingHorizontalLine: (value) {
                                    return FlLine(
                                      color: Colors.grey[700]!,
                                      strokeWidth: 1,
                                    );
                                  },
                                ),
                                titlesData: FlTitlesData(
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 60,
                                      interval: _getYAxisInterval(chartByDate),
                                      getTitlesWidget: (value, meta) {
                                        return Padding(
                                          padding: const EdgeInsets.only(right: 4),
                                          child: Text(
                                            _formatMoney(value),
                                            style: const TextStyle(
                                              fontSize: 9,
                                              color: Colors.grey,
                                            ),
                                            textAlign: TextAlign.right,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 40,
                                      interval: _getXAxisInterval(chartByDate.length),
                                      getTitlesWidget: (value, meta) {
                                        final index = value.toInt();
                                        if (index >= chartByDate.length || index < 0) {
                                          return const Text('');
                                        }
                                        final dateStr = chartByDate[index].label;
                                        final date = DateTime.parse(dateStr);
                                        return Transform.rotate(
                                          angle: -0.5, // Xoay 30 độ
                                          child: Text(
                                            DateFormat('dd/MM').format(date),
                                            style: const TextStyle(
                                              fontSize: 9,
                                              color: Colors.grey,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  topTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  rightTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                ),
                                borderData: FlBorderData(
                                  show: true,
                                  border: Border.all(color: Colors.grey[700]!),
                                ),
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: chartByDate.asMap().entries.map((e) {
                                      return FlSpot(
                                        e.key.toDouble(),
                                        e.value.amount,
                                      );
                                    }).toList(),
                                    isCurved: true,
                                    color: Colors.cyan,
                                    barWidth: 2,
                                    dotData: const FlDotData(show: true),
                                    belowBarData: BarAreaData(
                                      show: true,
                                      color: Colors.cyan.withOpacity(0.1),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Chart 2: Doanh thu theo ngày (Theo gói nâng cấp)
            Card(
              color: Colors.grey[900],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Doanh thu theo ngày (Gói $_selectedTier)',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 300,
                      child: chartByTier.isEmpty
                          ? const Center(
                              child: Text('Không có dữ liệu doanh thu.'),
                            )
                          : LineChart(
                              LineChartData(
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: true,
                                  getDrawingHorizontalLine: (value) {
                                    return FlLine(
                                      color: Colors.grey[700]!,
                                      strokeWidth: 1,
                                    );
                                  },
                                ),
                                titlesData: FlTitlesData(
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 60,
                                      interval: _getYAxisInterval(chartByTier),
                                      getTitlesWidget: (value, meta) {
                                        return Padding(
                                          padding: const EdgeInsets.only(right: 4),
                                          child: Text(
                                            _formatMoney(value),
                                            style: const TextStyle(
                                              fontSize: 9,
                                              color: Colors.grey,
                                            ),
                                            textAlign: TextAlign.right,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 40,
                                      interval: _getXAxisInterval(chartByTier.length),
                                      getTitlesWidget: (value, meta) {
                                        final index = value.toInt();
                                        if (index >= chartByTier.length || index < 0) {
                                          return const Text('');
                                        }
                                        final dateStr = chartByTier[index].label;
                                        final date = DateTime.parse(dateStr);
                                        return Transform.rotate(
                                          angle: -0.5, // Xoay 30 độ
                                          child: Text(
                                            DateFormat('dd/MM').format(date),
                                            style: const TextStyle(
                                              fontSize: 9,
                                              color: Colors.grey,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  topTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  rightTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                ),
                                borderData: FlBorderData(
                                  show: true,
                                  border: Border.all(color: Colors.grey[700]!),
                                ),
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: chartByTier.asMap().entries.map((e) {
                                      return FlSpot(
                                        e.key.toDouble(),
                                        e.value.amount,
                                      );
                                    }).toList(),
                                    isCurved: true,
                                    color: Colors.green,
                                    barWidth: 2,
                                    dotData: const FlDotData(show: true),
                                    belowBarData: BarAreaData(
                                      show: true,
                                      color: Colors.green.withOpacity(0.1),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
