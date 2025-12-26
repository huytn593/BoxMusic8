import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final tokenStorageProvider = Provider<TokenStorage>(
  (ref) => throw UnimplementedError('tokenStorageProvider must be overridden'),
);

class TokenStorage {
  TokenStorage(this._prefs);

  static const _tokenKey = 'token';
  static const _avatarKey = 'avatarBase64';

  final SharedPreferences _prefs;

  static Future<TokenStorage> create() async {
    final prefs = await SharedPreferences.getInstance();
    return TokenStorage(prefs);
  }

  String? get token => _prefs.getString(_tokenKey);

  String? get avatarBase64 => _prefs.getString(_avatarKey);

  Future<void> saveSession(String token, {String? avatar}) async {
    await _prefs.setString(_tokenKey, token);
    if (avatar != null) {
      await _prefs.setString(_avatarKey, avatar);
    }
  }

  Future<void> saveAvatar(String? avatar) async {
    if (avatar == null) {
      await _prefs.remove(_avatarKey);
    } else {
      await _prefs.setString(_avatarKey, avatar);
    }
  }

  Future<void> clear() async {
    // Xóa token và avatar, đảm bảo hoàn thành trước khi return
    final removedToken = await _prefs.remove(_tokenKey);
    final removedAvatar = await _prefs.remove(_avatarKey);
    
    // Đảm bảo changes được commit ngay lập tức
    // reload() để đảm bảo state được sync
    await _prefs.reload();
    
    // Verify token đã được xóa
    final verifyToken = _prefs.getString(_tokenKey);
    if (verifyToken != null) {
      // Nếu vẫn còn token, thử xóa lại
      await _prefs.remove(_tokenKey);
      await _prefs.reload();
    }
  }
}

