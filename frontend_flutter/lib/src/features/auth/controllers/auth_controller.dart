import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

import '../../../core/services/signalr_service.dart';
import '../../../core/storage/token_storage.dart';
import '../../../data/repositories/repository.dart';

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  final repository = ref.watch(repositoryProvider);
  final storage = ref.watch(tokenStorageProvider);
  return AuthController(repository, storage);
});

class AuthState {
  const AuthState({
    required this.initialized,
    required this.loading,
    this.session,
    this.errorMessage,
    this.sessionExpired = false,
  });

  factory AuthState.initial() => const AuthState(
        initialized: false,
        loading: false,
      );

  final bool initialized;
  final bool loading;
  final UserSession? session;
  final String? errorMessage;
  final bool sessionExpired; // Flag để đánh dấu session đã hết hạn

  bool get isAuthenticated => session != null;

  AuthState copyWith({
    bool? initialized,
    bool? loading,
    UserSession? session,
    String? errorMessage,
    bool? sessionExpired,
    // Thêm flag để force clear session (không dùng null để giữ session cũ)
    bool clearSession = false,
  }) {
    return AuthState(
      initialized: initialized ?? this.initialized,
      loading: loading ?? this.loading,
      // QUAN TRỌNG: 
      // - Nếu clearSession = true, set session = null (không dùng ?? để giữ session cũ)
      // - Nếu session được truyền vào (không null), dùng giá trị đó
      // - Nếu không truyền và clearSession = false, giữ session cũ
      session: clearSession ? null : (session ?? this.session),
      errorMessage: errorMessage,
      sessionExpired: sessionExpired ?? this.sessionExpired,
    );
  }
}

class UserSession {
  UserSession({
    required this.id,
    required this.fullname,
    required this.role,
    required this.token,
    this.avatarBase64,
  });

  final String id;
  final String fullname;
  final String role;
  final String token;
  final String? avatarBase64;

  bool get isAdmin => role.toLowerCase() == 'admin';
  bool get isArtist => role.toLowerCase() == 'artist';
  bool get isVip => role.toLowerCase() == 'vip';
  bool get isPremium => role.toLowerCase() == 'premium';
  bool get isNormal => role.toLowerCase() == 'normal';
  
  /// Kiểm tra user có quyền nghe VIP tracks không
  bool get canAccessVipTracks => isAdmin || isVip || isPremium;
  
  /// Lấy display name của role
  String get roleDisplayName {
    final roleLower = role.toLowerCase();
    switch (roleLower) {
      case 'admin':
        return 'Admin';
      case 'vip':
        return 'VIP';
      case 'premium':
        return 'Premium';
      case 'normal':
        return 'Normal';
      default:
        return role;
    }
  }
  
