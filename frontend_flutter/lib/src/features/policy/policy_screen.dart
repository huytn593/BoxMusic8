import 'package:flutter/material.dart';

import '../../widgets/app_page.dart';

class PolicyScreen extends StatelessWidget {
  const PolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Chính sách quyền riêng tư',
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Header
          Text(
            'Chính sách Quyền riêng tư',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Cập nhật lần cuối: 15 tháng 6, 2025',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white54,
                ),
          ),
          const SizedBox(height: 24),

          // Intro Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: const Border(
                left: BorderSide(color: Colors.redAccent, width: 4),
              ),
            ),
            child: Text(
              'Chính sách này giải thích cách BoxMusic thu thập, sử dụng và bảo vệ thông tin cá nhân của bạn khi sử dụng dịch vụ streaming nhạc của chúng tôi.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    height: 1.5,
                  ),
            ),
          ),
          const SizedBox(height: 32),

          // Overview Section
          _PolicySection(
            title: 'Tổng quan về Chính sách',
            content:
                'Tại BoxMusic, chúng tôi cam kết bảo vệ quyền riêng tư và dữ liệu cá nhân của bạn. Chính sách này mô tả cách chúng tôi xử lý thông tin của bạn khi sử dụng nền tảng streaming nhạc của chúng tôi.',
          ),
          const SizedBox(height: 24),

          // Commitment Section
          _PolicySection(
            title: 'Cam kết của chúng tôi',
            children: const [
              _BulletPoint('Minh bạch trong việc thu thập và sử dụng dữ liệu'),
              _BulletPoint('Bảo mật thông tin cá nhân với các biện pháp kỹ thuật tiên tiến'),
              _BulletPoint('Tôn trọng quyền kiểm soát dữ liệu của người dùng'),
              _BulletPoint('Tuân thủ các quy định pháp luật về bảo vệ dữ liệu'),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Contact Section (kept from original but styled)
          _PolicySection(
            title: 'Liên hệ',
            content: 'Nếu bạn có bất kỳ câu hỏi nào về chính sách này, vui lòng liên hệ với chúng tôi qua email: huytn593@gmail.com',
          ),
        ],
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  const _PolicySection({
    required this.title,
    this.content,
    this.children,
  });

  final String title;
  final String? content;
  final List<Widget>? children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        if (content != null)
          Text(
            content!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                  height: 1.6,
                ),
          ),
        if (children != null) ...[
          const SizedBox(height: 8),
          ...children!,
        ],
      ],
    );
  }
}

class _BulletPoint extends StatelessWidget {
  const _BulletPoint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Icon(Icons.circle, size: 6, color: Colors.white54),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                    height: 1.5,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
