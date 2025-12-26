import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/network/api_exception.dart';
import '../../data/repositories/repository.dart';
import '../../music_player/music_player_controller.dart';
import '../../widgets/app_page.dart';
import 'controllers/auth_controller.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _hasStoppedPlayer = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Dừng music player khi vào trang đăng nhập (chỉ chạy 1 lần)
    if (!_hasStoppedPlayer) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_hasStoppedPlayer) {
          _hasStoppedPlayer = true;
          final musicPlayerController = ref.read(musicPlayerControllerProvider.notifier);
          musicPlayerController.reset();
        }
      });
    }

    return AppPage(
      title: 'Đăng nhập',
      // Hiển thị bottomNavigationBar để người dùng có thể quay lại trang công khai
      showPrimaryNav: true,
      // Vẫn ẩn thanh nhạc ở màn auth để tránh gây nhiễu khi đăng nhập
      showMusicBar: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    Text(
                      'Chào mừng trở lại',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(labelText: 'Tên đăng nhập'),
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Vui lòng nhập tên đăng nhập' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(labelText: 'Mật khẩu'),
                      obscureText: true,
                      validator: (value) =>
                          value == null || value.length < 8 ? 'Mật khẩu tối thiểu 8 ký tự' : null,
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => context.go('/forgot-password'),
                        child: const Text('Quên mật khẩu?'),
                      ),
                    ),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _handleSubmit,
                        child: _loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Đăng nhập'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Chưa có tài khoản?'),
                        TextButton(
                          onPressed: () => context.go('/signup'),
                          child: const Text('Đăng ký ngay'),
                        ),
                      ],
                    ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authControllerProvider.notifier).login(
            username: _usernameController.text,
            password: _passwordController.text,
          );
      // Không cần context.go('/'); router sẽ tự redirect khi isAuthenticated
    } catch (error) {
      final message = _mapLoginError(error);
      setState(() => _error = message);
      _passwordController.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.redAccent,
          ),
        );
      await _showErrorDialog(context, message);
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  String _mapLoginError(dynamic error) {
    String message = 'Đăng nhập thất bại, vui lòng thử lại.';
    if (error is ApiException) {
      switch (error.statusCode) {
        case 401:
          message = 'Sai tên đăng nhập hoặc mật khẩu';
          break;
        case 403:
          message = 'Tài khoản của bạn đã bị khóa';
          break;
        case 500:
          message = 'Lỗi máy chủ, vui lòng thử lại sau';
          break;
        default:
          message = error.message;
      }
    } else if (error is SocketException ||
        error.toString().contains('SocketException')) {
      message = 'Không thể kết nối đến máy chủ';
    } else if (error.toString().contains('ApiException')) {
      final match =
          RegExp(r'ApiException\([^)]*\): (.+)').firstMatch(error.toString());
      if (match != null) {
        message = match.group(1) ?? message;
      }
    }
    return message;
  }

  Future<void> _showErrorDialog(BuildContext context, String message) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng nhập thất bại'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }
}

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _fullname = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _phone = TextEditingController();
  DateTime? _dob;
  int _gender = 0;
  bool _loading = false;
  String? _message;
  bool _hasStoppedPlayer = false;

  @override
  void dispose() {
    _username.dispose();
    _fullname.dispose();
    _email.dispose();
    _password.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Dừng music player khi vào trang đăng ký (chỉ chạy 1 lần)
    if (!_hasStoppedPlayer) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_hasStoppedPlayer) {
          _hasStoppedPlayer = true;
          final musicPlayerController = ref.read(musicPlayerControllerProvider.notifier);
          musicPlayerController.reset();
        }
      });
    }
    return AppPage(
      title: 'Đăng ký',
      // Hiển thị bottomNavigationBar cho trang đăng ký
      showMusicBar: false,
      showPrimaryNav: true,
      child: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Tạo tài khoản BoxMusic',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _username,
                        decoration: const InputDecoration(labelText: 'Tên đăng nhập'),
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Bắt buộc' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _fullname,
                        decoration: const InputDecoration(labelText: 'Họ tên'),
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Bắt buộc' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _email,
                        decoration: const InputDecoration(labelText: 'Email'),
                        validator: (value) =>
                            value == null || !value.contains('@') ? 'Email không hợp lệ' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _phone,
                        decoration: const InputDecoration(labelText: 'Số điện thoại'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _password,
                        decoration: const InputDecoration(labelText: 'Mật khẩu'),
                        obscureText: true,
                        validator: (value) =>
                            value == null || value.length < 8 ? 'Ít nhất 8 ký tự' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownMenu<int>(
                        label: const Text('Giới tính'),
                        initialSelection: _gender,
                        onSelected: (value) => setState(() => _gender = value ?? 0),
                        dropdownMenuEntries: const [
                          DropdownMenuEntry(value: 0, label: 'Nam'),
                          DropdownMenuEntry(value: 1, label: 'Nữ'),
                          DropdownMenuEntry(value: 2, label: 'Khác'),
                          DropdownMenuEntry(value: 3, label: 'Không muốn trả lời'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Ngày sinh'),
                        subtitle: Text(
                          _dob != null
                              ? DateFormat('dd/MM/yyyy').format(_dob!)
                              : 'Chưa chọn',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.calendar_month),
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
                      const SizedBox(height: 12),
                      if (_message != null)
                        Text(
                          _message!,
                          style: const TextStyle(color: Colors.lightGreenAccent),
                        ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _loading ? null : () => _submit(ref),
                          child: _loading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Đăng ký'),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
    );
  }

  Future<void> _submit(WidgetRef ref) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _message = null;
    });
    try {
      final repository = ref.read(repositoryProvider);
      await repository.register({
        'username': _username.text,
        'fullname': _fullname.text,
        'email': _email.text,
        'password': _password.text,
        'phoneNumber': _phone.text,
        'gender': _gender,
        'dateOfBirth': (_dob ?? DateTime.now()).toIso8601String(),
      });
      // Hiển thị dialog thành công với countdown
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const _RegistrationSuccessDialog(),
        );
      }
    } catch (error) {
      String message = 'Đăng ký thất bại, vui lòng thử lại.';
      if (error is ApiException) {
        message = error.message;
      } else if (error is SocketException ||
          error.toString().contains('SocketException')) {
        message = 'Không thể kết nối đến máy chủ';
      } else if (error.toString().contains('ApiException')) {
        final match =
            RegExp(r'ApiException\([^)]*\): (.+)').firstMatch(error.toString());
        if (match != null) {
          message = match.group(1) ?? message;
        }
      }
      setState(() {
        _message = message;
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }
}

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _submitting = false;
  String? _message;

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Quên mật khẩu',
      showMusicBar: false,
      showPrimaryNav: false,
      child: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                    Text(
                      'Nhập email để nhận OTP đặt lại mật khẩu',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator: (value) =>
                          value == null || !value.contains('@') ? 'Email không hợp lệ' : null,
                    ),
                    const SizedBox(height: 12),
                    if (_message != null)
                      Text(
                        _message!,
                        style: const TextStyle(color: Colors.lightGreenAccent),
                      ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitting ? null : () => _sendOtp(ref),
                        child: _submitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Gửi OTP'),
                      ),
                    ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _sendOtp(WidgetRef ref) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _message = null;
    });
    try {
      await ref.read(repositoryProvider).sendOtp(_emailController.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP đã được gửi đến email của bạn.'),
          backgroundColor: Colors.green,
        ),
      );
      context.go('/verify-otp?email=${Uri.encodeComponent(_emailController.text)}');
    } catch (error) {
      setState(() {
        _message = error.toString();
      });
    } finally {
      setState(() {
        _submitting = false;
      });
    }
  }
}

