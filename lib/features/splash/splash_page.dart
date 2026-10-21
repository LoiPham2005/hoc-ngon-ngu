import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingua/core/services/app_version_service.dart';
import 'package:lingua/core/utils/logger.dart';
import 'package:lingua/design/l10n/l10n_extensions.dart';
import 'package:lingua/features/course/providers/learner_notifier.dart';
import 'package:lingua/gen/assets.gen.dart';
import 'package:lingua/routes/app_router.dart';

/// Khởi động: kiểm tra phiên bản → chưa chọn khoá học thì Onboarding, có rồi thì vào app.
@RoutePage()
class SplashPage extends HookConsumerWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useEffect(() {
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
