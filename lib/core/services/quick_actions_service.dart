import 'package:lingua/core/di/global_providers.dart';
import 'package:lingua/core/services/session_notifier.dart';
import 'package:lingua/routes/app_router.dart';
import 'package:quick_actions/quick_actions.dart';

/// App shortcuts (nhấn giữ icon app). Icon = tên drawable Android / imageset iOS.
abstract class AppQuickActions {
  static const _plugin = QuickActions();

  /// Gọi 1 lần sau khi router sẵn sàng (frame đầu tiên).
  static Future<void> init() async {
    await _plugin.initialize((type) {
      switch (type) {
        case 'vouchers':
          appRouter.push(const VoucherListRoute());
        case 'login':
          appRouter.push(const LoginRoute());
        case 'logout':
          globalContainer.read(sessionProvider.notifier).logout();
      }
    });
    await update(isAuthenticated: globalContainer.read(sessionProvider));
  }

  /// Đổi danh sách shortcut theo trạng thái đăng nhập.
  static Future<void> update({required bool isAuthenticated}) =>
      _plugin.setShortcutItems(
        isAuthenticated
            ? const [
                ShortcutItem(
                  type: 'vouchers',
                  localizedTitle: 'Voucher',
                  icon: 'ic_shortcut_scan',
                ),
                ShortcutItem(
                  type: 'logout',
                  localizedTitle: 'Đăng xuất',
                  icon: 'ic_shortcut_logout',
                ),
              ]
            : const [
                ShortcutItem(
                  type: 'login',
                  localizedTitle: 'Đăng nhập',
                  icon: 'ic_shortcut_login',
                ),
              ],
      );
}
