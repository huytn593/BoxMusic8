import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../config/app_config.dart';

Uint8List? tryDecodeBase64Image(String? data) {
  if (data == null || data.isEmpty) return null;
  try {
    final encoded = data.contains(',')
        ? data.substring(data.indexOf(',') + 1)
        : data;
    return base64Decode(encoded);
  } catch (_) {
    return null;
  }
}

/// Helper function để xử lý avatar URL (có thể là URL hoặc base64)
/// Trả về ImageProvider phù hợp
ImageProvider<Object> buildAvatarProvider(String? data) {
  if (data == null || data.isEmpty) {
    return const AssetImage('assets/images/default-avatar.png');
  }

  // Kiểm tra nếu là URL (http:// hoặc https://)
  if (data.startsWith('http://') || data.startsWith('https://')) {
    String imageUrl = data;
    final baseUrl = AppConfig.apiBaseUrl.replaceAll('/api', '');
    if (imageUrl.contains('localhost:') || imageUrl.contains('127.0.0.1:')) {
      final uri = Uri.parse(imageUrl);
      final path = uri.path;
      imageUrl = '$baseUrl$path';
    }
    return NetworkImage(imageUrl);
  }

  // Kiểm tra nếu là relative path (bắt đầu bằng /)
  if (data.startsWith('/')) {
    final baseUrl = AppConfig.apiBaseUrl.replaceAll('/api', '');
    final imageUrl = '$baseUrl$data';
    return NetworkImage(imageUrl);
  }

  // Thử decode base64
  final bytes = tryDecodeBase64Image(data);
  if (bytes != null) {
    return MemoryImage(bytes);
  }

  // Fallback về default avatar
  return const AssetImage('assets/images/default-avatar.png');
}

