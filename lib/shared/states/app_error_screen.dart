import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lingua/routes/app_router.dart';

/// Thay `ErrorWidget.builder` mặc định: debug hiện exception, release hiện thông báo chung.
/// Không dùng `Theme.of` vì có thể lỗi xảy ra trước khi MaterialApp build xong.
class AppErrorScreen extends StatelessWidget {
  const AppErrorScreen({required this.details, super.key});

  final FlutterErrorDetails details;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF9FAFB),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: Color(0xFFB91C1C),
              ),
              const SizedBox(height: 16),
              SelectableText(
                kDebugMode
                    ? details.exceptionAsString()
                    : 'Một sự cố không mong muốn đã xảy ra.\nVui lòng thử lại.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Color(0xFF1F2937)),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => appRouter.replaceAll([const SplashRoute()]),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Quay về trang chủ'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
