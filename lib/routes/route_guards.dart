import 'package:auto_route/auto_route.dart';
import 'package:lingua/core/di/global_providers.dart';
import 'package:lingua/core/services/session_notifier.dart';
import 'package:lingua/routes/app_router.dart';

/// Chặn route cần đăng nhập. Chờ restore session xong mới quyết (tránh đẩy nhầm về Login
/// khi deep-link lúc cold start).
class AuthGuard extends AutoRouteGuard {
  const AuthGuard();

  @override
  Future<void> onNavigation(
    NavigationResolver resolver,
    StackRouter router,
  ) async {
    await globalContainer.read(sessionProvider.notifier).ready;
    if (globalContainer.read(sessionProvider)) {
      resolver.next();
    } else {
      resolver.redirectUntil(const LoginRoute());
    }
  }
}
