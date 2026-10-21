import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingua/core/services/app_version_service.dart';
import 'package:lingua/core/services/biometric_notifier.dart';
import 'package:lingua/core/services/session_notifier.dart';
import 'package:lingua/core/utils/logger.dart';
import 'package:lingua/routes/app_router.dart';

/// Khởi động: check version → (vân tay/Face ID nếu bật) → vào Main/Login theo trạng thái đăng nhập.
/// Mất mạng không chặn ở đây — `ConnectivityBanner` báo, từng màn tự có "Thử lại".
/// Lỗi bất kỳ → vẫn cho vào app (không để user kẹt ở spinner).
@RoutePage()
class SplashPage extends HookConsumerWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useEffect(() {
      Future<void> goToApp() async {
        await ref.read(sessionProvider.notifier).ready;
        // Đã đăng nhập + bật vân tay/Face ID → phải quét đúng mới vào; huỷ/sai → Login.
        final unlocked =
            ref.read(sessionProvider) &&
            (!ref.read(biometricProvider) ||
                await ref
                    .read(biometricProvider.notifier)
                    .authenticate('Mở khoá để vào ứng dụng'));
        if (!context.mounted) return;
        await context.router.replaceAll([
          unlocked ? const MainRoute() : const LoginRoute(),
        ]);
      }

      Future<void> bootstrap() async {
        try {
          if (!await ref
              .read(appVersionServiceProvider)
              .checkAndPrompt(context)) {
            return;
          }
        } catch (e, s) {
          talker.error('Splash bootstrap failed', e, s);
        }
        await goToApp();
      }

      WidgetsBinding.instance.addPostFrameCallback((_) => bootstrap());
      return null;
    }, const <Object?>[]);

    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
