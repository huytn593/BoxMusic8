import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/admin/admin_screens.dart';
import '../features/auth/auth_screens.dart';
import '../features/auth/controllers/auth_controller.dart';
import '../features/home/home_screens.dart';
import '../features/library/library_screens.dart';
import '../features/library/playlist_detail_screen_enhanced.dart';
import '../features/notfound/not_found_screen.dart';
import '../features/payment/payment_screens.dart';
import '../features/policy/policy_screen.dart';
import '../features/profile/profile_screens.dart';
import '../features/search/search_screen.dart';
import '../features/track/track_detail_screen.dart';
import '../features/upload/upload_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Watch auth state để trigger rebuild khi state thay đổi
  // Khi authState thay đổi, Provider sẽ rebuild và tạo GoRouter mới
  // GoRouter sẽ tự động chạy redirect khi được rebuild
  final authState = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: '/',
    // Không cần refreshListenable vì router sẽ rebuild tự động khi authState thay đổi
    redirect: (context, state) {
      // Đọc state mới nhất từ provider
      final auth = ref.read(authControllerProvider);
      final loggingIn = state.matchedLocation == '/signin' ||
          state.matchedLocation == '/signup' ||
          state.matchedLocation == '/forgot-password' ||
          state.matchedLocation == '/verify-otp' ||
          state.matchedLocation == '/reset-password';

      final requiresAuth = _protectedPaths.any(
        (path) => state.matchedLocation.startsWith(path),
      );

      if (!auth.initialized) {
        return null;
      }

      // Nếu user chưa authenticated
      if (!auth.isAuthenticated) {
        // Nếu đang ở protected path, redirect về signin
        if (requiresAuth) {
          return '/signin';
        }
        
        // Nếu session đã hết hạn (401), LUÔN redirect về /signin
        // Ngay cả khi đang ở trang chủ hoặc các trang công khai
        if (auth.sessionExpired) {
          // Nếu đã ở trang login rồi, reset flag và cho phép truy cập
          if (loggingIn) {
            // Reset sessionExpired flag khi đã ở trang login
            // Sử dụng addPostFrameCallback để tránh modifying state during build
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final currentAuth = ref.read(authControllerProvider);
              if (currentAuth.sessionExpired) {
                ref.read(authControllerProvider.notifier).state = 
                    currentAuth.copyWith(sessionExpired: false);
              }
            });
            return null;
          }
          // Chưa ở trang login, redirect về /signin
        return '/signin';
      }

        // Nếu đang ở trang signin/signup/forgot-password, cho phép truy cập
        if (loggingIn) {
          return null;
        }
        
        // Nếu chưa đăng nhập và không phải session expired
        // Cho phép truy cập các trang công khai (trang chủ, discover, search, track detail, albums)
        final publicPaths = ['/', '/discover', '/search', '/albums', '/policy'];
        final isPublicPath = publicPaths.contains(state.matchedLocation) ||
            state.matchedLocation.startsWith('/track/');
        
        if (!isPublicPath) {
          // Nếu đang ở trang khác không phải public pages, redirect về signin
          return '/signin';
        }
      }

      // Nếu user đã authenticated nhưng đang ở trang login, redirect về trang chủ
      if (auth.isAuthenticated && loggingIn) {
        return '/';
      }

      // Admin-only routes (chỉ statistic và track-management)
      // Upload: tất cả user đã đăng nhập đều có thể upload (match backend và React frontend)
      if (auth.session?.isAdmin != true &&
          (state.matchedLocation.startsWith('/statistic') ||
              state.matchedLocation.startsWith('/track-management'))) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/discover',
        builder: (context, state) => const DiscoverScreen(),
      ),
      GoRoute(
        path: '/albums',
        builder: (context, state) => const AlbumsScreen(),
      ),
      GoRoute(
        path: '/signin',
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/verify-otp',
        builder: (context, state) => VerifyOtpScreen(
          email: state.uri.queryParameters['email'],
        ),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) => ResetPasswordScreen(
          email: state.uri.queryParameters['email'],
          otp: state.uri.queryParameters['otp'],
        ),
      ),
      GoRoute(
        path: '/profile/:userId',
        builder: (context, state) => ProfileScreen(
          userId: state.pathParameters['userId'] ?? 'me',
        ),
      ),
      GoRoute(
        path: '/personal-profile/:profileId',
        builder: (context, state) => PersonalProfileScreen(
          profileId: state.pathParameters['profileId']!,
        ),
      ),
      GoRoute(
        path: '/upgrade/:userId',
        builder: (context, state) => UpgradeAccountScreen(
          userId: state.pathParameters['userId'] ?? 'me',
        ),
      ),
      GoRoute(
        path: '/payment-result',
        builder: (context, state) => PaymentResultScreen(
          queryParams: state.uri.queryParameters,
        ),
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) => SearchScreen(
          initialQuery:
              state.uri.queryParameters['q'] ?? state.uri.queryParameters['query'] ?? '',
        ),
      ),
      GoRoute(
        path: '/policy',
        builder: (context, state) => const PolicyScreen(),
      ),
      GoRoute(
        path: '/track/:trackId',
        builder: (context, state) => TrackDetailScreen(
          trackId: state.pathParameters['trackId']!,
        ),
      ),
      GoRoute(
        path: '/histories',
        builder: (context, state) => const HistoryScreen(userId: 'me'),
      ),
      GoRoute(
        path: '/track-management',
        builder: (context, state) => const AdminTrackListScreen(),
      ),
      GoRoute(
        path: '/likes',
        builder: (context, state) => const FavoriteScreen(),
      ),
      GoRoute(
        path: '/my-tracks/:profileId',
        builder: (context, state) => MyTrackScreen(
          profileId: state.pathParameters['profileId'] ?? 'me',
        ),
      ),
      GoRoute(
        path: '/upload',
        builder: (context, state) => const UploadTrackScreen(),
      ),
      GoRoute(
        path: '/library/:userId',
        builder: (context, state) => LibraryScreen(
          userId: state.pathParameters['userId'] ?? 'me',
        ),
      ),
      GoRoute(
        path: '/playlist/:playlistId',
        builder: (context, state) => PlaylistDetailScreen(
          playlistId: state.pathParameters['playlistId']!,
        ),
      ),
      GoRoute(
        path: '/statistic',
        builder: (context, state) => const RevenueChartScreen(),
      ),
      GoRoute(
        path: '/follow/:userId',
        builder: (context, state) => FollowScreen(
          userId: state.pathParameters['userId'] ?? 'me',
        ),
      ),
      GoRoute(
        path: '/recommend/:userId',
        builder: (context, state) => RecommendScreen(
          userId: state.pathParameters['userId'] ?? 'me',
        ),
      ),
      GoRoute(
        path: '/not-found',
        builder: (context, state) => const NotFoundScreen(),
      ),
    ],
    errorBuilder: (context, state) => const NotFoundScreen(),
  );
});

const _protectedPaths = {
  '/profile',
  '/likes',
  '/histories',
  '/upload',
  '/library',
  '/playlist',
  '/follow',
  '/recommend',
  '/upgrade',
  '/my-tracks',
};

