import 'package:equatable/equatable.dart';

class AuthLoginResponse extends Equatable {
  const AuthLoginResponse({required this.token, this.avatarBase64});

  final String token;
  final String? avatarBase64;

  factory AuthLoginResponse.fromJson(Map<String, dynamic> json) {
    return AuthLoginResponse(
      token: json['token']?.toString() ?? '',
      avatarBase64: json['avatarBase64']?.toString(),
    );
  }

  @override
  List<Object?> get props => [token, avatarBase64];
}

class TrackSummary extends Equatable {
  const TrackSummary({
    required this.id,
    required this.title,
    this.artistName,
    this.imageBase64,
    this.isPublic = true,
    this.playCount,
    this.likeCount,
    this.isApproved,
    this.isDeleted,
    this.genres = const [],
    this.audioUrl,
    this.lastPlay, // Cho history tracks
  });

  final String id;
  final String title;
  final String? artistName;
  final String? imageBase64;
  final bool isPublic;
  final int? playCount;
  final int? likeCount;
  final bool? isApproved;
  final bool? isDeleted;
  final List<String> genres;
  final String? audioUrl;
  final DateTime? lastPlay; // Thời gian nghe gần nhất (cho history)

  factory TrackSummary.fromJson(Map<String, dynamic> json) {
    final id = json['id'] ??
        json['trackId'] ??
        json['_id'] ??
        json['songId'] ??
        json['Id'];
    return TrackSummary(
      id: id?.toString() ?? '',
      title: json['title']?.toString() ?? json['name']?.toString() ?? 'Bài hát',
      artistName: json['artistName']?.toString() ??
          json['uploaderName']?.toString() ??
          json['artist']?.toString(),
      imageBase64: json['imageBase64']?.toString() ??
          json['imageUrl']?.toString() ??
          json['cover']?.toString() ??
          json['coverImage']?.toString(),
      isPublic: json['isPublic'] is bool
          ? json['isPublic'] as bool
          : json['isPublic']?.toString().toLowerCase() != 'false',
      playCount: json['playCount'] is int
          ? json['playCount'] as int
          : int.tryParse(json['playCount']?.toString() ?? ''),
      likeCount: json['likeCount'] is int
          ? json['likeCount'] as int
          : int.tryParse(json['likeCount']?.toString() ?? ''),
      isApproved: json['isApproved'] as bool?,
      isDeleted: json['isDeleted'] as bool?,
      genres: (json['genres'] as List?)
              ?.map((e) => e.toString())
              .toList(growable: false) ??
          const [],
      audioUrl: json['audioUrl']?.toString(),
      lastPlay: json['lastPlay'] != null
          ? DateTime.tryParse(json['lastPlay'].toString())
          : null,
    );
  }

  TrackSummary copyWith({
    String? id,
    String? title,
    String? artistName,
    String? imageBase64,
    bool? isPublic,
    int? playCount,
    int? likeCount,
    bool? isApproved,
    bool? isDeleted,
    List<String>? genres,
    String? audioUrl,
    DateTime? lastPlay,
  }) {
    return TrackSummary(
      id: id ?? this.id,
      title: title ?? this.title,
      artistName: artistName ?? this.artistName,
      imageBase64: imageBase64 ?? this.imageBase64,
      isPublic: isPublic ?? this.isPublic,
      playCount: playCount ?? this.playCount,
      likeCount: likeCount ?? this.likeCount,
      isApproved: isApproved ?? this.isApproved,
      isDeleted: isDeleted ?? this.isDeleted,
      genres: genres ?? this.genres,
      audioUrl: audioUrl ?? this.audioUrl,
      lastPlay: lastPlay ?? this.lastPlay,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        artistName,
        imageBase64,
        isPublic,
        playCount,
        likeCount,
        isApproved,
        genres,
        audioUrl,
        lastPlay,
      ];
}

class TrackDetailData extends Equatable {
  const TrackDetailData({
    required this.track,
    required this.description,
    required this.lastUpdate,
  });

  final TrackSummary track;
  final DateTime? lastUpdate;
  final String? description;

  factory TrackDetailData.fromJson(Map<String, dynamic> json) {
    return TrackDetailData(
      track: TrackSummary.fromJson(json),
      description: json['description']?.toString(),
      lastUpdate: json['lastUpdate'] != null
          ? DateTime.tryParse(json['lastUpdate'].toString())
          : null,
    );
  }

