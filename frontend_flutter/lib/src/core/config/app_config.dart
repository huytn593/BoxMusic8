import 'config_service.dart';

/// App Config - Quản lý cấu hình ứng dụng
/// 
/// Base URL được load từ ConfigService (hỗ trợ per-developer config)
class AppConfig {
  /// Get API base URL (dynamic, loaded from ConfigService)
  static String get apiBaseUrl => ConfigService.buildApiBaseUrl();

  /// Get Swagger URL
  static String get swaggerUrl => ConfigService.getSwaggerUrl();

  /// Asset paths
  static const heroBackground = 'assets/images/background.jpg';
  static const defaultTrackImage = 'assets/images/default-music.jpg';
  static const defaultAvatar = 'assets/images/default-avatar.png';

  /// Build URI với path và query parameters
  static Uri buildUri(
    String path, [
    Map<String, dynamic>? queryParameters,
  ]) {
    final uri = Uri.parse('$apiBaseUrl$path');
    if (queryParameters == null || queryParameters.isEmpty) {
      return uri;
    }
    return uri.replace(
      queryParameters: queryParameters.map(
        (key, value) => MapEntry(key, value?.toString()),
      ),
    );
  }

  /// Build WebSocket URL (for SignalR)
  static String buildSignalRUrl() {
    final uri = Uri.parse(apiBaseUrl);
    final wsScheme = uri.scheme == 'https' ? 'wss' : 'ws';
    return '$wsScheme://${uri.host}:${uri.port}/notificationHub';
  }
}

