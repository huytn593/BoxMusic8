import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Config Service - Quản lý config cho mỗi developer
/// 
/// Mỗi developer sẽ có file config.dev.json riêng (không commit vào git)
/// App sẽ đọc config từ SharedPreferences hoặc environment variables
class ConfigService {
  static const String _keyApiHost = 'config_api_host';
  static const String _keyApiPort = 'config_api_port';
  static const String _keySwaggerUrl = 'config_swagger_url';
  static const String _keyUseEmulator = 'config_use_emulator';
  static const String _keyEmulatorHost = 'config_emulator_host';

  // Default values
  static const String _defaultApiHost = '172.20.10.2';
  static const String _defaultApiPort = '5270';
  static const String _defaultSwaggerUrl = 'http://172.20.10.2:5270/swagger/index.html';
  static const bool _defaultUseEmulator = false;
  static const String _defaultEmulatorHost = '10.0.2.2';

  static SharedPreferences? _prefs;

  /// Initialize config service
  static Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Get API host
  static String getApiHost() {
    if (kDebugMode) {
      // Trong debug mode, ưu tiên đọc từ environment variable
      const envHost = String.fromEnvironment('API_HOST');
      if (envHost.isNotEmpty) {
        return envHost;
      }
    }
    return _prefs?.getString(_keyApiHost) ?? _defaultApiHost;
  }

  /// Get API port
  static String getApiPort() {
    if (kDebugMode) {
      const envPort = String.fromEnvironment('API_PORT');
      if (envPort.isNotEmpty) {
        return envPort;
      }
    }
    return _prefs?.getString(_keyApiPort) ?? _defaultApiPort;
  }

  /// Get Swagger URL
  static String getSwaggerUrl() {
    return _prefs?.getString(_keySwaggerUrl) ?? _defaultSwaggerUrl;
  }

  /// Check if using emulator
  /// Chỉ đọc từ environment variable hoặc SharedPreferences (không auto-detect)
  static bool getUseEmulator() {
    // Ưu tiên đọc từ environment variable (compile-time)
    if (kDebugMode) {
      const envUseEmulator = String.fromEnvironment('USE_EMULATOR');
      if (envUseEmulator.isNotEmpty) {
        return envUseEmulator.toLowerCase() == 'true';
      }
    }

    // Đọc từ SharedPreferences (runtime config)
    final prefsValue = _prefs?.getBool(_keyUseEmulator);
    if (prefsValue != null) {
      return prefsValue;
    }
    
    return _defaultUseEmulator;
  }

  /// Get emulator host
  static String getEmulatorHost() {
    return _prefs?.getString(_keyEmulatorHost) ?? _defaultEmulatorHost;
  }

  /// Build API base URL
  /// Logic đơn giản:
  /// - Nếu USE_EMULATOR=true: dùng 10.0.2.2 (emulator host)
  /// - Nếu USE_EMULATOR=false: dùng API_HOST (mặc định localhost cho device thật)
  /// - Port luôn dùng API_PORT (mặc định 5270)
  static String buildApiBaseUrl() {
    final useEmulator = getUseEmulator();
    final String host;
    
    if (useEmulator) {
      // Emulator: dùng 10.0.2.2 để truy cập localhost của máy host
      host = getEmulatorHost();
    } else {
      // Device thật: dùng API_HOST (mặc định localhost)
      // User có thể set API_HOST=192.168.x.x nếu cần dùng LAN IP
      host = getApiHost();
    }
    
    final port = getApiPort();
    return 'http://$host:$port';
  }

  /// Set API host
  static Future<void> setApiHost(String host) async {
    await _prefs?.setString(_keyApiHost, host);
  }

  /// Set API port
  static Future<void> setApiPort(String port) async {
    await _prefs?.setString(_keyApiPort, port);
  }

  /// Set Swagger URL
  static Future<void> setSwaggerUrl(String url) async {
    await _prefs?.setString(_keySwaggerUrl, url);
  }

  /// Set use emulator
  static Future<void> setUseEmulator(bool use) async {
    await _prefs?.setBool(_keyUseEmulator, use);
  }

  /// Set emulator host
  static Future<void> setEmulatorHost(String host) async {
    await _prefs?.setString(_keyEmulatorHost, host);
  }

  /// Load config from JSON (for initial setup)
  /// Developer có thể copy config.dev.json.example và load vào đây
  static Future<void> loadFromJson(Map<String, dynamic> json) async {
    await initialize();
    if (json.containsKey('API_HOST')) {
      await setApiHost(json['API_HOST'] as String);
    }
    if (json.containsKey('API_PORT')) {
      await setApiPort(json['API_PORT'] as String);
    }
    if (json.containsKey('SWAGGER_URL')) {
      await setSwaggerUrl(json['SWAGGER_URL'] as String);
    }
    if (json.containsKey('USE_EMULATOR')) {
      await setUseEmulator(json['USE_EMULATOR'] as bool);
    }
    if (json.containsKey('EMULATOR_HOST')) {
      await setEmulatorHost(json['EMULATOR_HOST'] as String);
    }
  }

  /// Reset to defaults
  static Future<void> resetToDefaults() async {
    await initialize();
    await _prefs?.remove(_keyApiHost);
    await _prefs?.remove(_keyApiPort);
    await _prefs?.remove(_keySwaggerUrl);
    await _prefs?.remove(_keyUseEmulator);
    await _prefs?.remove(_keyEmulatorHost);
  }
}

