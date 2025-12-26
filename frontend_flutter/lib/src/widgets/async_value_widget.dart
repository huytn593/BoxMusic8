import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AsyncValueWidget<T> extends ConsumerWidget {
  const AsyncValueWidget({
    super.key,
    required this.value,
    required this.data,
    this.loading,
    this.error,
    this.onRefresh,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final Widget? loading;
  final Widget Function(Object error, StackTrace stack)? error;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return value.when(
      data: data,
      loading: () =>
          loading ??
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
      error: (err, stack) {
        // Hiển thị user-friendly message cho ApiException
        String errorMessage = 'Đã xảy ra lỗi';
        if (err.toString().contains('ApiException')) {
          if (err.toString().contains('401')) {
            errorMessage = 'Phiên đăng nhập đã hết hạn, vui lòng đăng nhập lại';
          } else if (err.toString().contains('403')) {
            errorMessage = 'Tài khoản của bạn đã bị khóa hoặc không có quyền truy cập';
          } else if (err.toString().contains('Không thể kết nối')) {
            errorMessage = 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra:\n'
                '1. Backend đang chạy\n'
                '2. IP và Port đúng trong config\n'
                '3. Device và máy tính cùng mạng WiFi';
          } else {
            errorMessage = err.toString().replaceAll('ApiException', '').trim();
          }
        } else {
          errorMessage = err.toString();
        }
        
        return error?.call(err, stack) ??
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    errorMessage,
                    style: const TextStyle(color: Colors.redAccent),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  if (onRefresh != null)
                    TextButton.icon(
                      onPressed: onRefresh,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Thử lại'),
                    ),
                ],
              ),
            );
      },
    );
  }
}

