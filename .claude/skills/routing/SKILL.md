---
name: routing
description: Điều hướng bằng auto_route — appRouter toàn cục, danh sách route hiện có, thêm route/@RoutePage, truyền tham số, AuthGuard (chờ sessionProvider.ready), shell bottom nav AutoTabsRouter, điều hướng ngoài widget tree. Đọc khi thêm màn mới, navigate giữa màn, chặn route cần đăng nhập, hoặc sửa bottom nav.
---

# Routing — auto_route

File: `lib/routes/app_router.dart` (router), `route_guards.dart` (AuthGuard).

## Router

```dart
part 'app_router.gr.dart';

/// Router duy nhất của app — dùng `appRouter` ở chỗ không có `context`.
final appRouter = AppRouter();

@AutoRouterConfig(replaceInRouteName: 'Page,Route')
class AppRouter extends RootStackRouter {
  static const _auth = [AuthGuard()];

  @override
  List<AutoRoute> get routes => [
    AutoRoute(page: SplashRoute.page, path: '/splash', initial: true),
    AutoRoute(page: LoginRoute.page, path: '/login'),
    AutoRoute(page: AdsDemoRoute.page, path: '/ads-demo'),
    AutoRoute(
      page: MainRoute.page,
      path: '/main', // KHÔNG dùng '/': app mở bằng '/' → phải vào Splash (initial)
      guards: _auth,
      children: [
        AutoRoute(page: HomeRoute.page, path: ''),
        AutoRoute(page: VoucherListRoute.page, path: 'vouchers'),
        AutoRoute(page: SettingsRoute.page, path: 'settings'),
      ],
    ),
    AutoRoute(page: PaginationDemoRoute.page, path: '/pagination-demo'),
    AutoRoute(page: OpenapiUserListRoute.page, path: '/users', guards: _auth),
    AutoRoute(page: GeneratedUserListRoute.page, path: '/users-generated', guards: _auth),
  ];
}
```
Tên route = tên class Page đổi `Page` → `Route` (`PaginationDemoPage` → `PaginationDemoRoute`). `app.dart` gắn `routerConfig: appRouter.config(navigatorObservers: () => [TalkerRouteObserver(talker)])`.

## Thêm route

1. Page có `@RoutePage()`:
   ```dart
   @RoutePage()
   class VoucherDetailPage extends HookConsumerWidget {
     const VoucherDetailPage({required this.id, super.key});
     final String id;
     ...
   }
   ```
   Tham số path: `@PathParam('id') required this.id`; query: `@QueryParam('q') this.q`.
2. Import page vào `app_router.dart`, thêm `AutoRoute(page: VoucherDetailRoute.page, path: '/vouchers/:id')` (thêm `guards: _auth` nếu cần đăng nhập).
3. `make gen` → sinh `app_router.gr.dart`.

## Điều hướng

```dart
context.router.push(const AdsDemoRoute());
context.router.push(VoucherDetailRoute(id: v.id));
context.router.replace(const SplashRoute());
context.router.replaceAll([const MainRoute()]);   // xoá stack
context.router.maybePop();
```
Nhận kết quả: `final ok = await context.router.push<bool>(...)`; trả về: `context.router.maybePop(true)`.

Không có `context` (service, interceptor, quick action, listener ở `app.dart`): dùng `appRouter`:
```dart
appRouter.push(const VoucherListRoute());
appRouter.replaceAll([const LoginRoute()]);
```

## AuthGuard

```dart
class AuthGuard extends AutoRouteGuard {
  const AuthGuard();

  @override
  Future<void> onNavigation(NavigationResolver resolver, StackRouter router) async {
    await globalContainer.read(sessionProvider.notifier).ready;
    if (globalContainer.read(sessionProvider)) {
      resolver.next();
    } else {
      resolver.redirectUntil(const LoginRoute());
    }
  }
}
```
- Phải `await ready` trước khi đọc state — tránh đẩy nhầm user đã đăng nhập về Login khi deep link lúc cold start.
- Cold start bình thường do `SplashPage` quyết Main/Login; shell `MainRoute` hiện không gắn guard.
- Mất đăng nhập giữa chừng (logout, refresh token hỏng): listener `ref.listen(sessionProvider, ...)` trong `app.dart` gọi `appRouter.replaceAll([const LoginRoute()])`.

## Bottom nav (AutoTabsRouter)

`MainPage` (lib/features/main/main_page.dart):
```dart
return AutoTabsRouter(
  routes: const [HomeRoute(), VoucherListRoute(), SettingsRoute()],
  builder: (context, child) {
    final tabsRouter = AutoTabsRouter.of(context);
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: tabsRouter.activeIndex,
        onTap: tabsRouter.setActiveIndex,
        items: const [...],
      ),
    );
  },
);
```
Thêm tab = thêm child trong `MainRoute` ở router + thêm vào `routes` và `items` của `MainPage` (cùng thứ tự). Chuyển tab từ trong tab: `AutoTabsRouter.of(context).setActiveIndex(1)`; về shell từ ngoài: `context.router.replaceAll([const MainRoute()])`.

## Lưu ý

- Splash là `initial: true`; luồng: mạng → version → Main/Login (xem skill `architecture`).
- Không dùng `Navigator.push` cho màn có route; `Navigator`/`showDialog` chỉ cho dialog, bottom sheet.
