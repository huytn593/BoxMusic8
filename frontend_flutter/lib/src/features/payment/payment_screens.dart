import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/repositories/repository.dart';
import '../../widgets/app_page.dart';
import '../auth/controllers/auth_controller.dart';

class UpgradeAccountScreen extends ConsumerWidget {
  const UpgradeAccountScreen({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authControllerProvider).session;
    final resolvedId = userId == 'me' ? session?.id ?? '' : userId;

    return AppPage(
      title: 'Nâng cấp tài khoản',
      child: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: resolvedId.isEmpty
            ? const Center(child: Text('Vui lòng đăng nhập để nâng cấp.'))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      '✨ Chọn gói nâng cấp phù hợp ✨',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Responsive layout: Column trên màn hình nhỏ, Row trên màn hình lớn
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 600) {
                        // Màn hình nhỏ: hiển thị dọc
                        return Column(
                          children: [
                            _PlanCard(
                              title: 'VIP',
                              price: '99.000₫ / tháng',
                              icon: Icons.workspace_premium,
                              iconColor: Colors.amber,
                              benefits: const [
                                'Truy cập không giới hạn',
                                'Giới hạn 10 playlists',
                                'Nội dung độc quyền',
                              ],
                              benefitDetails: const [
                                'Nghe nhạc và khám phá mà không giới hạn số lượt hay thời gian sử dụng.',
                                'Tạo tối đa 10 playlists để sắp xếp nhạc yêu thích của bạn.',
                                'Truy cập các bài hát VIP và nội dung đặc biệt chỉ dành cho thành viên VIP.',
                              ],
                              onPressed: () => _requestPayment(ref, context, resolvedId, 'VIP'),
                              highlight: false,
                            ),
                            const SizedBox(height: 16),
                            _PlanCard(
                              title: 'Premium',
                              price: '199.000₫ / tháng',
                              icon: Icons.star,
                              iconColor: Colors.purple,
                              benefits: const [
                                'Truy cập không giới hạn',
                                'Không giới hạn playlist',
                                'Nội dung độc quyền',
                              ],
                              benefitDetails: const [
                                'Nghe nhạc và khám phá mà không giới hạn số lượt hay thời gian sử dụng.',
                                'Tạo không giới hạn số lượng playlists để sắp xếp nhạc yêu thích của bạn.',
                                'Truy cập các bài hát Premium và nội dung đặc biệt chỉ dành cho thành viên Premium.',
                              ],
                              onPressed: () => _requestPayment(ref, context, resolvedId, 'Premium'),
                              highlight: true,
                            ),
                          ],
                        );
                      }
                      // Màn hình lớn: hiển thị ngang
                      return Row(
                        children: [
                          Expanded(
                            child: _PlanCard(
                              title: 'VIP',
                              price: '99.000₫ / tháng',
                              icon: Icons.workspace_premium,
                              iconColor: Colors.amber,
                              benefits: const [
                                'Truy cập không giới hạn',
                                'Giới hạn 10 playlists',
                                'Nội dung độc quyền',
                              ],
                              benefitDetails: const [
                                'Nghe nhạc và khám phá mà không giới hạn số lượt hay thời gian sử dụng.',
                                'Tạo tối đa 10 playlists để sắp xếp nhạc yêu thích của bạn.',
                                'Truy cập các bài hát VIP và nội dung đặc biệt chỉ dành cho thành viên VIP.',
                              ],
                              onPressed: () => _requestPayment(ref, context, resolvedId, 'VIP'),
                              highlight: false,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _PlanCard(
                              title: 'Premium',
                              price: '199.000₫ / tháng',
                              icon: Icons.star,
                              iconColor: Colors.purple,
                              benefits: const [
                                'Truy cập không giới hạn',
                                'Không giới hạn playlist',
                                'Nội dung độc quyền',
                              ],
                              benefitDetails: const [
                                'Nghe nhạc và khám phá mà không giới hạn số lượt hay thời gian sử dụng.',
                                'Tạo không giới hạn số lượng playlists để sắp xếp nhạc yêu thích của bạn.',
                                'Truy cập các bài hát Premium và nội dung đặc biệt chỉ dành cho thành viên Premium.',
                              ],
                              onPressed: () => _requestPayment(ref, context, resolvedId, 'Premium'),
                              highlight: true,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  Card(
                    color: Colors.blue.shade900.withValues(alpha: 0.3),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.info_outline, color: Colors.blueAccent),
                              const SizedBox(width: 8),
                              Text(
                                'Lưu ý ⚠️',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueAccent,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _NoticeItem(
                            'Sau khi mua gói Premium, thời hạn còn lại của gói VIP sẽ bị hủy bỏ. Thời hạn gói nâng cấp sẽ được tính từ 0 giờ ngày mua.',
                          ),
                          const SizedBox(height: 8),
                          _NoticeItem(
                            'Nếu có gói đang có và chưa hết hạn, khi mua gói cùng cấp sẽ được cộng thêm 30 ngày vào ngày hết hạn.',
                          ),
                          const SizedBox(height: 8),
                          _NoticeItem(
                            'Gói nâng cấp sau khi mua sẽ không thể hoàn tiền.',
                          ),
                          const SizedBox(height: 8),
                          _NoticeItem(
                            'Vui lòng đọc kỹ chính sách mua hàng của chúng tôi ',
                            linkText: 'tại đây',
                            onLinkTap: () => context.go('/policy'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              ),
      ),
    );
  }

  Future<void> _requestPayment(
      WidgetRef ref, BuildContext context, String userId, String tier) async {
    // Lấy role mới nhất từ database (không dùng token vì có thể đã cũ)
    final repository = ref.read(repositoryProvider);
    String? currentRoleFromDb;
    try {
      final profile = await repository.getMyProfile(userId);
      currentRoleFromDb = profile.role?.toLowerCase();
    } catch (e) {
      // Nếu lỗi, fallback về role từ session
      final session = ref.read(authControllerProvider).session;
      currentRoleFromDb = session?.role?.toLowerCase() ?? 'normal';
    }
    
    final currentRole = currentRoleFromDb ?? 'normal';
    final isVipOrPremium = currentRole == 'vip' || currentRole == 'premium';
    
    bool confirm = false;
    
    // Nếu user đang ở role VIP hoặc Premium
    if (isVipOrPremium) {
      // Xác định currentTier chính xác dựa trên role (case-insensitive)
      String currentTier;
      if (currentRole == 'vip') {
        currentTier = 'VIP';
      } else if (currentRole == 'premium') {
        currentTier = 'Premium';
      } else {
        currentTier = 'Normal'; // Fallback (không nên xảy ra vì đã check isVipOrPremium)
      }
      final targetTier = tier;
      
      // Trường hợp 1: Mua trùng gói (VIP mua VIP, Premium mua Premium)
      if (currentTier == targetTier) {
        confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Mua thêm gói $targetTier'),
            content: Text(
              'Bạn đang có gói $currentTier. Nếu mua thêm gói $targetTier, thời hạn sẽ được cộng thêm 30 ngày vào ngày hết hạn hiện tại.\n\nBạn có muốn tiếp tục?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Hủy'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(backgroundColor: Colors.blue),
                child: const Text('Tiếp tục'),
              ),
            ],
          ),
        ) ?? false;
      } 
      // Trường hợp 2: Mua khác gói (VIP mua Premium, Premium mua VIP)
      else {
        // Kiểm tra số playlist hiện tại nếu Premium mua VIP
        int? currentPlaylistCount;
        String? warningMessage;
        
        if (currentTier == 'Premium' && targetTier == 'VIP') {
          try {
            final limits = await repository.getPlaylistLimits(userId);
            currentPlaylistCount = limits.currentPlaylists;
            const vipMaxPlaylists = 10;
            
            if (currentPlaylistCount > vipMaxPlaylists) {
              warningMessage = '\n\n⚠️ Lưu ý: Bạn hiện có $currentPlaylistCount playlists. Gói VIP chỉ cho phép tối đa $vipMaxPlaylists playlists. Sau khi mua VIP, bạn sẽ không thể tạo playlist mới cho đến khi xóa bớt playlist (còn tối đa $vipMaxPlaylists playlists).';
            }
          } catch (e) {
            // Nếu lỗi, bỏ qua cảnh báo
          }
        }
        
        confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Cảnh báo'),
            content: Text(
              'Bạn đang có gói $currentTier. Nếu mua gói $targetTier, gói $currentTier hiện tại sẽ bị hủy và thời hạn sẽ được tính từ 0 giờ ngày mua.${warningMessage ?? ''}\n\nBạn có chắc chắn muốn tiếp tục?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Hủy'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Xác nhận'),
              ),
            ],
          ),
        ) ?? false;
      }
    } 
    // Nếu user chưa có gói VIP/Premium, hiển thị dialog xác nhận bình thường
    else {
      confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Xác nhận mua'),
          content: Text('Bạn có chắc muốn nâng cấp lên gói $tier không?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Thanh toán'),
            ),
          ],
        ),
      ) ?? false;
    }

    if (!confirm || !context.mounted) return;

    try {
      final repository = ref.read(repositoryProvider);
      // Map tier to price and description (match React frontend format)
      // Gửi tier trực tiếp là "VIP" hoặc "Premium" (không phải VIP30/VIP90)
      final tierInfo = _getTierInfo(tier);
      final url = await repository.requestPaymentUrl({
        'orderType': 'billpayment',
        'amount': tierInfo['price'],
        'orderDescription': 'Người dùng $userId thanh toán gói ${tierInfo['title']}',
        'name': '$userId, ${tierInfo['title']}', // Backend sẽ parse tier từ đây
      });
      if (!context.mounted) return;
      
      final uri = Uri.parse(url);
      
      // Kiểm tra xem có thể mở URL không
      final canLaunch = await canLaunchUrl(uri);
      
      if (canLaunch) {
        // Thử mở URL với externalApplication mode (mở trong browser)
        try {
          await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );
        } catch (e) {
          // Nếu externalApplication không hoạt động, thử platformDefault
          try {
            await launchUrl(
              uri,
              mode: LaunchMode.platformDefault,
            );
          } catch (e2) {
            // Nếu cả hai đều không hoạt động, thử inAppWebView
            try {
              await launchUrl(
                uri,
                mode: LaunchMode.inAppWebView,
              );
            } catch (e3) {
              throw Exception('Không thể mở trình duyệt để thanh toán. Vui lòng kiểm tra kết nối mạng và thử lại.');
            }
          }
        }
      } else {
        // Nếu canLaunchUrl trả về false, vẫn thử mở (có thể do Android 11+ package visibility)
        try {
          await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );
        } catch (e) {
          throw Exception('Không thể mở trình duyệt để thanh toán. Vui lòng kiểm tra kết nối mạng và thử lại. Lỗi: $e');
        }
      }
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể mở thanh toán: ${error.toString()}'),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Thử lại',
            onPressed: () => _requestPayment(ref, context, userId, tier),
          ),
        ),
      );
    }
  }

  Map<String, dynamic> _getTierInfo(String tier) {
    switch (tier) {
      case 'VIP':
        return {'title': 'VIP', 'price': 99000};
      case 'Premium':
        return {'title': 'Premium', 'price': 199000};
      default:
        return {'title': 'VIP', 'price': 99000};
    }
  }

}

