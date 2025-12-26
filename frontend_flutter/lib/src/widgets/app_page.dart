import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/network/api_client.dart';
import '../core/utils/image_utils.dart';
import '../features/auth/controllers/auth_controller.dart';
import '../features/notifications/notification_bell.dart';
import '../features/notifications/notification_controller.dart';
import '../music_player/music_player_controller.dart';
import '../music_player/widgets/music_player_bar.dart';
import '../router/app_router.dart';

class AppPage extends ConsumerWidget {
  const AppPage({
    super.key,
    required this.title,
    required this.child,
    this.actions,
    this.fab,
    this.showMusicBar = true,
    this.showPrimaryNav = true,
  });

  final String title;
  final Widget child;
  final List<Widget>? actions;
  final Widget? fab;
  final bool showMusicBar;
  final bool showPrimaryNav;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch auth state để rebuild khi thay đổi
    final authState = ref.watch(authControllerProvider);
    final user = authState.session;

    // Listen to music player errors for VIP/Login popups
    ref.listen(musicPlayerControllerProvider, (previous, next) {
      if (previous?.errorMessage == next.errorMessage || next.errorMessage == null) {
        return;
      }

      final error = next.errorMessage!;
      if (error == kErrorRequireVip) {
        // Show VIP Upgrade Dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Dành riêng cho VIP'),
            content: const Text(
              'Bài hát này dành riêng cho tài khoản VIP. Vui lòng nâng cấp tài khoản để thưởng thức trọn vẹn kho nhạc chất lượng cao.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Đóng'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  final currentUser = ref.read(authControllerProvider).session;
                  if (currentUser != null) {
                    context.go('/upgrade/${currentUser.id}');
                  } else {
                     context.go('/signin');
                  }
                },
                child: const Text('Nâng cấp ngay'),
              ),
            ],
          ),
        );
      } else if (error == kErrorRequireLogin) {
        // Show Login Prompt
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Cần đăng nhập'),
            content: const Text('Bạn cần đăng nhập để nghe bài hát này.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Đóng'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.go('/signin');
                },
                child: const Text('Đăng nhập'),
              ),
            ],
          ),
        );
      } else {
        // Show standard error snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
    
    // Kiểm tra route hiện tại để ẩn các thành phần ở màn hình auth
    final router = GoRouter.of(context);
    final currentLocation = router.routerDelegate.currentConfiguration.uri.path;
    final isAuthScreen = currentLocation == '/signin' ||
        currentLocation == '/signup' ||
        currentLocation == '/forgot-password';
    
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            Image.asset(
              'assets/images/icon.png',
              width: 64,
              height: 64,
            ),
            const SizedBox(width: 8),
            // Dùng Expanded + ellipsis để tránh pixel overflow với title dài
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        bottom: isAuthScreen
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(60),
                child: TopNavigationBar(),
              ),
        actions: isAuthScreen
            ? null
            : [
                if (user != null) const NotificationBell(),
                ...?actions,
                // Luôn render _UserAvatarMenu, widget sẽ tự ẩn nếu user null
                _UserAvatarMenu(
                  key: ValueKey('user_avatar_${user?.id ?? 'null'}_${authState.initialized}'),
                ),
              ],
      ),
      floatingActionButton: fab,
      body: SafeArea(child: child),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showMusicBar) const MusicPlayerBar(),
          if (showPrimaryNav) const PrimaryNavigationBar(),
        ],
      ),
    );
  }
}

class PrimaryNavigationBar extends ConsumerWidget {
  const PrimaryNavigationBar({super.key});

