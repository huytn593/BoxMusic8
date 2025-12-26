import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import '../config/app_config.dart';
import '../storage/token_storage.dart';
import 'api_exception.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);
  return ApiClient(tokenStorage);
});

class ApiClient {
  ApiClient(this._tokenStorage) {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        // Tăng timeout cho real device (network có thể chậm hơn)
        connectTimeout: const Duration(seconds: 60), // Tăng từ 30 lên 60
        receiveTimeout: const Duration(seconds: 60), // Tăng từ 30 lên 60
        sendTimeout: const Duration(seconds: 120), // Upload có thể mất thời gian
        responseType: ResponseType.json,
        headers: const {
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Đọc token mới nhất từ storage mỗi lần request
          // Đảm bảo không dùng token cũ sau khi logout
          final token = _tokenStorage.token;
          if (token != null && token.isNotEmpty) {
            options.headers.putIfAbsent('Authorization', () => 'Bearer $token');
          } else {
            // Nếu không có token, xóa Authorization header (nếu có)
            options.headers.remove('Authorization');
          }
          return handler.next(options);
        },
        onError: (error, handler) {
          if (error.type == DioExceptionType.connectionError ||
              error.type == DioExceptionType.connectionTimeout ||
              error.type == DioExceptionType.receiveTimeout) {
            handler.reject(
              DioException(
                requestOptions: error.requestOptions,
                error: ApiException.network(),
              ),
            );
            return;
          }

          final statusCode = error.response?.statusCode;
          
          if (statusCode == 401) {
            handler.reject(
              DioException(
                requestOptions: error.requestOptions,
                response: error.response,
                error: ApiException.unauthorized(),
              ),
            );
            return;
          }

          if (statusCode == 403) {
            handler.reject(
              DioException(
                requestOptions: error.requestOptions,
                response: error.response,
                error: ApiException.forbidden(),
              ),
            );
            return;
          }

          handler.next(error);
        },
      ),
    );

    if (kDebugMode) {
      _dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseHeader: true, // Bật để debug
          responseBody: true,
          maxWidth: 200, // Tăng để xem đầy đủ
          error: true, // Hiển thị lỗi
        ),
      );
    }
  }

  late final Dio _dio;
  final TokenStorage _tokenStorage;

  Dio get dio => _dio;

  /// Clear Authorization header từ tất cả pending requests
  /// Dùng khi logout để đảm bảo không có request nào dùng token cũ
  /// Lưu ý: Không đóng Dio instance vì ApiClient sẽ được tạo lại tự động
  /// khi tokenStorageProvider thay đổi (do ref.watch)
  void clearAuthorizationHeaders() {
    // Không cần làm gì vì:
    // 1. Token đã được xóa khỏi storage
    // 2. Interceptor đọc token từ storage mỗi lần request
    // 3. Khi token null, interceptor sẽ không thêm Authorization header
    // 4. Các request đang pending sẽ fail với 401 hoặc không có token
    // 
    // Nếu muốn cancel requests, có thể dùng _dio.close(force: true)
    // nhưng điều này sẽ đóng Dio instance và không thể dùng lại
    // Vì ApiClient được tạo lại mỗi khi tokenStorageProvider thay đổi,
    // nên không cần cancel requests thủ công
  }
}