class VerifyOtpScreen extends ConsumerStatefulWidget {
  const VerifyOtpScreen({super.key, required this.email});

  final String? email;

  @override
  ConsumerState<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends ConsumerState<VerifyOtpScreen> {
  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _loading = false;
  String? _message;
  int _countdown = 0;

  @override
  void initState() {
    super.initState();
    if (_countdown > 0) {
      _startCountdown();
    }
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startCountdown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _countdown > 0) {
        setState(() {
          _countdown--;
        });
        _startCountdown();
      }
    });
  }

  void _handleOtpChange(String value, int index) {
    if (value.length > 1) {
      // Handle paste
      final pastedData = value.replaceAll(RegExp(r'[^0-9]'), '').substring(0, value.length > 6 ? 6 : value.length);
      for (int i = 0; i < pastedData.length && (index + i) < 6; i++) {
        _otpControllers[index + i].text = pastedData[i];
        if (index + i < 5) {
          _focusNodes[index + i + 1].requestFocus();
        }
      }
      if (pastedData.length == 6) {
        _verifyOtp();
      }
      return;
    }

    if (value.isEmpty) {
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
    } else if (value.length == 1 && RegExp(r'[0-9]').hasMatch(value)) {
      _otpControllers[index].text = value;
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        _verifyOtp();
      }
    } else {
      _otpControllers[index].text = '';
    }
  }

  String _getOtp() {
    return _otpControllers.map((c) => c.text).join();
  }

  Future<void> _verifyOtp() async {
    if (widget.email == null) return;
    final otp = _getOtp();
    if (otp.length != 6) return;

    setState(() {
      _loading = true;
      _message = null;
    });

    try {
      await ref.read(repositoryProvider).verifyOtp(
            email: widget.email!,
            otp: otp,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Xác thực OTP thành công!'),
          backgroundColor: Colors.green,
        ),
      );
      context.go('/reset-password?email=${Uri.encodeComponent(widget.email!)}&otp=$otp');
    } catch (error) {
      setState(() {
        // Lấy message từ ApiException hoặc error message
        String errorMessage = 'OTP không hợp lệ hoặc đã hết hạn. Vui lòng thử lại.';
        if (error is ApiException) {
          errorMessage = error.message;
        } else if (error.toString().contains('ApiException')) {
          // Parse message từ toString nếu không thể cast
          final match = RegExp(r'ApiException\([^)]*\): (.+)').firstMatch(error.toString());
          if (match != null) {
            errorMessage = match.group(1) ?? errorMessage;
          }
        }
        _message = errorMessage;
        // Clear OTP fields on error
        for (var controller in _otpControllers) {
          controller.clear();
        }
        _focusNodes[0].requestFocus();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _resendOtp() async {
    if (_countdown > 0 || widget.email == null) return;

    setState(() {
      _loading = true;
      _countdown = 60;
    });
    _startCountdown();

    try {
      await ref.read(repositoryProvider).sendOtp(widget.email!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP mới đã được gửi.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      setState(() {
        _message = error.toString();
        _countdown = 0;
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Xác thực OTP',
      showMusicBar: false,
      showPrimaryNav: true,
      child: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Nhập mã OTP',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.email ?? 'Không có email',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                          ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Mã OTP đã được gửi đến email của bạn.\nMã này có hiệu lực trong 5 phút.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.white70),
                    ),
                    const SizedBox(height: 24),
                    // OTP Input Fields
                    LayoutBuilder(
                      builder: (context, constraints) {
                        // Tính toán kích thước động dựa trên màn hình
                        final availableWidth = constraints.maxWidth;
                        final spacing = 8.0;
                        final totalSpacing = spacing * 5; // 5 khoảng cách giữa 6 ô
                        final itemWidth = ((availableWidth - totalSpacing) / 6).clamp(40.0, 50.0);
                        final itemHeight = itemWidth * 1.2;
                        final fontSize = (itemWidth * 0.45).clamp(18.0, 22.0);
                        
                        return Wrap(
                          alignment: WrapAlignment.center,
                          spacing: spacing,
                          children: List.generate(6, (index) {
                            return SizedBox(
                              width: itemWidth,
                              height: itemHeight,
                              child: TextField(
                                controller: _otpControllers[index],
                                focusNode: _focusNodes[index],
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.number,
                                maxLength: 1,
                                style: TextStyle(
                                  fontSize: fontSize,
                                  fontWeight: FontWeight.bold,
                                ),
                                decoration: InputDecoration(
                                  counterText: '',
                                  contentPadding: EdgeInsets.zero, // Loại bỏ padding mặc định
                                  isDense: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: Colors.grey.shade600),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Colors.blue, width: 2),
                                  ),
                                ),
                                onChanged: (value) => _handleOtpChange(value, index),
                                onTap: () {
                                  _otpControllers[index].selection = TextSelection.fromPosition(
                                    TextPosition(offset: _otpControllers[index].text.length),
                                  );
                                },
                              ),
                            );
                          }),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    if (_message != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          _message!,
                          style: const TextStyle(color: Colors.redAccent),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _verifyOtp,
                        child: _loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Xác thực OTP'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: (_countdown > 0 || _loading) ? null : _resendOtp,
                      child: Text(
                        _countdown > 0
                            ? 'Gửi lại OTP (${_countdown}s)'
                            : 'Gửi lại OTP',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key, required this.email, required this.otp});

  final String? email;
  final String? otp;

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  String? _message;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.email == null || widget.otp == null) return;

    setState(() {
      _loading = true;
      _message = null;
    });

    try {
      await ref.read(repositoryProvider).resetPassword(
            email: widget.email!,
            otp: widget.otp!,
            newPassword: _passwordController.text,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đặt lại mật khẩu thành công!'),
          backgroundColor: Colors.green,
        ),
      );
      context.go('/signin');
    } catch (error) {
      setState(() {
        // Lấy message từ ApiException hoặc error message
        String errorMessage = 'Đặt lại mật khẩu thất bại. Vui lòng thử lại.';
        if (error is ApiException) {
          errorMessage = error.message;
        } else if (error.toString().contains('ApiException')) {
          // Parse message từ toString nếu không thể cast
          final match = RegExp(r'ApiException\([^)]*\): (.+)').firstMatch(error.toString());
          if (match != null) {
            errorMessage = match.group(1) ?? errorMessage;
          }
        }
        _message = errorMessage;
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Đặt lại mật khẩu',
      showMusicBar: false,
      showPrimaryNav: true,
      child: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Đặt lại mật khẩu mới',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.email ?? 'Không có email',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white70,
                            ),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Mật khẩu mới',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        obscureText: _obscurePassword,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập mật khẩu mới';
                          }
                          if (value.length < 8) {
                            return 'Mật khẩu phải có ít nhất 8 ký tự';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _confirmPasswordController,
                        decoration: InputDecoration(
                          labelText: 'Xác nhận mật khẩu',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword = !_obscureConfirmPassword;
                              });
                            },
                          ),
                        ),
                        obscureText: _obscureConfirmPassword,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng xác nhận mật khẩu';
                          }
                          if (value != _passwordController.text) {
                            return 'Mật khẩu không khớp';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      if (_message != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            _message!,
                            style: const TextStyle(color: Colors.redAccent),
                          ),
                        ),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _resetPassword,
                          child: _loading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Đặt lại mật khẩu'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RegistrationSuccessDialog extends StatefulWidget {
  const _RegistrationSuccessDialog({super.key});

  @override
  State<_RegistrationSuccessDialog> createState() => _RegistrationSuccessDialogState();
}

class _RegistrationSuccessDialogState extends State<_RegistrationSuccessDialog> {
  int _countdown = 5;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 1) {
        setState(() {
          _countdown--;
        });
      } else {
        _timer?.cancel();
        _goToLogin();
      }
    });
  }

  void _goToLogin() {
    if (mounted) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context); // Close dialog first if open
      }
      context.go('/signin');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Column(
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 64),
          SizedBox(height: 16),
          Text('Đăng ký thành công!'),
        ],
      ),
      content: Text(
        'Tự động chuyển về trang đăng nhập sau $_countdown giây...',
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 16),
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _goToLogin,
            child: const Text('Đăng nhập ngay'),
          ),
        ),
      ],
      actionsAlignment: MainAxisAlignment.center,
    );
  }
}