  List<_NavDestination> _getDestinations(UserSession? user) {
    // Ẩn menu cho người dùng chưa đăng nhập
    if (user == null) {
      return [
        const _NavDestination(label: 'Trang chủ', icon: Icons.home_filled, route: '/'),
        const _NavDestination(label: 'Khám phá', icon: Icons.explore, route: '/discover'),
      ];
    }
    
    if (user.isAdmin) {
      return [
        const _NavDestination(label: 'Trang chủ', icon: Icons.home_filled, route: '/'),
        const _NavDestination(label: 'Khám phá', icon: Icons.explore, route: '/discover'),
        const _NavDestination(label: 'Thư viện', icon: Icons.library_music, route: '/library/me'),
        const _NavDestination(label: 'Menu', icon: Icons.menu, route: '/menu', isMenu: true),
      ];
    }
    return [
      const _NavDestination(label: 'Trang chủ', icon: Icons.home_filled, route: '/'),
      const _NavDestination(label: 'Khám phá', icon: Icons.explore, route: '/discover'),
      const _NavDestination(label: 'Thư viện', icon: Icons.library_music, route: '/library/me'),
      const _NavDestination(label: 'Menu', icon: Icons.menu, route: '/menu', isMenu: true),
    ];
  }

  int _indexForLocation(String location, List<_NavDestination> destinations) {
    for (int i = 0; i < destinations.length; i++) {
      final dest = destinations[i];
      if (dest.isMenu) continue; // Menu không có route cụ thể
      if (location == dest.route || 
          (dest.route == '/library/me' && location.startsWith('/library')) ||
          (dest.route == '/profile/me' && (location.startsWith('/profile') || location.startsWith('/personal-profile')))) {
        return i;
      }
    }
    return 0;
  }

