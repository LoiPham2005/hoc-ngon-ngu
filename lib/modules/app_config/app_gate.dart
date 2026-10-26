import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingua/core/services/app_version_service.dart';
import 'package:lingua/design/l10n/l10n_extensions.dart';
import 'package:lingua/modules/app_config/app_config.dart';

/// Khoá toàn app khi Remote Config `app_config` yêu cầu: đang bảo trì, hoặc bản đang chạy
/// thấp hơn `min_version` (bắt buộc cập nhật). Đặt trong `MaterialApp.builder` → phủ mọi màn,
/// đổi trên Firebase là áp dụng ngay; gỡ khoá thì quay lại đúng màn đang dở.
class AppGate extends ConsumerWidget {
  const AppGate({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);
    final version = ref.watch(packageInfoProvider).value?.version;
    final l10n = context.l10n;
    final block = config.maintenance
        ? _BlockScreen(
            icon: Icons.construction_rounded,
            title: l10n.maintenance_title,
            message: config.maintenanceMessage.isNotEmpty
                ? config.maintenanceMessage
                : l10n.maintenance_message,
          )
        : version != null && config.mustUpdate(version)
        ? _BlockScreen(
            icon: Icons.system_update_rounded,
            title: l10n.update_forceTitle,
            message: l10n.update_forceMessage,
            action: FilledButton(
              onPressed: () => ref.read(appVersionServiceProvider).openStore(),
              child: Text(l10n.update_now),
            ),
          )
        : null;
    // App bên dưới giữ nguyên trạng thái, chỉ bị ẩn và không nhận chạm khi đang khoá.
    return IndexedStack(
      index: block == null ? 0 : 1,
      sizing: StackFit.expand,
      children: [child, block ?? const SizedBox.shrink()],
    );
  }
}

class _BlockScreen extends StatelessWidget {
  const _BlockScreen({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 72, color: theme.colorScheme.primary),
                  const SizedBox(height: 24),
                  Text(
                    title,
                    style: theme.textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    style: theme.textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  if (action case final action?) ...[
                    const SizedBox(height: 32),
                    SizedBox(width: double.infinity, child: action),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
