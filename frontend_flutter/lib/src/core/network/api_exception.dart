import 'package:dio/dio.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.data});

  final String message;
  final int? statusCode;
  final dynamic data;

  @override
  String toString() => 'ApiException($statusCode): $message';

  factory ApiException.fromDio(DioException error) {
    // Xử lý network errors (không có response)
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return ApiException.network(
        'Không thể kết nối đến máy chủ. Vui lòng kiểm tra kết nối mạng và đảm bảo backend đang chạy trên ${error.requestOptions.baseUrl}.',
      );
    }

    // Xử lý errors có response
    final response = error.response;
    final status = response?.statusCode;
    
    // Lấy message từ response
    String? message;
    if (response?.data != null) {
      if (response!.data is Map<String, dynamic>) {
        message = response.data['message']?.toString() ?? 
                 response.data['error']?.toString() ??
                 response.data['Message']?.toString() ??
                 response.data['Error']?.toString();
      } else if (response.data is String) {
        message = response.data as String;
      } else {
        message = response.data.toString();
      }
    }
    
    return ApiException(
      message ?? error.message ?? 'Đã có lỗi xảy ra',
      statusCode: status,
      data: response?.data,
    );
  }

  factory ApiException.network([String? message]) {
    return ApiException(message ?? 'Không thể kết nối đến máy chủ');
  }

  factory ApiException.unauthorized([String? message]) {
    return ApiException(
      message ?? 'Phiên đăng nhập đã hết hạn',
      statusCode: 401,
    );
  }

  factory ApiException.forbidden([String? message]) {
    return ApiException(
      message ?? 'Tài khoản của bạn đã bị khóa hoặc không có quyền truy cập',
      statusCode: 403,
    );
  }

  factory ApiException.serverError([String? message]) {
    return ApiException(
      message ?? 'Lỗi máy chủ, vui lòng thử lại sau',
      statusCode: 500,
    );
  }

  factory ApiException.notFound([String? message]) {
    return ApiException(
      message ?? 'Không tìm thấy tài nguyên',
      statusCode: 404,
    );
  }

  /// Get user-friendly Vietnamese error message
  String get userMessage {
    switch (statusCode) {
      case 401:
        return 'Phiên đăng nhập đã hết hạn, vui lòng đăng nhập lại';
      case 403:
        return 'Tài khoản của bạn đã bị khóa hoặc không có quyền truy cập';
      case 404:
        return 'Không tìm thấy tài nguyên';
      case 500:
        return 'Lỗi máy chủ, vui lòng thử lại sau';
      default:
        return message;
    }
  }
}

