import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingua/core/riverpod/use_run_messages.dart';
import 'package:lingua/design/theme/styles/app_dimensions.dart';
import 'package:lingua/features/auth/providers/auth_notifier.dart';
import 'package:lingua/routes/app_router.dart';
import 'package:lingua/shared/base/app_button.dart';
import 'package:lingua/shared/base/app_scaffold.dart';
import 'package:lingua/shared/base/app_text_field.dart';

/// Tạo tài khoản (`POST /auth/register`) — xong là đăng nhập luôn và vào app.
@RoutePage()
class RegisterPage extends HookConsumerWidget {
  const RegisterPage({super.key});

  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[A-Za-z]{2,}$');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final nameCtl = useTextEditingController();
    final emailCtl = useTextEditingController();
    final passwordCtl = useTextEditingController();
    final loading = ref.watch(authProvider.select((s) => s.isLoading));
    final notifier = ref.read(authProvider.notifier);

    useRunMessages(notifier);

    Future<void> submit() async {
      if (!(formKey.currentState?.validate() ?? false)) return;
      final ok = await notifier.register(
        email: emailCtl.text.trim(),
        password: passwordCtl.text,
        fullName: nameCtl.text.trim(),
      );
      if (ok && context.mounted) {
        await context.router.replaceAll([const MainRoute()]);
      }
    }

    return AppScaffold(
      appBar: AppBar(title: const Text('Tạo tài khoản')),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppDimensions.space24),
          children: [
            AppTextField(
              controller: nameCtl,
              label: 'Họ tên (không bắt buộc)',
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  (v?.trim().length ?? 0) > 100 ? 'Tối đa 100 ký tự' : null,
            ),
            gapH16,
            AppTextField(
              controller: emailCtl,
              label: 'Email',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: (v) => _email.hasMatch(v?.trim() ?? '')
                  ? null
                  : 'Email không hợp lệ',
            ),
            gapH16,
            AppTextField(
              controller: passwordCtl,
              label: 'Mật khẩu',
              obscureText: true,
              textInputAction: TextInputAction.next,
              validator: (v) {
                final len = v?.length ?? 0;
                if (len < 8) return 'Tối thiểu 8 ký tự';
                if (len > 128) return 'Tối đa 128 ký tự';
                return null;
              },
            ),
            gapH16,
            AppTextField(
              label: 'Nhập lại mật khẩu',
              obscureText: true,
              onSubmitted: (_) => submit(),
              validator: (v) =>
                  v == passwordCtl.text ? null : 'Mật khẩu nhập lại không khớp',
            ),
            gapH32,
            AppButton(
              label: 'Tạo tài khoản',
              isLoading: loading,
              onPressed: submit,
            ),
            gapH12,
            TextButton(
              onPressed: () => context.router.maybePop(),
              child: const Text('Đã có tài khoản? Đăng nhập'),
            ),
          ],
        ),
      ),
    );
  }
}