  void _showMenuSheet(BuildContext context, WidgetRef ref) {
    final user = ref.read(authControllerProvider).session;
    final router = GoRouter.of(context);
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Menu',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (user == null) ...[
                      ListTile(
                        leading: const Icon(Icons.login),
                        title: const Text('Đăng nhập'),
                        onTap: () {
                          Navigator.pop(context);
                          router.go('/signin');
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.person_add),
                        title: const Text('Đăng ký'),
                        onTap: () {
                          Navigator.pop(context);
                          router.go('/signup');
                        },
                      ),
            ] else ...[
              if (user.isAdmin) ...[
                // Menu cho Admin - chỉ các chức năng chủ yếu
                ListTile(
                  leading: const Icon(Icons.bar_chart),
                  title: const Text('Thống kê doanh thu'),
                  onTap: () {
                    Navigator.pop(context);
                    router.go('/statistic');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.music_note),
                  title: const Text('Quản lý nhạc'),
                  onTap: () {
                    Navigator.pop(context);
                    router.go('/track-management');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.upload),
                  title: const Text('Tải lên'),
                  onTap: () {
                    Navigator.pop(context);
                    router.go('/upload');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.history),
                  title: const Text('Lịch sử nghe'),
                  onTap: () {
                    Navigator.pop(context);
                    router.go('/histories');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('Cá nhân'),
                  onTap: () {
                    Navigator.pop(context);
                    router.go('/profile/${user.id}');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.people),
                  title: const Text('Đang theo dõi'),
                  onTap: () {
                    Navigator.pop(context);
                    router.go('/follow/${user.id}');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Đăng xuất'),
                  onTap: () async {
                    Navigator.pop(context);
                    final authController = ref.read(authControllerProvider.notifier);
                    await authController.logout();
                    router.go('/signin');
                  },
                ),
              ] else ...[
                // Menu cho User thường
                ListTile(
                  leading: const Icon(Icons.upload),
                  title: const Text('Tải lên'),
                  onTap: () {
                    Navigator.pop(context);
                    router.go('/upload');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.history),
                  title: const Text('Lịch sử nghe'),
                  onTap: () {
                    Navigator.pop(context);
                    router.go('/histories');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.favorite),
                  title: const Text('Dành cho bạn'),
                  onTap: () {
                    Navigator.pop(context);
                    router.go('/recommend/${user.id}');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.my_library_music),
                  title: const Text('Nhạc của tôi'),
                  onTap: () {
                    Navigator.pop(context);
                    router.go('/my-tracks/${user.id}');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('Cá nhân'),
                  onTap: () {
                    Navigator.pop(context);
                    router.go('/profile/${user.id}');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.people),
                  title: const Text('Đang theo dõi'),
                  onTap: () {
                    Navigator.pop(context);
                    router.go('/follow/${user.id}');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.workspace_premium),
                  title: const Text('Nâng cấp tài khoản'),
                  onTap: () {
                    Navigator.pop(context);
                    router.go('/upgrade/${user.id}');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Đăng xuất'),
                  onTap: () async {
                    Navigator.pop(context);
                    final authController = ref.read(authControllerProvider.notifier);
                    await authController.logout();
                    router.go('/signin');
                  },
                ),
              ],
            ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).session;
    final destinations = _getDestinations(user);
    final router = GoRouter.of(context);
    final routeInfo = router.routeInformationProvider.value;
    final infoLocation = routeInfo.uri.toString();
    final location = infoLocation.isNotEmpty
        ? infoLocation
        : (router.routerDelegate.currentConfiguration.isNotEmpty
            ? router.routerDelegate.currentConfiguration.last.matchedLocation
            : '/');
    final currentIndex = _indexForLocation(location, destinations);

    return NavigationBar(
      selectedIndex: currentIndex,
      indicatorColor: Colors.red.withOpacity(0.2), // Background màu đỏ nhạt cho item được chọn
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      destinations: [
        for (int i = 0; i < destinations.length; i++)
          NavigationDestination(
            icon: Icon(
              destinations[i].icon,
              color: i == currentIndex ? Colors.red : null, // Màu đỏ khi được chọn
            ),
            selectedIcon: Icon(
              destinations[i].icon,
              color: Colors.red, // Màu đỏ khi được chọn
            ),
            label: destinations[i].label,
          ),
      ],
      onDestinationSelected: (index) {
        final destination = destinations[index];
        if (destination.isMenu) {
          _showMenuSheet(context, ref);
          return;
        }
        final currentUser = ref.read(authControllerProvider).session;
        String target = destination.route;
        if (destination.route == '/profile/me') {
          target = currentUser != null ? '/profile/${currentUser.id}' : '/signin';
        } else if (destination.route == '/library/me') {
          // Nếu user chưa đăng nhập, redirect về signin
          if (currentUser == null) {
            router.go('/signin');
            return;
          }
          target = '/library/${currentUser.id}';
        }
        router.go(target);
      },
    );
  }
}

class _NavDestination {
  const _NavDestination({
    required this.label,
    required this.icon,
    required this.route,
    this.isMenu = false,
  });

  final String label;
  final IconData icon;
  final String route;
  final bool isMenu;
}

ImageProvider<Object> _avatarProvider(String? data) {
  return buildAvatarProvider(data);
}

class TopNavigationBar extends ConsumerStatefulWidget {
  const TopNavigationBar({super.key});

  @override
  ConsumerState<TopNavigationBar> createState() => _TopNavigationBarState();
}

class _TopNavigationBarState extends ConsumerState<TopNavigationBar> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_NavLink> get _navLinks {
    // Watch auth state trực tiếp thay vì dùng props
    final user = ref.watch(authControllerProvider).session;
    if (user?.isAdmin ?? false) {
      return [
        const _NavLink(
          label: 'Thống kê doanh thu',
          route: '/statistic',
          requiresAuth: true,
        ),
        const _NavLink(
          label: 'Quản lý nhạc',
          route: '/track-management',
          requiresAuth: true,
        ),
        const _NavLink(
          label: 'Tải lên nhạc mới',
          route: '/upload',
          requiresAuth: true,
        ),
      ];
    }

    return [
      const _NavLink(label: 'Trang chủ', route: '/'),
      const _NavLink(label: 'Khám phá', route: '/discover'),
      const _NavLink(
        label: 'Tải lên',
        route: '/upload',
        requiresAuth: true,
      ),
      const _NavLink(
        label: 'Thư viện',
        requiresAuth: true,
        routeBuilder: _NavRouteBuilder.library,
      ),
      const _NavLink(
        label: 'Lịch sử nghe',
        route: '/histories',
        requiresAuth: true,
      ),
      const _NavLink(
        label: 'Dành cho bạn',
        requiresAuth: true,
        routeBuilder: _NavRouteBuilder.recommend,
      ),
      if (user != null)
        const _NavLink(
          label: 'Nhạc của tôi',
          requiresAuth: true,
          routeBuilder: _NavRouteBuilder.myTracks,
        ),
    ];
  }

  Future<void> _promptSignin() async {
    final shouldLogin = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cần đăng nhập'),
        content: const Text('Bạn cần đăng nhập để sử dụng tính năng này.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Để sau'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Đăng nhập'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (shouldLogin == true) {
      context.go('/signin');
    }
  }

  Future<void> _onNavTap(_NavLink link) async {
    // Lấy user từ auth state thay vì dùng props
    final user = ref.read(authControllerProvider).session;
    if (link.requiresAuth && user == null) {
      await _promptSignin();
      return;
    }

    final target = link.resolve(user);
    if (target == null) {
      await _promptSignin();
      return;
    }

    if (context.mounted) {
      context.go(target);
    }
  }

  void _submitSearch() {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    context.go('/search?q=${Uri.encodeComponent(query)}');
  }

  @override
  Widget build(BuildContext context) {
    // Loại bỏ nav links vì đã có menu rồi, chỉ giữ search bar
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: SizedBox(
        height: 44,
        child: TextField(
          controller: _searchController,
          onSubmitted: (_) => _submitSearch(),
          style: const TextStyle(fontSize: 14), // Thu nhỏ chữ
          decoration: InputDecoration(
            hintText: 'Nhập tên bài hát hoặc người dùng...',
            hintStyle: const TextStyle(fontSize: 14), // Thu nhỏ chữ hint
            prefixIcon: const Icon(Icons.search, size: 20), // Thu nhỏ icon
            suffixIcon: IconButton(
              icon: const Icon(Icons.arrow_forward, size: 20), // Thu nhỏ icon
              onPressed: _submitSearch,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(999),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), // Giảm padding
          ),
        ),
      ),
    );
  }
}

class _NavLink {
  const _NavLink({
    required this.label,
    this.route,
    this.routeBuilder,
    this.requiresAuth = false,
  });

