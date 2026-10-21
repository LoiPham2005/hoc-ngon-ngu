import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingua/core/services/biometric_notifier.dart';
import 'package:lingua/design/l10n/locale_notifier.dart';
import 'package:lingua/design/theme/theme_notifier.dart';
import 'package:lingua/features/auth/providers/auth_notifier.dart';
import 'package:lingua/shared/base/app_scaffold.dart';
import 'package:lingua/shared/dialogs/app_confirmation_dialog.dart';

@RoutePage()
class SettingsPage extends HookConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final locale = ref.watch(localeProvider);
    final biometricOn = ref.watch(biometricProvider);
    final biometricAvailable = useFuture(
      useMemoized(ref.read(biometricProvider.notifier).isAvailable),
    ).data;

    return AppScaffold(
      appBar: AppBar(title: const Text('Cài đặt')),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Giao diện',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final v in AppThemeVariant.values)
                  ChoiceChip(
                    label: Text(v.label),
                    selected: theme == v,
                    onSelected: (_) => ref.read(themeProvider.notifier).set(v),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            title: const Text('Ngôn ngữ'),
            subtitle: Text(locale.languageCode.toUpperCase()),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final picked = await showDialog<String>(
                context: context,
                builder: (_) => SimpleDialog(
                  title: const Text('Chọn ngôn ngữ'),
                  children: [
                    SimpleDialogOption(
                      onPressed: () => Navigator.pop(context, 'vi'),
                      child: const Text('Tiếng Việt'),
                    ),
                    SimpleDialogOption(
                      onPressed: () => Navigator.pop(context, 'en'),
                      child: const Text('English'),
                    ),
                  ],
                ),
              );
              if (picked != null) {
                await ref.read(localeProvider.notifier).set(Locale(picked));
              }
            },
          ),
          // Máy không có cảm biến / chưa cài vân tay, khuôn mặt → ẩn.
          if (biometricAvailable ?? false)
            SwitchListTile(
              secondary: const Icon(Icons.fingerprint),
              title: const Text('Mở khoá bằng vân tay / Face ID'),
              value: biometricOn,
              onChanged: (v) => ref
                  .read(biometricProvider.notifier)
                  .setEnabled(v, reason: 'Xác nhận để bật mở khoá nhanh'),
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
            onTap: () async {
              final ok = await AppConfirmationDialog.show(
                context,
                title: 'Đăng xuất',
                message: 'Bạn có chắc chắn muốn đăng xuất?',
                destructive: true,
              );
              if (ok) {
                await ref.read(authProvider.notifier).logout();
              }
            },
          ),
        ],
      ),
    );
  }
}
