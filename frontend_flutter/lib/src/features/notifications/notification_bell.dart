import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/models.dart';
import '../../data/repositories/repository.dart';
import '../../features/auth/controllers/auth_controller.dart';
import 'notification_controller.dart';

final pendingTracksCountProvider = FutureProvider.autoDispose<int>((ref) {
  final repository = ref.watch(repositoryProvider);
  return repository.getPendingTracksCount();
});

class NotificationBell extends ConsumerStatefulWidget {
  const NotificationBell({super.key});

  @override
  ConsumerState<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends ConsumerState<NotificationBell> {

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) {
      return '${diff.inSeconds} giây trước';
    }
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} phút trước';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours} giờ trước';
    }
    return '${diff.inDays} ngày trước';
  }

  void _handleNotificationTap(BuildContext context, NotificationItem item) {
    // Parse notification content để tìm trackId hoặc navigate dựa trên title
    final title = item.title.toLowerCase();
    final content = item.content.toLowerCase();
    
    // Nếu notification về track (duyệt, khóa, xóa, v.v.)
    if (title.contains('nhạc') || title.contains('bài hát') || 
        content.contains('bài hát') || content.contains('nhạc')) {
      // Navigate đến trang "Nhạc của tôi" để user xem danh sách track
      final session = ref.read(authControllerProvider).session;
      if (session != null && context.mounted) {
        context.go('/my-tracks/${session.id}');
      }
    }
    // Có thể thêm các case khác nếu cần (profile, payment, etc.)
  }

  void _showNotificationMenu(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => AlertDialog(
        contentPadding: EdgeInsets.zero,
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320, maxHeight: 500),
          child: _NotificationMenuContent(
            onRefresh: () {
              ref
                  .read(notificationControllerProvider.notifier)
                  .refreshNotifications();
              final session = ref.read(authControllerProvider).session;
              final isAdmin = session?.role?.toLowerCase() == 'admin';
              if (isAdmin) {
                ref.invalidate(pendingTracksCountProvider);
              }
            },
            onClose: () => Navigator.pop(dialogContext),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifications = ref.watch(notificationControllerProvider);
    final items = notifications.valueOrNull ?? const <NotificationItem>[];
    final unread = items.where((item) => !item.isViewed).length;
    
    // Lấy pending tracks count cho admin
    final session = ref.watch(authControllerProvider).session;
    final isAdmin = session?.role?.toLowerCase() == 'admin';
    final pendingCount = isAdmin 
        ? ref.watch(pendingTracksCountProvider)
        : const AsyncValue.data(0);
    
    // Tính tổng số thông báo (unread + pending tracks nếu là admin)
    final totalUnread = unread + (isAdmin 
        ? (pendingCount.valueOrNull ?? 0) 
        : 0);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          tooltip: 'Thông báo',
          icon: const Icon(Icons.notifications_none),
          onPressed: () {
            ref
                .read(notificationControllerProvider.notifier)
                .refreshNotifications();
            if (isAdmin) {
              ref.invalidate(pendingTracksCountProvider);
            }
            _showNotificationMenu(context);
          },
        ),
        if (totalUnread > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                totalUnread.toString(),
                style: const TextStyle(fontSize: 11),
              ),
            ),
          ),
      ],
    );
  }
}

class _NotificationMenuContent extends ConsumerWidget {
  const _NotificationMenuContent({
    required this.onRefresh,
    required this.onClose,
  });

  final VoidCallback onRefresh;
  final VoidCallback onClose;

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) {
      return '${diff.inSeconds} giây trước';
    }
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} phút trước';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours} giờ trước';
    }
    return '${diff.inDays} ngày trước';
  }

  void _handleNotificationTap(BuildContext context, NotificationItem item, WidgetRef ref) {
    // Parse notification content để tìm trackId hoặc navigate dựa trên title
    final title = item.title.toLowerCase();
    final content = item.content.toLowerCase();
    
    // Nếu notification về track (duyệt, khóa, xóa, v.v.)
    if (title.contains('nhạc') || title.contains('bài hát') || 
        content.contains('bài hát') || content.contains('nhạc')) {
      // Navigate đến trang "Nhạc của tôi" để user xem danh sách track
      final session = ref.read(authControllerProvider).session;
      if (session != null && context.mounted) {
        context.go('/my-tracks/${session.id}');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationControllerProvider);
    final items = notifications.valueOrNull ?? const <NotificationItem>[];
    final session = ref.watch(authControllerProvider).session;
    final isAdmin = session?.role?.toLowerCase() == 'admin';
    final pendingCount = isAdmin 
        ? ref.watch(pendingTracksCountProvider)
        : const AsyncValue.data(0);

    return SizedBox(
      width: 320,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Thông báo',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 20),
                      tooltip: 'Làm mới',
                      onPressed: onRefresh,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      tooltip: 'Đóng',
                      onPressed: onClose,
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isAdmin && pendingCount.valueOrNull != null && pendingCount.valueOrNull! > 0) ...[
            ListTile(
              dense: true,
              leading: const Icon(Icons.music_note, color: Colors.orange),
              title: Text(
                '${pendingCount.valueOrNull} bài hát đang chờ xét duyệt',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              onTap: () {
                onClose();
                context.go('/track-management');
              },
            ),
            const Divider(height: 1),
          ],
          // Notifications list
          notifications.when(
            data: (items) {
              if (items.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: Text('Không có thông báo nào')),
                );
              }
              return SizedBox(
                height: 400,
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return ListTile(
                      dense: true,
                      onTap: () {
                        onClose();
                        // Mark as viewed
                        if (!item.isViewed) {
                          ref
                              .read(notificationControllerProvider.notifier)
                              .markAsViewed(item.id);
                        }
                        // Navigate
                        _handleNotificationTap(context, item, ref);
                      },
                      leading: Icon(
                        item.isViewed
                            ? Icons.notifications_outlined
                            : Icons.notifications_active,
                        color: item.isViewed
                            ? Colors.white70
                            : Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                      title: Text(
                        item.title,
                        style: TextStyle(
                          fontWeight: item.isViewed
                              ? FontWeight.w500
                              : FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.content,
                            style: const TextStyle(fontSize: 11),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _timeAgo(item.createdAt),
                            style: const TextStyle(fontSize: 10, color: Colors.white54),
                          ),
                        ],
                      ),
                      trailing: !item.isViewed
                          ? const Icon(
                              Icons.circle,
                              color: Colors.redAccent,
                              size: 10,
                            )
                          : null,
                    );
                  },
                ),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (error, stack) => Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text('Lỗi: $error'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

