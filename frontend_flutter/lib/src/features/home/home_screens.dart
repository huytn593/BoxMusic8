import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../data/models/models.dart';
import '../../data/repositories/repository.dart';
import '../../widgets/app_page.dart';
import '../../widgets/async_value_widget.dart';
import '../../widgets/track_collection.dart';

// Cache providers để không load lại mỗi lần vào app
final _topTracksProvider =
    FutureProvider<List<TrackSummary>>((ref) {
  final repository = ref.watch(repositoryProvider);
  return repository.topPlayedTracks();
});

final _topLikedProvider =
    FutureProvider<List<TrackSummary>>((ref) {
  final repository = ref.watch(repositoryProvider);
  return repository.topLikedTracks();
});

// Load toàn bộ track (đã approved) để hiển thị đầy đủ
final _allTracksProvider =
    FutureProvider<List<TrackSummary>>((ref) {
  final repository = ref.watch(repositoryProvider);
  return repository.getAllTracks();
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topTracks = ref.watch(_topTracksProvider);
    final topLiked = ref.watch(_topLikedProvider);
    final allTracks = ref.watch(_allTracksProvider);

    return AppPage(
      title: 'BoxMusic',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeroSection(onGetStarted: () => context.go('/discover')),
            const SizedBox(height: 32),
            Text(
              'Bài hát đang thịnh hành',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            AsyncValueWidget(
              value: topTracks,
              data: (tracks) => TrackCollection(
                tracks: tracks,
                onDetails: (track) => context.go('/track/${track.id}'),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Được yêu thích nhất',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            AsyncValueWidget(
              value: topLiked,
              data: (tracks) => TrackCollection(
                tracks: tracks,
                onDetails: (track) => context.go('/track/${track.id}'),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Tất cả bài hát',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            AsyncValueWidget(
              value: allTracks,
              data: (tracks) => TrackCollection(
                tracks: tracks,
                onDetails: (track) => context.go('/track/${track.id}'),
              ),
            ),
            const SizedBox(height: 32),
            _PolicyBanner(onTap: () => context.go('/policy')),
          ],
        ),
      ),
    );
  }
}

class DiscoverScreen extends ConsumerWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topTracks = ref.watch(_topTracksProvider);
    final topLiked = ref.watch(_topLikedProvider);

    return AppPage(
      title: 'Khám phá',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Phổ biến nhất',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            AsyncValueWidget(
              value: topTracks,
              data: (tracks) => TrackCollection(
                tracks: tracks,
                onDetails: (track) => context.go('/track/${track.id}'),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Được yêu thích nhất',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            AsyncValueWidget(
              value: topLiked,
              data: (tracks) => TrackCollection(
                tracks: tracks,
                onDetails: (track) => context.go('/track/${track.id}'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Dùng lại providers đã cache thay vì tạo mới
final _albumsTopPlayedProvider = _topTracksProvider;
final _albumsTopLikedProvider = _topLikedProvider;

class AlbumsScreen extends ConsumerWidget {
  const AlbumsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topPlayed = ref.watch(_albumsTopPlayedProvider);
    final topLiked = ref.watch(_albumsTopLikedProvider);

    return AppPage(
      title: 'Albums',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Played Section
            const Text(
              'Top Bài Hát Phổ Biến',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            AsyncValueWidget(
              value: topPlayed,
              data: (tracks) {
                if (tracks.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: Text('Chưa có bài hát nào.')),
                  );
                }
                return TrackCollection(
                  tracks: tracks,
                );
              },
              loading: const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, stack) => Padding(
                padding: const EdgeInsets.all(16),
                child: Center(child: Text('Lỗi: $error')),
              ),
            ),
            const SizedBox(height: 32),
            // Top Liked Section
            const Text(
              'Top Bài Hát Yêu Thích',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            AsyncValueWidget(
              value: topLiked,
              data: (tracks) {
                if (tracks.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: Text('Chưa có bài hát nào.')),
                  );
                }
                return TrackCollection(
                  tracks: tracks,
                );
              },
              loading: const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, stack) => Padding(
                padding: const EdgeInsets.all(16),
                child: Center(child: Text('Lỗi: $error')),
              ),
              onRefresh: () => ref.invalidate(_topLikedProvider),
            ),
          ],
        ),
      ),
    );
  }
}

final recommendTracksProvider =
    FutureProvider.autoDispose.family<List<TrackSummary>, String>((ref, userId) {
  final repository = ref.watch(repositoryProvider);
  return repository.recommendTracks(userId);
});

class RecommendScreen extends ConsumerWidget {
  const RecommendScreen({
    super.key,
    required this.userId,
  });

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracks = ref.watch(recommendTracksProvider(userId));
    return AppPage(
      title: 'Dành cho bạn',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dựa vào những bài hát bạn đã nghe gần đây',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            AsyncValueWidget(
                value: tracks,
                data: (data) {
                  if (data.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.music_off,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Không có bài hát gợi ý nào.',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Hãy nghe thêm nhiều bài hát để chúng tôi có thể gợi ý cho bạn!',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }
                  return TrackCollection(
                    tracks: data,
                    onDetails: (track) => context.go('/track/${track.id}'),
                  );
                },
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection({required this.onGetStarted});

  final VoidCallback onGetStarted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        image: DecorationImage(
          image: const AssetImage(AppConfig.heroBackground),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withValues(alpha: 0.65),
            BlendMode.darken,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Khám phá âm nhạc mới',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            'Nghe nhạc trực tuyến miễn phí. Khám phá hàng triệu bài hát và playlist từ các nghệ sĩ trên toàn thế giới.',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            children: [
              ElevatedButton(
                onPressed: onGetStarted,
                child: const Text('Bắt đầu ngay'),
              ),
              OutlinedButton(
                onPressed: () => context.go('/discover'),
                child: const Text('Khám phá playlist'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PolicyBanner extends StatelessWidget {
  const _PolicyBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF151515),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Expanded(
              child: Text(
                'Xem chính sách quyền riêng tư của chúng tôi',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }
}