  /// Lấy icon emoji cho role
  String get roleIcon {
    final roleLower = role.toLowerCase();
    switch (roleLower) {
      case 'admin':
        return '⚔️';
      case 'vip':
        return '👑';
      case 'premium':
        return '💎';
      default:
        return '';
    }
  }
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._repository, this._storage)
      : super(AuthState.initial()) {
    _loadSession();
  }

  final Repository _repository;
  final TokenStorage _storage;

  Future<void> _loadSession() async {
    final token = _storage.token;
    if (token != null && token.isNotEmpty) {
      final session = _buildSessionFromToken(
        token,
        avatarBase64: _storage.avatarBase64,
      );
      state = state.copyWith(
        initialized: true,
        session: session,
        sessionExpired: false, // Reset flag khi initialize với token hợp lệ
      );
    } else {
      state = state.copyWith(
        initialized: true,
        sessionExpired: false, // Reset flag khi initialize không có token
      );
    }
  }

  UserSession? _buildSessionFromToken(
    String token, {
    String? avatarBase64,
  }) {
    try {
      final decoded = JwtDecoder.decode(token);
      final id = decoded['sub']?.toString();
      final role = decoded['role']?.toString() ?? 'user';
      final fullname = decoded['fullname']?.toString() ?? 'BoxMusic User';
      if (id == null) return null;
      return UserSession(
        id: id,
        fullname: fullname,
        role: role,
        token: token,
        avatarBase64: avatarBase64,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> login({
    required String username,
    required String password,
  }) async {
    state = state.copyWith(loading: true, errorMessage: null);
    try {
      final response = await _repository.login(
        username: username,
        password: password,
      );
      await _storage.saveSession(
        response.token,
        avatar: response.avatarBase64,
      );
      final session = _buildSessionFromToken(
        response.token,
        avatarBase64: response.avatarBase64,
      );
      state = state.copyWith(
        loading: false,
        session: session,
        initialized: true,
        sessionExpired: false, // Reset flag khi login thành công
      );
    } catch (error) {
      state = state.copyWith(
        loading: false,
        errorMessage: error.toString(),
      );
      rethrow;
    }
  }

  Future<void> logout() async {
    state = state.copyWith(loading: true);
    try {
      await _repository.logout();
    } catch (_) {
      // ignore logout failures - vẫn clear session
    } finally {
      // Disconnect SignalR trước khi clear storage
      await SignalRService().disconnect();
      
      // Clear storage trước (token, avatar) - ĐẢM BẢO HOÀN THÀNH
      await _storage.clear();
      
      // Verify token đã được xóa
      final verifyToken = _storage.token;
      if (verifyToken != null && verifyToken.isNotEmpty) {
        // Nếu vẫn còn token, force clear lại
        await _storage.clear();
      }
      
      // Update state ngay lập tức để trigger router refresh
      // Set session = null để đảm bảo UI refresh về trạng thái chưa đăng nhập
      state = state.copyWith(
        loading: false,
        clearSession: true, // QUAN TRỌNG: Force clear session (không giữ session cũ)
        initialized: true, // Đảm bảo initialized = true để router có thể redirect
        errorMessage: null, // Clear error message
        sessionExpired: false, // Reset flag khi logout thủ công
      );
      
      // StateNotifier tự động notify listeners khi state thay đổi
      // Router sẽ rebuild và redirect về /signin
    }
  }

  /// Chỉ gọi API logout (không clear state/storage)
  /// Dùng khi muốn gọi API trước khi clear state
  Future<void> logoutApiOnly() async {
    try {
      await _repository.logout();
    } catch (_) {
      // Ignore logout API errors - không quan trọng
    }
  }

  /// Chỉ clear storage và state (không gọi API)
  /// Dùng sau khi đã gọi logoutApiOnly()
  /// Set sessionExpired = true để router tự động redirect về /signin
  Future<void> clearStorageAndState() async {
    // Disconnect SignalR trước khi clear storage
    await SignalRService().disconnect();
    
    // Clear storage
    await _storage.clear();
    
    // Verify token đã được xóa
    final verifyToken = _storage.token;
    if (verifyToken != null && verifyToken.isNotEmpty) {
      // Nếu vẫn còn token, force clear lại
      await _storage.clear();
    }
    
    // Update state
    // QUAN TRỌNG: 
    // - Set session = null để UI rebuild và ẩn dropdown
    //   + UI watch authControllerProvider → sẽ rebuild khi state thay đổi
    //   + Khi session = null, _UserAvatarMenu sẽ hiển thị nút đăng nhập/đăng ký
    // - Set sessionExpired = true để router tự động redirect về /signin
    //   + Router logic: !auth.isAuthenticated && auth.sessionExpired → redirect về /signin
    //   + Router watch authControllerProvider → sẽ rebuild khi state thay đổi
    // - Dùng clearSession = true để đảm bảo session được clear (không giữ session cũ)
    state = state.copyWith(
      loading: false,
      clearSession: true, // QUAN TRỌNG: Force clear session (không giữ session cũ)
      initialized: true,
      errorMessage: null,
      sessionExpired: false, // Logout thủ công -> quay về trang chủ
    );
  }

  /// Clear state ngay lập tức (không gọi API, không clear storage)
  /// Dùng khi logout để router có thể redirect ngay
  /// Storage sẽ được clear sau đó trong logout()
  void clearStateImmediately() {
    state = state.copyWith(
      clearSession: true, // QUAN TRỌNG: Force clear session (không giữ session cũ)
      initialized: true, // Đảm bảo initialized = true để router có thể redirect
      errorMessage: null,
      sessionExpired: false,
    );
  }

  /// Clear session only (không gọi API) - dùng khi session hết hạn (401)
  /// Public method để có thể gọi từ repository khi phát hiện 401
  Future<void> clearSessionOnly() async {
    // Disconnect SignalR trước khi clear storage
    await SignalRService().disconnect();
    
    // Clear storage và đảm bảo hoàn thành
    await _storage.clear();
    
    // Verify token đã được xóa
    final verifyToken = _storage.token;
    if (verifyToken != null && verifyToken.isNotEmpty) {
      // Nếu vẫn còn token, force clear lại
      await _storage.clear();
    }
    
    // Set sessionExpired = true để router biết cần redirect về /signin
    state = state.copyWith(
      clearSession: true, // QUAN TRỌNG: Force clear session (không giữ session cũ)
      initialized: true, // Đảm bảo initialized = true để router có thể redirect
      sessionExpired: true, // Đánh dấu session đã hết hạn
    );
  }

  Future<void> updateAvatar(String? avatarBase64) async {
    await _storage.saveAvatar(avatarBase64);
    final current = state.session;
    if (current != null) {
      state = state.copyWith(
        session: UserSession(
          id: current.id,
          fullname: current.fullname,
          role: current.role,
          token: current.token,
          avatarBase64: avatarBase64,
        ),
      );
    }
  }

  /// Reload session từ token hiện tại (dùng sau khi thanh toán để lấy role mới)
  /// Gọi API getMyProfile để lấy role mới từ database (vì token không tự động cập nhật)
  Future<void> reloadSession() async {
    final token = _storage.token;
    if (token != null && token.isNotEmpty) {
      try {
        // Decode token để lấy userId
        final decoded = JwtDecoder.decode(token);
        final id = decoded['sub']?.toString();
        if (id != null) {
          // Gọi API getMyProfile để lấy role mới từ database
          final profile = await _repository.getMyProfile(id);
          
          // Cập nhật session với role mới từ database
          final session = UserSession(
            id: id,
            fullname: decoded['fullname']?.toString() ?? profile.fullname,
            role: profile.role ?? decoded['role']?.toString() ?? 'normal',
            token: token, // Giữ nguyên token (backend sẽ check role từ DB khi cần)
            avatarBase64: profile.avatarBase64 ?? _storage.avatarBase64,
          );
          
          state = state.copyWith(
            session: session,
            initialized: true,
          );
        }
      } catch (error) {
        // Nếu lỗi, vẫn decode token như cũ
        final session = _buildSessionFromToken(
          token,
          avatarBase64: _storage.avatarBase64,
        );
        if (session != null) {
          state = state.copyWith(
            session: session,
            initialized: true,
          );
        }
      }
    }
  }
}

