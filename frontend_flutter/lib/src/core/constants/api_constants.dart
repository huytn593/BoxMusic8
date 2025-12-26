/// API Constants - Tất cả endpoints và WebSocket connections
/// 
/// LƯU Ý: Base URL được load từ AppConfig, không hardcode ở đây
class ApiConstants {
  // Auth endpoints
  static const String login = '/api/Auth/login';
  static const String register = '/api/Auth/register';
  static const String logout = '/api/Auth/logout';
  static const String sendOtp = '/api/Auth/send-otp';
  static const String verifyOtp = '/api/Auth/verify-otp';
  static const String resetPassword = '/api/Auth/reset-password';

  // Track endpoints
  static const String trackUpload = '/api/Track/upload';
  static String trackById(String id) => '/api/Track/$id';
  static const String topPlayed = '/api/Track/top-played';
  static const String topLike = '/api/Track/top-like';
  static String trackAudio(String id) => '/api/Track/audio/$id';
  static String trackInfo(String id) => '/api/Track/track-info/$id';
  static String playCount(String id) => '/api/Track/play-count/$id';
  static String trackDetail(String id) => '/api/Track/track-detail/$id';
  static const String allTrack = '/api/Track/all-track';
  static String approveTrack(String id) => '/api/Track/approve/$id';
  static String publicTrack(String id) => '/api/Track/public/$id';
  static String deleteTrack(String trackId) => '/api/Track/delete/$trackId';
  static String recommendTrack(String userId) => '/api/Track/recommend-track/$userId';

  // Comment endpoints
  static String comments(String trackId) => '/api/Comment/comments/$trackId';
  static const String addComment = '/api/Comment/comments';
  static String deleteComment(String commentId) => '/api/Comment/delete-comment/$commentId';

  // Favorites endpoints
  static String toggleFavorite(String trackId) => '/api/Favorites/toggle/$trackId';
  static const String myFavorites = '/api/Favorites/my-tracks';
  static String checkFavorite(String trackId) => '/api/Favorites/check/$trackId';
  static const String deleteAllFavorites = '/api/Favorites/delete-all';

  // Followers endpoints
  static String follow(String userId) => '/api/Followers/follow/$userId';
  static String unfollow(String userId) => '/api/Followers/unfollow/$userId';
  static String checkFollowing(String userId) => '/api/Followers/check/$userId';
  static String following(String followerId) => '/api/Followers/following/$followerId';
  static String followingList(String followerId) => '/api/Followers/FollowingList/$followerId';

  // History endpoints
  static String userHistory(String userId) => '/api/History/user/$userId';
  static const String playHistory = '/api/History/play';
  static String deleteHistory(String trackId) => '/api/History/delete/$trackId';
  static const String deleteAllHistory = '/api/History/delete-all';

  // Notification endpoints
  static String myNotification(String id) => '/api/Notification/my-notification/$id';
  static String markNotificationViewed(String id) => '/api/Notification/mark-viewed/$id';

  // PaymentRecord endpoints
  static const String revenueByTime = '/api/PaymentRecord/by-time';
  static const String revenueByTier = '/api/PaymentRecord/by-tier';

  // Playlist endpoints
  static String userPlaylists(String userId) => '/api/Playlist/user/$userId';
  static String playlistById(String playlistId) => '/api/Playlist/$playlistId';
  static String updatePlaylist(String playlistId) => '/api/Playlist/$playlistId';
  static String deletePlaylist(String playlistId) => '/api/Playlist/$playlistId';
  static const String createPlaylist = '/api/Playlist';
  static String addTrackToPlaylist(String playlistId) => '/api/Playlist/$playlistId/tracks';
  static String removeTrackFromPlaylist(String playlistId, String trackId) => '/api/Playlist/$playlistId/tracks/$trackId';
  static String playlistLimits(String userId) => '/api/Playlist/limits/$userId';

  // Profile endpoints
  static String myProfile(String userID) => '/api/Profile/my-profile/$userID';
  static String profile(String userID) => '/api/Profile/profile/$userID';
  static String updatePersonal(String userID) => '/api/Profile/personal/$userID';
  static String updatePersonalAvatar(String userID) => '/api/Profile/personal-avt/$userID';
  static String changePassword(String userId) => '/api/Profile/change-password/$userId';
  static String myTracks(String profileId) => '/api/Profile/my-tracks/$profileId';
  static String updateAddress(String userId) => '/api/Profile/address/$userId';
  static String sendVerifyEmailOtp(String userId) => '/api/Profile/send-verify-email-otp/$userId';
  static String verifyEmailOtp(String userId) => '/api/Profile/verify-email-otp/$userId';

  // Search endpoints
  static const String search = '/api/search'; // Backend SearchController, route is /api/search

  // VnPay endpoints
  static const String vnPayCreate = '/api/VnPay/create';
  static const String vnPayReturn = '/api/VnPay/return';

  // Storage paths (backend storage locations)
  static const String storageAvatar = 'backend/storage/avatar';
  static const String storageCoverImages = 'backend/storage/cover_images';
  static const String storagePlaylistCover = 'backend/storage/playlist_cover';
  static const String storageTracks = 'backend/storage/tracks';
}

/// WebSocket constants (nếu có sử dụng WebSocket)
class WebSocketConstants {
  // WebSocket base URL sẽ được load từ AppConfig
  // Ví dụ: ws://172.20.10.2:5270/websocket
  static String buildWebSocketUrl(String baseUrl) {
    final uri = Uri.parse(baseUrl);
    final wsScheme = uri.scheme == 'https' ? 'wss' : 'ws';
    return '$wsScheme://${uri.host}:${uri.port}/websocket';
  }
}