  @override
  List<Object?> get props => [track, lastUpdate, description];
}

class PlaylistSummary extends Equatable {
  const PlaylistSummary({
    required this.id,
    required this.name,
    this.description,
    this.trackCount = 0,
    this.coverBase64,
  });

  final String id;
  final String name;
  final String? description;
  final int trackCount;
  final String? coverBase64;

  factory PlaylistSummary.fromJson(Map<String, dynamic> json) {
    final id = json['id'] ?? json['playlistId'] ?? json['_id'];
    return PlaylistSummary(
      id: id?.toString() ?? '',
      name: json['name']?.toString() ?? 'Playlist',
      description: json['description']?.toString(),
      trackCount: json['trackCount'] is int
          ? json['trackCount'] as int
          : int.tryParse(json['trackCount']?.toString() ?? '') ?? 0,
      coverBase64: json['imageBase64']?.toString() ?? 
                   json['ImageBase64']?.toString() ??
                   json['coverImage']?.toString() ?? 
                   json['cover']?.toString(),
    );
  }

  @override
  List<Object?> get props => [id, name, description, trackCount, coverBase64];
}

class PlaylistDetail extends Equatable {
  const PlaylistDetail({
    required this.playlist,
    required this.tracks,
    this.userId,
  });

  final PlaylistSummary playlist;
  final List<TrackSummary> tracks;
  final String? userId;

  factory PlaylistDetail.fromJson(Map<String, dynamic> json) {
    final playlist = PlaylistSummary.fromJson(json);
    // Backend trả về PlaylistTrackDto với TrackId (PascalCase), cần map sang TrackSummary
    final tracks = (json['tracks'] as List?)
            ?.map((e) {
              final trackData = e as Map<String, dynamic>;
              final trackId = trackData['trackId'] ?? 
                  trackData['TrackId'] ?? 
                  trackData['id'] ?? 
                  trackData['Id'];
              return TrackSummary.fromJson({
                'id': trackId?.toString(),
                'title': trackData['title'] ?? trackData['Title'] ?? '',
                'artistName': trackData['artistName'] ?? 
                    trackData['ArtistName'] ?? 
                    'BoxMusic',
                'imageBase64': trackData['imageBase64'] ?? 
                    trackData['ImageBase64'],
                'isPublic': trackData['isPublic'] ?? 
                    trackData['IsPublic'] ?? 
                    true,
              });
            })
            .toList(growable: false) ??
        const <TrackSummary>[];
    return PlaylistDetail(
      playlist: playlist,
      tracks: tracks,
      userId: json['userId']?.toString() ?? json['UserId']?.toString(),
    );
  }

  @override
  List<Object?> get props => [playlist, tracks, userId];
}

class ProfileData extends Equatable {
  const ProfileData({
    required this.id,
    required this.fullname,
    required this.email,
    this.phoneNumber,
    this.avatarBase64,
    this.role,
    this.gender,
    this.dateOfBirth,
    this.address,
    this.isVip = false,
    this.expiredDate,
    this.isEmailVerified = false,
    this.followCount = 0,
  });

  final String id;
  final String fullname;
  final String email;
  final String? phoneNumber;
  final String? avatarBase64;
  final String? role;
  final int? gender;
  final DateTime? dateOfBirth;
  final String? address;
  final bool isVip;
  final DateTime? expiredDate;
  final bool isEmailVerified;
  final int followCount;

  factory ProfileData.fromJson(Map<String, dynamic> json) {
    final id = json['id'] ?? json['userId'] ?? json['_id'];
    return ProfileData(
      id: id?.toString() ?? '',
      fullname: json['fullname']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString(),
      avatarBase64: json['avatarBase64']?.toString(),
      role: json['role']?.toString()?.trim().split(' ').first,
      gender: json['gender'] as int?,
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.tryParse(json['dateOfBirth'].toString())
          : null,
      address: json['address']?.toString(),
      isVip: json['isVip'] as bool? ?? false,
      expiredDate: json['expiredDate'] != null
          ? DateTime.tryParse(json['expiredDate'].toString())
          : null,
      isEmailVerified: json['isEmailVerified'] as bool? ?? false,
      followCount: json['followCount'] as int? ?? 
          json['FollowCount'] as int? ?? 0,
    );
  }

