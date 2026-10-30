import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingua/core/di/global_providers.dart';
import 'package:lingua/core/services/app_version_service.dart';
import 'package:lingua/core/utils/logger.dart';
import 'package:lingua/design/l10n/l10n_extensions.dart';
import 'package:lingua/features/course/providers/learner_notifier.dart';
import 'package:lingua/gen/assets.gen.dart';
import 'package:lingua/modules/ads/ad_config.dart';
import 'package:lingua/modules/ads/ad_manager.dart';
import 'package:lingua/modules/app_config/app_notice.dart';
import 'package:lingua/routes/app_router.dart';

/// Khởi động: hỏi cập nhật nếu có bản mới → thông báo (Remote Config) → chưa chọn khoá học thì Onboarding, có rồi thì vào app.
@RoutePage()
class SplashPage extends HookConsumerWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useEffect(() {
      Future<void> bootstrap() async {
        try {
          await _showLaunchAd(ref);
          if (!context.mounted) return;
          await ref.read(appVersionServiceProvider).checkAndPrompt(context);
          if (context.mounted) await showAppNotice(context, ref);
        } catch (e, s) {
          talker.error('Splash bootstrap failed', e, s);
        }
        if (!context.mounted) return;
        await context.router.replaceAll([
          if (ref.read(learnerProvider).course == null)
            OnboardingRoute()
          else
            const MainRoute(),
        ]);
      }

      WidgetsBinding.instance.addPostFrameCallback((_) => bootstrap());
      return null;
    }, const <Object?>[]);

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: Assets.images.prod.image(width: 112, height: 112),
            ),
            const SizedBox(height: 20),
            Text(
              context.l10n.appName,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
    );
  }
}

const _kLaunches = 'launch_count_v1';

/// App Open lúc mở app — bỏ qua LẦN ĐẦU (ấn tượng đầu quyết định giữ chân D1). Chờ tải tối đa
/// 3 giây, không thêm lớp phủ (splash vốn là màn chờ); không có ad thì vào app ngay.
Future<void> _showLaunchAd(WidgetRef ref) async {
  final prefs = ref.read(sharedPrefsProvider);
  final launches = (prefs.getInt(_kLaunches) ?? 0) + 1;
  await prefs.setInt(_kLaunches, launches);
  if (launches < 2) return;
  await ref
      .read(adManagerProvider)
      .showAppOpen(
        AppOpenPlacement.splash,
        timeout: const Duration(seconds: 3),
        loadingOverlay: false,
      );
}
