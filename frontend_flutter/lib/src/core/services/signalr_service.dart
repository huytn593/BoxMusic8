import 'dart:async';
import 'package:signalr_netcore/signalr_client.dart';
import '../config/app_config.dart';

/// SignalR Service để quản lý real-time connections
class SignalRService {
  static final SignalRService _instance = SignalRService._internal();
  factory SignalRService() => _instance;
  SignalRService._internal();

  HubConnection? _connection;
  String? _currentUserId;
  final List<Function(Map<String, dynamic>)> _notificationListeners = [];

  /// Get SignalR hub URL
  String _getHubUrl() {
    // SignalR client tự động convert http/https thành ws/wss
    // Nên chỉ cần dùng http/https URL
    final uri = Uri.parse(AppConfig.apiBaseUrl);
    return '${uri.scheme}://${uri.host}:${uri.port}/notificationHub';
  }

  /// Connect to SignalR hub
  Future<void> connect(String userId, String? token) async {
    if (_connection != null && _connection?.state == HubConnectionState.Connected) {
      if (_currentUserId == userId) {
        return; // Đã connect rồi
      }
      await disconnect();
    }

    _currentUserId = userId;

    final hubUrl = _getHubUrl();
    final options = HttpConnectionOptions(
      accessTokenFactory: () async => token ?? '',
    );

    _connection = HubConnectionBuilder()
        .withUrl(hubUrl, options: options)
        .withAutomaticReconnect()
        .build();

    // Listen for notifications
    _connection?.on('ReceiveNotification', (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        final notification = arguments[0] as Map<String, dynamic>;
        for (final listener in _notificationListeners) {
          listener(notification);
        }
      }
    });

    // Handle connection events - onclose có thể không có hoặc signature khác
    // Bỏ qua onclose callback nếu không cần thiết

    try {
      await _connection?.start();
      print('SignalR connected successfully');
      
      // Join user group
      await _connection?.invoke('JoinUserGroup', args: <Object>[userId]);
      print('Joined user group: user_$userId');
    } catch (e) {
      print('Error connecting to SignalR: $e');
      rethrow;
    }
  }

  /// Disconnect from SignalR hub
  Future<void> disconnect() async {
    if (_connection != null) {
      final userIdToLeave = _currentUserId;
      if (userIdToLeave != null) {
        try {
          await _connection?.invoke('LeaveUserGroup', args: <Object>[userIdToLeave]);
        } catch (e) {
          print('Error leaving user group: $e');
        }
      }
      
      await _connection?.stop();
      _connection = null;
      _currentUserId = null;
      print('SignalR disconnected');
    }
  }

  /// Add notification listener
  void addNotificationListener(Function(Map<String, dynamic>) listener) {
    _notificationListeners.add(listener);
  }

  /// Remove notification listener
  void removeNotificationListener(Function(Map<String, dynamic>) listener) {
    _notificationListeners.remove(listener);
  }

  /// Check if connected
  bool get isConnected => 
      _connection != null && _connection?.state == HubConnectionState.Connected;

  /// Get connection state
  HubConnectionState? get connectionState => _connection?.state;
}