class _NoticeItem extends StatelessWidget {
  const _NoticeItem(this.text, {this.linkText, this.onLinkTap});

  final String text;
  final String? linkText;
  final VoidCallback? onLinkTap;

  @override
  Widget build(BuildContext context) {
    if (linkText != null && onLinkTap != null) {
      return RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.white70, fontSize: 14),
          children: [
            TextSpan(text: text),
            TextSpan(
              text: linkText,
              style: const TextStyle(
                color: Colors.blueAccent,
                decoration: TextDecoration.underline,
              ),
              recognizer: TapGestureRecognizer()..onTap = onLinkTap,
            ),
          ],
        ),
      );
    }
    return Text(
      text,
      style: const TextStyle(color: Colors.white70, fontSize: 14),
    );
  }
}

class _PlanCard extends StatefulWidget {
  const _PlanCard({
    required this.title,
    required this.price,
    required this.icon,
    required this.iconColor,
    required this.benefits,
    required this.benefitDetails,
    required this.onPressed,
    this.highlight = false,
  });

  final String title;
  final String price;
  final IconData icon;
  final Color iconColor;
  final List<String> benefits;
  final List<String> benefitDetails;
  final VoidCallback onPressed;
  final bool highlight;

  @override
  State<_PlanCard> createState() => _PlanCardState();
}