  final String label;
  final String? route;
  final String Function(UserSession user)? routeBuilder;
  final bool requiresAuth;

  String? resolve(UserSession? user) {
    if (routeBuilder != null) {
      if (user == null) return null;
      return routeBuilder!(user);
    }
    return route;
  }
}

class _NavRouteBuilder {
  static String library(UserSession user) => '/library/${user.id}';
  static String recommend(UserSession user) => '/recommend/${user.id}';
  static String myTracks(UserSession user) => '/my-tracks/${user.id}';
}

class _UserAvatarMenu extends ConsumerWidget {
  const _UserAvatarMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch auth state trực tiếp - widget sẽ rebuild khi auth state thay đổi
    final authState = ref.watch(authControllerProvider);
    final user = authState.session;
    
    // Nếu user null hoặc chưa initialized, không hiển thị menu
    // Hiển thị nút đăng nhập/đăng ký thay thế
    if (user == null || !authState.initialized) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            onPressed: () => context.go('/signin'),
            child: const Text('Đăng nhập'),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: () => context.go('/signup'),
            child: const Text('Đăng ký'),
          ),
          const SizedBox(width: 16),
        ],
      );
    }
    
    // Dùng key dựa trên user.id và initialized để force rebuild khi user thay đổi
    // Điều này đảm bảo PopupMenuButton được tạo lại khi logout
    return PopupMenuButton<_UserMenuAction>(
      key: ValueKey('user_menu_${user.id}_${authState.initialized}'),
      tooltip: 'Tài khoản',
      offset: const Offset(0, 48),
      itemBuilder: (context) {
        // Double check user trong itemBuilder để đảm bảo menu không hiển thị nếu user null
        final currentAuthState = ref.read(authControllerProvider);
        final currentUser = currentAuthState.session;
        
        // Nếu user null hoặc chưa initialized, không hiển thị menu items
        if (currentUser == null || !currentAuthState.initialized) {
          return const [];
        }
        
        return [
          const PopupMenuItem(
            value: _UserMenuAction.profile,
            child: Text('Trang cá nhân'),
          ),
          const PopupMenuItem(
            value: _UserMenuAction.library,
            child: Text('Thư viện của tôi'),
          ),
          const PopupMenuItem(
            value: _UserMenuAction.history,
            child: Text('Lịch sử nghe'),
          ),
          if (!currentUser.isAdmin)
            const PopupMenuItem(
              value: _UserMenuAction.upgrade,
              child: Text('Nâng cấp tài khoản'),
            ),
          const PopupMenuDivider(),
          const PopupMenuItem(
            value: _UserMenuAction.logout,
            child: Text('Đăng xuất'),
          ),
        ];
      },
      onSelected: (action) => _handleAction(action, context, ref),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: CircleAvatar(
          radius: 18,
          backgroundImage: _avatarProvider(user.avatarBase64),
        ),
      ),
    );
  }

  Future<void> _handleAction(
    _UserMenuAction action,
    BuildContext context,
    WidgetRef ref,
  ) async {
    // Lấy user từ auth state
    final user = ref.read(authControllerProvider).session;
    if (user == null) {
      // Nếu user null, redirect về signin
      if (context.mounted) {
        context.go('/signin');
      }
      return;
    }
    
    switch (action) {
      case _UserMenuAction.profile:
        context.go('/profile/${user.id}');
        break;
      case _UserMenuAction.library:
        context.go('/library/${user.id}');
        break;
      case _UserMenuAction.history:
        context.go('/histories');
        break;
      case _UserMenuAction.upgrade:
        context.go('/upgrade/${user.id}');
        break;
      case _UserMenuAction.logout:
        // PopupMenuButton tự động đóng khi onSelected được gọi
        // Nhưng để đảm bảo, đợi một frame trước khi hiển thị dialog
        await Future.delayed(const Duration(milliseconds: 50));
        
        if (!context.mounted) return;
        
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Đăng xuất'),
            content: const Text('Bạn chắc chắn muốn đăng xuất?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Hủy'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Đăng xuất'),
              ),
            ],
          ),
        );
        
        if (confirm == true && context.mounted) {
          // ============================================================
          // GIẢI PHÁP TOÀN DIỆN CHO LOGOUT - ĐẢM BẢO UI REBUILD VÀ REDIRECT
          // ============================================================
          // Vấn đề: UI không rebuild sau khi logout → dropdown vẫn hiển thị
          // Giải pháp: Clear state → Force UI rebuild → Force router redirect
          // ============================================================
          
          // Capture tất cả cần thiết TRƯỚC KHI await
          final currentContext = context;
          final router = GoRouter.of(currentContext);
          final authController = ref.read(authControllerProvider.notifier);
          final musicPlayerController = ref.read(musicPlayerControllerProvider.notifier);
          
          // Bước 1: Clear notifications ngay lập tức TRƯỚC KHI làm gì cả
          // Ngăn chúng tiếp tục gọi API sau khi logout và clear UI ngay
          ref.read(notificationControllerProvider.notifier).clearNotifications();
          // Sau đó invalidate để đảm bảo provider được rebuild khi login lại
          ref.invalidate(notificationControllerProvider);
          
          // Bước 2: Reset music player và đợi hoàn tất
          // QUAN TRỌNG: Phải await để đảm bảo nhạc dừng và state được clear trước khi logout
          try {
            await musicPlayerController.reset();
          } catch (_) {
            // Ignore errors nhưng vẫn tiếp tục logout
          }
          // Invalidate provider để đảm bảo UI rebuild và ẩn music player bar
          ref.invalidate(musicPlayerControllerProvider);
          
          // Bước 3: Clear storage và state NGAY LẬP TỨC
          // QUAN TRỌNG: 
          // - Clear token TRƯỚC để Dio interceptor không dùng token cũ
          // - Set session = null → UI sẽ rebuild và ẩn dropdown
          // - Set sessionExpired = true → Router sẽ redirect
          await authController.clearStorageAndState();
          
          if (currentContext.mounted) {
            router.go('/');
          }
          
          // Bước 6: Gọi API logout ở background (không đợi, không quan trọng)
          // API có thể fail (Invalid token) nhưng không sao vì:
          // - Token đã được xóa khỏi storage → Dio interceptor không thêm Authorization header
          // - State đã được clear → UI đã refresh
          // - Router đã redirect về /signin → User đã được chuyển về trang đăng nhập
          authController.logoutApiOnly().catchError((_) {
            // Ignore errors - không quan trọng
          });
        }
        break;
    }
  }
}

enum _UserMenuAction { profile, library, history, upgrade, logout }

