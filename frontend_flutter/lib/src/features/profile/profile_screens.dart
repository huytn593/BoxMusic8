import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/utils/image_utils.dart';
import '../../data/models/models.dart';
import '../../data/repositories/repository.dart';
import '../../widgets/app_page.dart';
import '../../widgets/async_value_widget.dart';
import '../../widgets/track_collection.dart';
import '../auth/controllers/auth_controller.dart';
import '../library/library_screens.dart' show artistTracksProvider;

final myProfileProvider =
    FutureProvider.autoDispose.family<ProfileData, String>((ref, userId) {
  final repository = ref.watch(repositoryProvider);
  return repository.getMyProfile(userId);
});

final profileProvider =
    FutureProvider.autoDispose.family<ProfileData, String>((ref, userId) {
  final repository = ref.watch(repositoryProvider);
  return repository.getProfile(userId);
});

final followingProvider =
    FutureProvider.autoDispose.family<List<FollowUser>, String>((ref, userId) {
  final repository = ref.watch(repositoryProvider);
  return repository.getFollowing(userId);
});

final profileFollowingStatusProvider =
    FutureProvider.autoDispose.family<bool, String>((ref, followingId) async {
  if (followingId.isEmpty) return false;
  final session = ref.watch(authControllerProvider).session;
  if (session == null) return false;
  final repository = ref.watch(repositoryProvider);
  // Backend endpoint chỉ cần followingId, tự lấy followerId từ JWT
  return repository.checkFollowing(session.id, followingId);
});

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key, required this.userId});

  final String userId;

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  DateTime? _dob;
  int _gender = 0;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authControllerProvider).session;
    final userId = widget.userId == 'me' ? session?.id ?? '' : widget.userId;

    if (userId.isEmpty) {
      return const AppPage(
        title: 'Cài đặt tài khoản',
        child: Center(child: Text('Vui lòng đăng nhập để tiếp tục.')),
      );
    }

    final profile = ref.watch(myProfileProvider(userId));
    return AppPage(
      title: 'Cài đặt tài khoản',
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: AsyncValueWidget(
          value: profile,
          data: (data) {
            _nameController.text = data.fullname;
            _dob ??= data.dateOfBirth;
            _gender = data.gender ?? 0;
            return ListView(
              children: [
                _ProfileHeader(
                  profile: data,
                  onChangeAvatar: () async {
                    final picker = ImagePicker();
                    final picked = await picker.pickImage(source: ImageSource.gallery);
                    if (picked == null) return;
                    final repository = ref.read(repositoryProvider);
                    // Backend yêu cầu FullName, Gender, DateOfBirth khi upload avatar
                    final formData = FormData.fromMap({
                      'FullName': data.fullname,
                      'Gender': data.gender ?? 0,
                      'DateOfBirth': (data.dateOfBirth ?? DateTime.now()).toIso8601String(),
                      'Avatar': await MultipartFile.fromFile(
                        picked.path,
                        filename: 'avatar.jpg',
                      ),
                    });
                    await repository.updateProfileAvatar(userId, formData);
                    final refreshed = await repository.getMyProfile(userId);
                    ref.invalidate(myProfileProvider(userId));
                    await ref
                        .read(authControllerProvider.notifier)
                        .updateAvatar(refreshed.avatarBase64);
                  },
                ),
                const SizedBox(height: 24),
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Họ tên'),
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Vui lòng nhập họ tên' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownMenu<int>(
                        label: const Text('Giới tính'),
                        initialSelection: _gender,
                        onSelected: (value) => setState(() => _gender = value ?? 0),
                        dropdownMenuEntries: const [
                          DropdownMenuEntry(value: 0, label: 'Nam'),
                          DropdownMenuEntry(value: 1, label: 'Nữ'),
                          DropdownMenuEntry(value: 2, label: 'Khác'),
                          DropdownMenuEntry(value: 3, label: 'Không tiết lộ'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Ngày sinh'),
                        subtitle: Text(
                          _dob != null
                              ? '${_dob!.day}/${_dob!.month}/${_dob!.year}'
                              : 'Chưa cập nhật',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: () async {
                            final now = DateTime.now();
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _dob ?? DateTime(now.year - 18),
                              firstDate: DateTime(1900),
                              lastDate: now,
                            );
                            if (picked != null) {
                              setState(() => _dob = picked);
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () async {
                          if (!_formKey.currentState!.validate()) return;
                          final repository = ref.read(repositoryProvider);
                          await repository.updateProfile(userId, {
                            'fullname': _nameController.text,
                            'gender': _gender,
                            if (_dob != null) 'dateOfBirth': _dob!.toIso8601String(),
                          });
                          ref.invalidate(myProfileProvider(userId));
                        },
                        child: const Text('Lưu thay đổi'),
                      ),
                      const SizedBox(height: 32),
                      _ContactSection(profile: data, userId: userId),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile, required this.onChangeAvatar});

  final ProfileData profile;
  final VoidCallback onChangeAvatar;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 40,
          backgroundImage: _avatarProvider(profile.avatarBase64),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: profile.fullname,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 20),
                    ),
                    if (profile.role != null && profile.role!.toLowerCase() != 'normal') ...[
                      const WidgetSpan(child: SizedBox(width: 12)),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: _RoleBadge(role: profile.role!),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                profile.email,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Đang theo dõi: ${profile.followCount}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                    ),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: onChangeAvatar,
                child: const Text('Đổi ảnh đại diện'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ContactSection extends ConsumerStatefulWidget {
  const _ContactSection({required this.profile, required this.userId});

  final ProfileData profile;
  final String userId;

  @override
  ConsumerState<_ContactSection> createState() => _ContactSectionState();
}

class _ContactSectionState extends ConsumerState<_ContactSection> {
  late final TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    _addressController = TextEditingController(text: widget.profile.address);
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repository = ref.watch(repositoryProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Liên lạc',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Text(
                widget.profile.email,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Icon(
              widget.profile.isEmailVerified ? Icons.verified : Icons.warning_amber,
              color: widget.profile.isEmailVerified ? Colors.green : Colors.orange,
            ),
            const SizedBox(width: 12),
            TextButton(
              onPressed: () => _startEmailVerification(context),
              child: Text(
                widget.profile.isEmailVerified ? 'Đã xác minh' : 'Xác minh',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _addressController,
          decoration: const InputDecoration(labelText: 'Địa chỉ liên lạc'),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton(
            onPressed: () async {
              await repository.updateAddress(widget.userId, _addressController.text);
              ref.invalidate(myProfileProvider(widget.userId));
            },
            child: const Text('Lưu địa chỉ'),
          ),
        ),
      ],
    );
  }

  Future<void> _startEmailVerification(BuildContext context) async {
    final repository = ref.read(repositoryProvider);
    
    // Hiển thị loading khi gửi OTP
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đang gửi OTP...')),
    );
    
    try {
      await repository.sendVerifyEmailOtp(widget.userId);
      if (!context.mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã gửi OTP đến email của bạn. Vui lòng kiểm tra hộp thư.'),
          backgroundColor: Colors.green,
        ),
      );
      
      final otpController = TextEditingController();
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Xác thực Email'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Nhập mã OTP đã được gửi đến email của bạn.\nMã này có hiệu lực trong 5 phút.',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    labelText: 'Mã OTP (6 chữ số)',
                    hintText: 'Nhập mã OTP',
                    counterText: '',
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    letterSpacing: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                if (otpController.text.length == 6) {
                  Navigator.of(context).pop(true);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vui lòng nhập đủ 6 chữ số')),
                  );
                }
              },
              child: const Text('Xác nhận'),
            ),
          ],
        ),
      );
      
      if (confirmed == true && otpController.text.isNotEmpty) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đang xác thực...')),
        );
        
        await repository.verifyEmailOtp(widget.userId, otpController.text);
        
        if (mounted) {
          ref.invalidate(myProfileProvider(widget.userId));
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Xác thực email thành công!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class PersonalProfileScreen extends ConsumerWidget {
  const PersonalProfileScreen({super.key, required this.profileId});

  final String profileId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider(profileId));
    final session = ref.watch(authControllerProvider).session;
    final isCurrentUser = session?.id == profileId;
    final followingStatus = !isCurrentUser && session != null
        ? ref.watch(profileFollowingStatusProvider(profileId))
        : null;

    return AppPage(
      title: 'Hồ sơ',
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: AsyncValueWidget(
          value: profile,
          data: (data) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: _avatarProvider(data.avatarBase64),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: data.fullname,
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 20),
                              ),
                              if (data.role != null && data.role!.toLowerCase() != 'normal') ...[
                                const WidgetSpan(child: SizedBox(width: 12)),
                                WidgetSpan(
                                  alignment: PlaceholderAlignment.middle,
                                  child: _RoleBadge(role: data.role!),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          data.email,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: Colors.white70),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Đang theo dõi: ${data.followCount}',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.white54),
                        ),
                      ],
                    ),
                  ),
                  if (!isCurrentUser && session != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: _ProfileFollowButton(
                        userId: profileId,
                        session: session,
                        followingStatus: followingStatus!,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Bài hát đã đăng',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: AsyncValueWidget(
                  value: ref.watch(artistTracksProvider(profileId)),
                  data: (tracks) => TrackCollection(
                    tracks: tracks,
                    onDetails: (track) => context.go('/track/${track.id}'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FollowScreen extends ConsumerWidget {
  const FollowScreen({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final following = ref.watch(followingProvider(userId));

    return AppPage(
      title: 'Đang theo dõi',
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: AsyncValueWidget(
          value: following,
          data: (users) => ListView.separated(
            itemCount: users.length,
            separatorBuilder: (_, __) => const Divider(color: Colors.white12),
            itemBuilder: (context, index) {
              final user = users[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundImage: _avatarProvider(user.avatarBase64),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  user.fullname,
                                  style: Theme.of(context).textTheme.titleMedium,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (user.role != null && user.role!.toLowerCase() != 'normal') ...[
                                const SizedBox(width: 8),
                                _RoleBadge(role: user.role!),
                              ],
                            ],
                          ),
                          if (user.username != null)
                            Text(
                              '@${user.username}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.white54,
                                  ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _ProfileFollowButton(
                      userId: user.id,
                      session: ref.watch(authControllerProvider).session!,
                      followingStatus: const AsyncValue.data(true), // List này là list đang follow nên status luôn là true
                      onFollowChanged: () => ref.invalidate(followingProvider(userId)),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

ImageProvider<Object> _avatarProvider(String? data) {
  return buildAvatarProvider(data);
}

class _ProfileFollowButton extends ConsumerStatefulWidget {
  const _ProfileFollowButton({
    required this.userId,
    required this.session,
    required this.followingStatus,
    this.onFollowChanged,
  });

  final String userId;
  final UserSession session;
  final AsyncValue<bool> followingStatus;
  final VoidCallback? onFollowChanged;

  @override
  ConsumerState<_ProfileFollowButton> createState() => _ProfileFollowButtonState();
}

class _ProfileFollowButtonState extends ConsumerState<_ProfileFollowButton> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return AsyncValueWidget(
      value: widget.followingStatus,
      data: (isFollowing) => ElevatedButton(
        onPressed: _isProcessing ? null : () => _handleFollow(isFollowing),
        child: _isProcessing
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(isFollowing ? 'Đang theo dõi' : 'Theo dõi'),
      ),
      loading: ElevatedButton(
        onPressed: null,
        child: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (error, stack) => ElevatedButton(
        onPressed: _isProcessing ? null : () => _handleFollow(false),
        child: const Text('Theo dõi'),
      ),
    );
  }

  Future<void> _handleFollow(bool isFollowing) async {
    if (_isProcessing) return;
    
    setState(() => _isProcessing = true);
    
    try {
      final repository = ref.read(repositoryProvider);
      if (isFollowing) {
        await repository.unfollowUser(widget.userId);
      } else {
        await repository.followUser(widget.userId);
      }
      
      // Refresh following status
      ref.invalidate(profileFollowingStatusProvider(widget.userId));
      
      // Refresh profile để cập nhật followCount
      ref.invalidate(profileProvider(widget.userId));
      
      widget.onFollowChanged?.call();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isFollowing ? 'Đã bỏ theo dõi' : 'Đã theo dõi'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }
}

/// Badge hiển thị role (VIP, Premium, Admin)
class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    // Trim và loại bỏ khoảng trắng thừa, chỉ lấy từ đầu tiên
    final roleTrimmed = role.trim().split(' ').first.toLowerCase();
    Color backgroundColor;
    Color textColor;
    String icon;
    String text;

    switch (roleTrimmed) {
      case 'vip':
        backgroundColor = Colors.orange.shade700.withValues(alpha: 0.9); // Dùng orange thay vì amber để không chói
        textColor = Colors.black; // Màu đen cho chữ VIP
        icon = '👑';
        text = 'VIP';
        break;
      case 'premium':
        backgroundColor = Colors.purple.shade800.withValues(alpha: 0.8); // Tăng alpha để nổi bật hơn
        textColor = Colors.purple.shade100; // Màu sáng hơn cho text
        icon = '💎';
        text = 'Premium';
        break;
      case 'admin':
        backgroundColor = Colors.red.shade800.withValues(alpha: 0.8); // Tăng alpha để nổi bật hơn
        textColor = Colors.red.shade100; // Màu sáng hơn cho text
        icon = '⚔️';
        text = 'Admin';
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withValues(alpha: 0.5), width: 1.5), // Tăng độ đậm border
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            icon,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

