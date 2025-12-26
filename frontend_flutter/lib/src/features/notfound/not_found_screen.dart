import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/app_page.dart';

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Không tìm thấy trang',
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off, size: 64),
            const SizedBox(height: 16),
            const Text('Trang bạn yêu cầu không tồn tại.'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Về trang chủ'),
            ),
          ],
        ),
      ),
    );
  }
}

