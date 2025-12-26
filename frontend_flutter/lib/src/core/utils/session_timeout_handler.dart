import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/controllers/auth_controller.dart';
import '../network/api_exception.dart';

/// Session Timeout Handler
/// 
/// Xử lý khi session hết hạn (401/403) - tương tự useLoginSessionOut trong React
class SessionTimeoutHandler {
  SessionTimeoutHandler(this.ref);

  final Ref ref;

  /// Handle session timeout - logout và redirect to login
  Future<void> handleSessionTimeout({
    String? message,
    bool showToast = true,
  }) async {
    // Logout user
    final authController = ref.read(authControllerProvider.notifier);
    await authController.logout();

    // TODO: Show toast message nếu cần
    // if (showToast) {
    //   Fluttertoast.showToast(
    //     msg: message ?? 'Phiên đăng nhập đã hết hạn, vui lòng đăng nhập lại',
    //     toastLength: Toast.LENGTH_LONG,
    //   );
    // }

    // Navigate to login - cần context, sẽ handle ở UI layer
    // Hoặc sử dụng GoRouter để navigate
  }

  /// Check if error is session timeout
  bool isSessionTimeout(dynamic error) {
    if (error is ApiException) {
      return error.statusCode == 401 || error.statusCode == 403;
    }
    return false;
  }
}

/// Provider cho SessionTimeoutHandler
final sessionTimeoutHandlerProvider = Provider<SessionTimeoutHandler>((ref) {
  return SessionTimeoutHandler(ref);
});

