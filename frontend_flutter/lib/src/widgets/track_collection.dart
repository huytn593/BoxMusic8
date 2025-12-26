import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import '../core/utils/image_utils.dart';
import '../data/models/models.dart';
import '../music_player/music_player_controller.dart';

class TrackCollection extends ConsumerWidget {
  const TrackCollection({
    super.key,
    required this.tracks,
    this.onDetails,
  });

  final List<TrackSummary> tracks;
  final void Function(TrackSummary track)? onDetails;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (tracks.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Text('Không có bài hát nào.'),
        ),
      );
    }

    final controller = ref.read(musicPlayerControllerProvider.notifier);
    final columns = MediaQuery.sizeOf(context).width ~/ 160;
    final crossAxisCount = columns.clamp(2, 4);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: tracks.length,
      itemBuilder: (context, index) {
        final track = tracks[index];
        return Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // Image với onTap để navigate đến track detail
                Expanded(
                child: GestureDetector(
                  onTap: onDetails != null ? () => onDetails!(track) : null,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _TrackImage(data: track.imageBase64),
                  ),
                  ),
                ),
                const SizedBox(height: 12),
              // Title và artist với onTap để navigate
              GestureDetector(
                onTap: onDetails != null ? () => onDetails!(track) : null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(
                  track.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  softWrap: true,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                // Ưu tiên artistName, fallback 'user' thay vì 'BoxMusic' để khớp màn chi tiết
                Text(
                  (track.artistName?.trim().isNotEmpty ?? false)
                      ? track.artistName!.trim()
                      : 'user',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
                ),
                const SizedBox(height: 8),
              // Row chứa nút play - không có GestureDetector để tránh conflict
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.play_circle_fill),
                      color: Theme.of(context).colorScheme.primary,
                    onPressed: () {
                      // Chỉ play nhạc, không navigate
                      // IconButton tự động stop event propagation
                      controller.playTracks(
                        tracks,
                        startIndex: index,
                      );
                    },
                    ),
                    if (!track.isPublic)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade700.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'VIP',
                          style: TextStyle(
                            color: Colors.amber,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
          ),
        );
      },
    );
  }
}

class _TrackImage extends StatelessWidget {
  const _TrackImage({this.data});

  final String? data;

  @override
  Widget build(BuildContext context) {
    final imageData = data;
    if (imageData == null || imageData.isEmpty) {
      return Image.asset(
        AppConfig.defaultTrackImage,
        fit: BoxFit.contain,
        width: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return Image.asset(
            'assets/images/default-music.jpg',
            fit: BoxFit.contain,
            width: double.infinity,
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
        width: double.infinity,
        cacheWidth: 300, // Cache với kích thước tối ưu
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
            AppConfig.defaultTrackImage,
            fit: BoxFit.cover,
            width: double.infinity,
            errorBuilder: (context, error, stackTrace) {
              return Image.asset(
                'assets/images/default-music.jpg',
                fit: BoxFit.cover,
                width: double.infinity,
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
        width: double.infinity,
        cacheWidth: 300, // Cache với kích thước tối ưu
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
            AppConfig.defaultTrackImage,
            fit: BoxFit.cover,
            width: double.infinity,
            errorBuilder: (context, error, stackTrace) {
              return Image.asset(
                'assets/images/default-music.jpg',
                fit: BoxFit.cover,
                width: double.infinity,
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
        width: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return Image.asset(
            AppConfig.defaultTrackImage,
            fit: BoxFit.cover,
            width: double.infinity,
            errorBuilder: (context, error, stackTrace) {
              return Image.asset(
                'assets/images/default-music.jpg',
                fit: BoxFit.cover,
                width: double.infinity,
              );
            },
          );
        },
      );
    }

    // Fallback về default image
    return Image.asset(
      AppConfig.defaultTrackImage,
      fit: BoxFit.cover,
      width: double.infinity,
      errorBuilder: (context, error, stackTrace) {
        return Image.asset(
          'assets/images/default-music.jpg',
          fit: BoxFit.cover,
          width: double.infinity,
        );
      },
    );
  }
}