class _PlanCardState extends State<_PlanCard> {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: widget.highlight ? 8 : 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: widget.highlight
            ? const BorderSide(color: Colors.amber, width: 2)
            : BorderSide(color: Colors.grey.shade700, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.highlight)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Khuyến nghị',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            if (widget.highlight) const SizedBox(height: 12),
            Icon(widget.icon, size: 48, color: widget.iconColor),
            const SizedBox(height: 16),
            Text(
              widget.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...widget.benefits.asMap().entries.map((entry) {
              final index = entry.key;
              final benefit = entry.value;
              final detail = widget.benefitDetails[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Tooltip(
                  message: detail,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.lightGreenAccent,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          benefit,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            // Thay Spacer() bằng SizedBox để tránh lỗi unbounded height
            const SizedBox(height: 16),
            Text(
              widget.price,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.blueAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: widget.onPressed,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  widget.title == 'VIP' ? 'Nâng cấp VIP' : 'Nâng cấp Premium',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PaymentResultScreen extends ConsumerStatefulWidget {
  const PaymentResultScreen({
    super.key,
    this.queryParams,
    this.status,
    this.message,
  });

  final Map<String, String>? queryParams;
  final String? status;
  final String? message;

  @override
  ConsumerState<PaymentResultScreen> createState() => _PaymentResultScreenState();
}

class _PaymentResultScreenState extends ConsumerState<PaymentResultScreen> {
  bool _loading = true;
  Map<String, dynamic>? _result;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Đợi frame đầu tiên để context sẵn sàng
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _processPayment();
    });
  }

  Future<void> _processPayment() async {
    // Lấy query params từ widget hoặc route state
    final queryParams = widget.queryParams ?? 
        GoRouter.of(context).routerDelegate.currentConfiguration.uri.queryParameters;

    // Kiểm tra xem có query params từ VNPay không
    if (queryParams.isEmpty || !queryParams.containsKey('vnp_ResponseCode')) {
      // Nếu không có query params, có thể là direct navigation hoặc test
      if (widget.status != null) {
        setState(() {
          _loading = false;
          _result = {
            'success': widget.status == 'success',
            'message': widget.message,
          };
        });
        return;
      }
      setState(() {
        _loading = false;
        _error = 'Không có dữ liệu giao dịch. Có thể bạn đã hủy trước khi hoàn tất.';
      });
      return;
    }

    // Xử lý callback từ VNPay
    try {
      final repository = ref.read(repositoryProvider);
      final result = await repository.processPaymentReturn(queryParams);

      // Kiểm tra success từ response code
      final responseCode = queryParams['vnp_ResponseCode'];
      final transactionStatus = queryParams['vnp_TransactionStatus'];
      final success = responseCode == '00' && transactionStatus == '00';

      setState(() {
        _loading = false;
        _result = {
          ...result,
          'success': success,
          'orderId': result['orderId'] ?? queryParams['vnp_TxnRef'],
          'paymentMethod': result['paymentMethod'] ?? 'VnPay',
          'userId': result['userId'] ?? '',
          'tier': result['tier'] ?? '',
        };
      });

      // Nếu thanh toán thành công, refresh auth state để lấy role mới
      if (success && result['tier'] != null) {
        // Reload session để lấy token mới với role đã cập nhật
        await Future.delayed(const Duration(milliseconds: 500));
        await ref.read(authControllerProvider.notifier).reloadSession();
      }
    } catch (error) {
      setState(() {
        _loading = false;
        _error = 'Lỗi khi xác thực giao dịch với hệ thống. Vui lòng thử lại.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return AppPage(
        title: 'Kết quả thanh toán',
        showPrimaryNav: false,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null || _result == null) {
      return AppPage(
        title: 'Kết quả thanh toán',
        showPrimaryNav: false,
        child: Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error,
                    size: 72,
                    color: Colors.redAccent,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Thanh toán thất bại',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _error ?? 'Thanh toán thất bại hoặc bị hủy giữa chừng.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.go('/'),
                    child: const Text('Về trang chủ'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final success = _result!['success'] == true;
    return AppPage(
      title: 'Kết quả thanh toán',
      showPrimaryNav: false,
      child: Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  success ? Icons.check_circle : Icons.error,
                  size: 72,
                  color: success ? Colors.greenAccent : Colors.redAccent,
                ),
                const SizedBox(height: 16),
                Text(
                  success ? '✅ Thanh toán thành công!' : '❌ Thanh toán thất bại.',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (_result!['orderId'] != null) ...[
                  const SizedBox(height: 24),
                  _InfoRow(
                    label: 'Mã giao dịch:',
                    value: _result!['orderId'].toString(),
                  ),
                ],
                if (_result!['paymentMethod'] != null) ...[
                  const SizedBox(height: 12),
                  _InfoRow(
                    label: 'Phương thức:',
                    value: _result!['paymentMethod'].toString(),
                  ),
                ],
                if (_result!['userId'] != null && _result!['userId'].toString().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _InfoRow(
                    label: 'Người dùng:',
                    value: _result!['userId'].toString(),
                  ),
                ],
                if (_result!['tier'] != null && _result!['tier'].toString().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _InfoRow(
                    label: 'Gói:',
                    value: _result!['tier'].toString(),
                  ),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.go('/'),
                  child: const Text('Về trang chủ'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Colors.white70),
          ),
        ),
      ],
    );
  }
}

