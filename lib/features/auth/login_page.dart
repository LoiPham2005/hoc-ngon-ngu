import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingua/core/riverpod/use_run_messages.dart';
import 'package:lingua/core/services/biometric_notifier.dart';
import 'package:lingua/core/services/session_notifier.dart';
import 'package:lingua/core/utils/toast.dart';
import 'package:lingua/design/theme/styles/app_dimensions.dart';
import 'package:lingua/features/auth/providers/auth_notifier.dart';
import 'package:lingua/routes/app_router.dart';
import 'package:lingua/shared/base/app_button.dart';
import 'package:lingua/shared/base/app_scaffold.dart';
import 'package:lingua/shared/base/app_text_field.dart';
import 'package:lingua/shared/dialogs/app_confirmation_dialog.dart';

/// Đăng nhập bằng API thật (`POST /auth/login`).
@RoutePage()
class LoginPage extends HookConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailCtl = useTextEditingController();
    final passwordCtl = useTextEditingController();
    final loading = ref.watch(authProvider.select((s) => s.isLoading));
    final notifier = ref.read(authProvider.notifier);
    final biometric = ref.read(biometricProvider.notifier);
    // Còn phiên (vào đây vì huỷ quét ở Splash) + đã bật → cho quét lại thay vì nhập mật khẩu.
    final canUnlock =
        ref.watch(sessionProvider) && ref.watch(biometricProvider);

    useRunMessages(notifier);

    Future<void> submit() async {
      final email = emailCtl.text.trim();
      final password = passwordCtl.text;
      if (email.isEmpty || password.isEmpty) {
        toast.warning('Nhập email và mật khẩu');
        return;
      }
      final ok = await notifier.login(identifier: email, password: password);
      if (!ok || !context.mounted) return;
      if (await biometric.shouldOffer() && context.mounted) {
        final accept = await AppConfirmationDialog.show(
          context,
          title: 'Đăng nhập nhanh',
          message:
              'Lần sau mở app bằng vân tay / Face ID, không cần nhập mật khẩu?',
          confirmText: 'Bật',
          cancelText: 'Để sau',
        );
        if (accept) {
          await biometric.setEnabled(
            true,
            reason: 'Xác nhận để bật đăng nhập nhanh',
          );
        }
      }
      if (context.mounted) await context.router.replaceAll([const MainRoute()]);
    }

    Future<void> unlock() async {
      if (await biometric.authenticate('Mở khoá để vào ứng dụng') &&
          context.mounted) {
        await context.router.replaceAll([const MainRoute()]);
      }
    }

    return AppScaffold(
      body: Padding(
        padding: const EdgeInsets.all(AppDimensions.space24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Đăng nhập',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            gapH32,
            AppTextField(
              controller: emailCtl,
              label: 'Email',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
            ),
            gapH16,
            AppTextField(
              controller: passwordCtl,
              label: 'Mật khẩu',
              obscureText: true,
              onSubmitted: (_) => submit(),
            ),
            gapH32,
            AppButton(
              label: 'Đăng nhập',
              isLoading: loading,
              onPressed: submit,
            ),
            if (canUnlock) ...[
              gapH12,
              OutlinedButton.icon(
                onPressed: unlock,
                icon: const Icon(Icons.fingerprint),
                label: const Text('Dùng vân tay / Face ID'),
              ),
            ],
            gapH12,
            TextButton(
              onPressed: () => context.router.push(const RegisterRoute()),
              child: const Text('Chưa có tài khoản? Đăng ký'),
            ),
          ],
        ),
      ),
    );
  }
}
