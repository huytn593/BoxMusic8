import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/utils/image_utils.dart';
import '../music_player_controller.dart';

class MusicPlayerBar extends ConsumerWidget {
  const MusicPlayerBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(musicPlayerControllerProvider);
    final controller = ref.read(musicPlayerControllerProvider.notifier);
    final track = playerState.currentTrack;

    if (track == null) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0E0E0E),
        border: Border(
          top: BorderSide(color: Colors.white12),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _TrackImage(
                  key: ValueKey(track.id), // Key để tránh rebuild không cần thiết
                  data: track.imageBase64,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track.title,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      softWrap: true,
                    ),
                    Text(
                      track.artistName ?? 'BoxMusic',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.white70),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: controller.previous,
                icon: const Icon(Icons.skip_previous_rounded),
              ),
              IconButton(
                onPressed: controller.togglePlay,
                icon: Icon(
                  playerState.isPlaying
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_fill,
                  size: 32,
                ),
              ),
              IconButton(
                onPressed: controller.next,
                icon: const Icon(Icons.skip_next_rounded),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            ),
            child: Slider(
              min: 0,
              max: playerState.duration.inMilliseconds.toDouble().clamp(1, double.infinity),
              value: playerState.position.inMilliseconds
                  .clamp(0, playerState.duration.inMilliseconds)
                  .toDouble(),
              onChanged: (value) => controller.seek(
                Duration(milliseconds: value.toInt()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackImage extends StatefulWidget {
  const _TrackImage({super.key, this.data});

  final String? data;

  @override
  State<_TrackImage> createState() => _TrackImageState();
}

class _TrackImageState extends State<_TrackImage> {
  ImageProvider? _imageProvider;
  String? _lastData;

  @override
  void initState() {
    super.initState();
    _updateImageProvider();
  }

  @override
  void didUpdateWidget(_TrackImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      _updateImageProvider();
    }
  }

  void _updateImageProvider() {
    final imageData = widget.data;
    if (imageData == null || imageData.isEmpty) {
      _imageProvider = null;
      _lastData = null;
      return;
    }

    // Chỉ update nếu data thay đổi
    if (_lastData == imageData) return;
    _lastData = imageData;

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
      _imageProvider = NetworkImage(imageUrl);
      return;
    }

    // Kiểm tra nếu là relative path (bắt đầu bằng /)
    if (imageData.startsWith('/')) {
      final baseUrl = AppConfig.apiBaseUrl.replaceAll('/api', '');
      final imageUrl = '$baseUrl$imageData';
      _imageProvider = NetworkImage(imageUrl);
      return;
    }

    // Thử decode base64
    final bytes = tryDecodeBase64Image(imageData);
    if (bytes != null) {
      _imageProvider = MemoryImage(bytes);
      return;
    }

    _imageProvider = null;
  }

  @override
  Widget build(BuildContext context) {
    if (_imageProvider == null) {
      return Image.asset(
        AppConfig.defaultTrackImage,
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Image.asset(
            'assets/images/default-music.jpg',
            width: 48,
            height: 48,
            fit: BoxFit.cover,
          );
        },
      );
    }

    return Image(
      image: _imageProvider!,
      width: 48,
      height: 48,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return SizedBox(
          width: 48,
          height: 48,
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
        return Image.asset(
          AppConfig.defaultTrackImage,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Image.asset(
              'assets/images/default-music.jpg',
              width: 48,
              height: 48,
              fit: BoxFit.cover,
            );
          },
        );
      },
    );
  }
}