  ProfileData copyWith({
    String? fullname,
    String? phoneNumber,
    String? avatarBase64,
    int? gender,
    DateTime? dateOfBirth,
    String? address,
    bool? isVip,
    DateTime? expiredDate,
    bool? isEmailVerified,
    int? followCount,
  }) {
    return ProfileData(
      id: id,
      fullname: fullname ?? this.fullname,
      email: email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      avatarBase64: avatarBase64 ?? this.avatarBase64,
      role: role,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      address: address ?? this.address,
      isVip: isVip ?? this.isVip,
      expiredDate: expiredDate ?? this.expiredDate,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      followCount: followCount ?? this.followCount,
    );
  }

  @override
  List<Object?> get props => [
        id,
        fullname,
        email,
        phoneNumber,
        avatarBase64,
        role,
        gender,
        dateOfBirth,
        address,
        isVip,
        expiredDate,
        isEmailVerified,
        followCount,
      ];
}

class NotificationItem extends Equatable {
  const NotificationItem({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    this.isViewed = false,
  });

  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final bool isViewed;

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    final id = json['id'] ?? json['_id'] ?? json['notificationId'];
    return NotificationItem(
      id: id?.toString() ?? '',
      title: json['title']?.toString() ??
          json['subject']?.toString() ??
          'Thông báo',
      content: json['content']?.toString() ??
          json['message']?.toString() ??
          '',
      createdAt: DateTime.tryParse(
            json['createdAt']?.toString() ??
                json['createAt']?.toString() ??
                '',
          ) ??
          DateTime.now(),
      isViewed: json['isViewed'] as bool? ?? false,
    );
  }

  NotificationItem copyWith({
    bool? isViewed,
  }) {
    return NotificationItem(
      id: id,
      title: title,
      content: content,
      createdAt: createdAt,
      isViewed: isViewed ?? this.isViewed,
    );
  }

  @override
  List<Object?> get props => [id, title, content, createdAt, isViewed];
}

class CommentItem extends Equatable {
  const CommentItem({
    required this.id,
    required this.content,
    required this.authorName,
    required this.createdAt,
    this.avatarBase64,
    this.userId,
  });

  final String id;
  final String content;
  final String authorName;
  final DateTime createdAt;
  final String? avatarBase64;
  final String? userId; // Để check quyền xóa comment

  factory CommentItem.fromJson(Map<String, dynamic> json) {
    // Backend trả về CommentDetail với PascalCase: CommentId, UserName, Contents, CreateAt, ImageBase64, UserId
    // React frontend dùng camelCase: commentId, userName, contents, createAt, imageBase64, userId
    final id = json['id'] ?? 
        json['_id'] ?? 
        json['commentId'] ?? 
        json['CommentId'];
    return CommentItem(
      id: id?.toString() ?? '',
      content: json['content']?.toString() ?? 
          json['Contents']?.toString() ?? 
          json['contents']?.toString() ?? 
          '',
      authorName: json['userName']?.toString() ?? 
          json['UserName']?.toString() ?? 
          json['fullname']?.toString() ??
          json['username']?.toString() ??
          'Người dùng',
      createdAt: DateTime.tryParse(
            json['createdAt']?.toString() ?? 
            json['CreateAt']?.toString() ?? 
            json['createAt']?.toString() ?? 
            '',
          ) ??
          DateTime.now(),
      avatarBase64: json['avatarBase64']?.toString() ?? 
          json['ImageBase64']?.toString() ??
          json['imageBase64']?.toString(),
      userId: json['userId']?.toString() ?? 
          json['UserId']?.toString(),
    );
  }

  @override
  List<Object?> get props => [id, content, authorName, createdAt, avatarBase64, userId];
}

class PaymentRecord extends Equatable {
  const PaymentRecord({
    required this.id,
    required this.userId,
    required this.orderId,
    required this.amount,
    required this.paymentTime,
    required this.tier,
  });

  final String id;
  final String userId;
  final String orderId;
  final double amount;
  final DateTime paymentTime;
  final String tier;

