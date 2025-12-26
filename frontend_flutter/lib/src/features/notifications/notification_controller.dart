import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/signalr_service.dart';
import '../../core/storage/token_storage.dart';
import '../../data/models/models.dart';
import '../../data/repositories/repository.dart';
import '../auth/controllers/auth_controller.dart';

final notificationControllerProvider = AutoDisposeAsyncNotifierProvider<
    NotificationController, List<NotificationItem>>(NotificationController.new);

class NotificationController
    extends AutoDisposeAsyncNotifier<List<NotificationItem>> {
  StreamSubscription? _signalRSubscription;
  final _signalRService = SignalRService();

  @override
  FutureOr<List<NotificationItem>> build() async {
    // Watch auth state để rebuild khi session thay đổi
    final authState = ref.watch(authControllerProvider);
    final session = authState.session;
    
    // Nếu session null, chưa initialized, hoặc session expired
    // return empty list ngay lập tức - không gọi API
    // Điều này ngăn race condition khi logout hoặc session expired
    if (session == null || !authState.initialized || authState.sessionExpired) {
      // Disconnect SignalR nếu đã connect
      _cleanup();
      // QUAN TRỌNG: Set state = empty list ngay lập tức để UI clear notifications
      state = const AsyncData([]);
      return [];
    }

    final repository = ref.watch(repositoryProvider);
    final notifications = await repository.getNotifications(session.id);

    // Connect SignalR để nhận real-time notifications
    await _connectSignalR(session.id);

    return notifications;
  }

  Future<void> _connectSignalR(String userId) async {
    try {
      // Get token từ storage
      final tokenStorage = ref.read(tokenStorageProvider);
      final token = tokenStorage.token;

      // Connect to SignalR
      await _signalRService.connect(userId, token);

      // Listen for real-time notifications
      _signalRService.addNotificationListener(_handleRealTimeNotification);
    } catch (e) {
      print('Error connecting SignalR: $e');
      // Không throw error để không block UI
    }
  }

  void _handleRealTimeNotification(Map<String, dynamic> notificationData) {
    // Convert notification data to NotificationItem
    final notification = NotificationItem.fromJson(notificationData);
    
    // Update state với notification mới ở đầu list
    state = state.whenData((items) => [notification, ...items]);
  }

  // Cleanup khi provider bị dispose
  void _cleanup() {
    _signalRSubscription?.cancel();
    _signalRService.removeNotificationListener(_handleRealTimeNotification);
    _signalRService.disconnect();
  }

  Future<void> refreshNotifications() async {
    final session = ref.read(authControllerProvider).session;
    if (session == null) {
      state = const AsyncData([]);
      return;
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(repositoryProvider);
      return repository.getNotifications(session.id);
    });
  }

  Future<void> markAsViewed(String id) async {
    final repository = ref.read(repositoryProvider);
    await repository.markNotificationViewed(id);
    state = state.whenData(
      (items) => items
          .map((item) => item.id == id ? item.copyWith(isViewed: true) : item)
          .toList(),
    );
  }

  /// Clear notifications ngay lập tức (dùng khi logout)
  void clearNotifications() {
    _cleanup();
    state = const AsyncData([]);
  }
}