  factory PaymentRecord.fromJson(Map<String, dynamic> json) {
    return PaymentRecord(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      orderId: json['orderId']?.toString() ?? '',
      amount: json['amount'] is num
          ? (json['amount'] as num).toDouble()
          : double.tryParse(json['amount']?.toString() ?? '') ?? 0,
      paymentTime: json['paymentTime'] != null
          ? DateTime.parse(json['paymentTime'].toString())
          : DateTime.now(),
      tier: json['tier']?.toString() ?? '',
    );
  }

  @override
  List<Object?> get props => [id, userId, orderId, amount, paymentTime, tier];
}

class RevenuePoint extends Equatable {
  const RevenuePoint({required this.label, required this.amount});

  final String label;
  final double amount;

  @override
  List<Object?> get props => [label, amount];
}

class FollowUser extends Equatable {
  const FollowUser({
    required this.id,
    required this.fullname,
    this.avatarBase64,
    this.username,
    this.role,
  });

  final String id;
  final String fullname;
  final String? avatarBase64;
  final String? username;
  final String? role;

  factory FollowUser.fromJson(Map<String, dynamic> json) {
    final id = json['id'] ?? 
        json['userId'] ?? 
        json['_id'] ?? 
        json['followingId'];
    return FollowUser(
      id: id?.toString() ?? '',
      fullname: json['fullname']?.toString() ??
          json['name']?.toString() ??
          json['followingName']?.toString() ??
          'Người dùng',
      avatarBase64: json['avatarBase64']?.toString() ?? 
          json['followingAvatar']?.toString(),
      username: json['username']?.toString(),
      role: json['role']?.toString() ?? json['followingRole']?.toString(),
    );
  }

  @override
  List<Object?> get props => [id, fullname, avatarBase64, username, role];
}

class SearchResults extends Equatable {
  const SearchResults({
    required this.tracks,
    required this.users,
  });

  final List<TrackSummary> tracks;
  final List<FollowUser> users;

  factory SearchResults.fromJson(Map<String, dynamic> json) {
    return SearchResults(
      tracks: (json['tracks'] as List?)
              ?.map((e) => TrackSummary.fromJson(e as Map<String, dynamic>))
              .toList(growable: false) ??
          const [],
      users: (json['users'] as List?)
              ?.map((e) => FollowUser.fromJson(e as Map<String, dynamic>))
              .toList(growable: false) ??
          const [],
    );
  }

  @override
  List<Object?> get props => [tracks, users];
}

class PlaylistLimits extends Equatable {
  const PlaylistLimits({
    required this.userRole,
    required this.currentPlaylists,
    required this.maxPlaylists,
    required this.maxTracksPerPlaylist,
  });

  final String userRole;
  final int currentPlaylists;
  final int maxPlaylists;
  final int maxTracksPerPlaylist;

  factory PlaylistLimits.fromJson(Map<String, dynamic> json) {
    return PlaylistLimits(
      userRole: json['userRole']?.toString() ?? 'normal',
      currentPlaylists: json['currentPlaylists'] is num
          ? (json['currentPlaylists'] as num).toInt()
          : int.tryParse(json['currentPlaylists']?.toString() ?? '') ?? 0,
      maxPlaylists: json['maxPlaylists'] is num
          ? (json['maxPlaylists'] as num).toInt()
          : int.tryParse(json['maxPlaylists']?.toString() ?? '') ?? 0,
      maxTracksPerPlaylist: json['maxTracksPerPlaylist'] is num
          ? (json['maxTracksPerPlaylist'] as num).toInt()
          : int.tryParse(json['maxTracksPerPlaylist']?.toString() ?? '') ?? 0,
    );
  }

  bool get isUnlimited => maxPlaylists >= 2147483647;
  bool get canCreateMore => isUnlimited || currentPlaylists < maxPlaylists;
  bool get isTracksUnlimited => maxTracksPerPlaylist >= 2147483647;

  @override
  List<Object?> get props => [userRole, currentPlaylists, maxPlaylists, maxTracksPerPlaylist];
}

class UploadTrackPayload {
  UploadTrackPayload({
    required this.title,
    required this.filePath,
    this.album,
    this.genres = const [],
    this.artistId,
    this.coverBase64,
    this.isPublic = true, // Mặc định là nhạc thường (public)
  });

  final String title;
  final String filePath;
  final String? album;
  final List<String> genres;
  final String? artistId;
  final String? coverBase64;
  final bool isPublic; // true = nhạc thường, false = VIP
}

