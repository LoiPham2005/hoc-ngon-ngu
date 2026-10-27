---
name: architecture
description: Cấu trúc thư mục, luồng khởi động app (main_* → main() → AppInitializer → App), DI bằng Riverpod (globalContainer, provider keepAlive), lưu trữ (SharedPreferences / FlutterSecureStorage), log talker, cấu hình theo flavor. Đọc khi chưa biết file mới đặt ở đâu, cần thêm bước init lúc boot, thêm service singleton, lưu dữ liệu local, hoặc đọc provider ở chỗ không có `ref`.
---

# Kiến trúc lingua

## Thư mục

```
lib/
  main.dart            1 entry cho mọi flavor (`appFlavor` từ `--flavor`): runZonedGuarded, talker, Sentry, globalContainer, error handlers
  app.dart             UncontrolledProviderScope + MaterialApp.router
  config/              flavor_config, app_info (tên app, id/link store), app_initializer (init từng bước), system_ui_manager
  core/di/             global_providers (globalContainer, sharedPrefs, secureStorage)
  core/errors/         Failure (sealed) + ErrorHandler
  core/riverpod/       BaseNotifier (`run`), PaginatedNotifier, ref_extensions
  core/network/        dio_provider, AuthInterceptor, ApiResponse/PaginatedResponse
  core/services/       session_notifier, notification, fcm, app_version, quick_actions
  core/utils/          logger (talker), toast
  design/              theme (theme_tailor) + l10n (ARB, LocaleNotifier)
  shared/              base / dialogs / states
  features/<name>/     <name>_page.dart ở gốc · models/ services/ (chỉ khi gọi API) · providers/ · widgets/
  modules/             ads, iap, analytics, attribution, app_config
  routes/              config/app_router.dart, route_guards.dart
  gen/                 sinh tự động (assets, l10n) — không sửa tay
```

Không có tầng domain/use case: notifier gọi thẳng service Retrofit.

## Luồng khởi động

`main()` (lib/main.dart, flavor = `appFlavor` từ `--flavor`), tất cả trong `runZonedGuarded`:
1. `WidgetsFlutterBinding.ensureInitialized()`, đọc `FlavorConfig.current` (tự lấy flavor từ `appFlavor`).
2. `configureTalker(...)` theo flavor; `SentryFlutter.init` nếu có `sentryDsn` và không phải debug.
3. Tạo `globalContainer = ProviderContainer(observers: [TalkerRiverpodObserver...], overrides: [sharedPrefsProvider.overrideWithValue(await SharedPreferences.getInstance())])`.
4. `await AppInitializer.initialize()` — Firebase → local notification → FCM → SystemUI → IAP → AdConfig → AdConsent → AdManager → AdLifecycle. Mỗi bước bọc `_step(name, fn)`: lỗi chỉ log, không chặn app.
5. Gắn `FlutterError.onError` (Crashlytics) và `PlatformDispatcher.instance.onError` (`talker.error`).
6. `runApp(const App())`.

`App` (lib/app.dart): `UncontrolledProviderScope(container: globalContainer)`; trong `_AppView` gắn `ErrorWidget.builder = AppErrorScreen`, `AppLifecycleListener(onResume: SystemUIManager.applyUiMode)`, `AppQuickActions.init()` sau frame đầu; `ref.listen(sessionProvider, ...)` → hết đăng nhập thì `appRouter.replaceAll([const LoginRoute()])`. MaterialApp bọc `ToastificationWrapper`, `builder: FlutterSmartDialog.init()`, `navigatorObservers: [TalkerRouteObserver(talker)]`.

Sau đó `SplashPage` lo: `appVersionServiceProvider.checkAndPrompt(context)` (bản mới không bắt buộc) → `showAppNotice` → Onboarding hoặc Main. Bắt buộc cập nhật / bảo trì do `AppGate` (trong `MaterialApp.builder`) khoá mọi màn.

### Thêm bước init

Thêm vào `AppInitializer.initialize()` qua `_step` để lỗi không làm sập boot:
```dart
await _step('Foo', () => globalContainer.read(fooServiceProvider).init());
```
Bước cần `context` (dialog) thì làm ở `SplashPage`, không làm ở AppInitializer.

### Cấu hình theo flavor

Không có env compile-time. Mọi giá trị khác nhau theo flavor nằm trong `FlavorConfig` (lib/config/flavor_config.dart): `apiBaseUrl`, `enableLogging`, `enableCrashlytics`, `sentryDsn`. Thêm field = thêm vào constructor + 3 nhánh `switch` trong `FlavorConfig.current`. Đọc: `FlavorConfig.current.apiBaseUrl`, `FlavorConfig.isDev`, `FlavorConfig.isProd`.

## DI = Riverpod codegen

Service singleton = functional provider `keepAlive` đặt ngay dưới class trong cùng file:
```dart
part 'notification_service.g.dart';

class NotificationService { ... }

@Riverpod(keepAlive: true)
NotificationService notificationService(Ref ref) => NotificationService();
```
Phụ thuộc service khác → `ref.read(...)` trong provider (vd `FcmService(ref.read(notificationServiceProvider))`). Provider có sẵn: `dioProvider`, `sharedPrefsProvider`, `secureStorageProvider`, `notificationServiceProvider`, `fcmServiceProvider`, `appVersionServiceProvider`, `analyticsServiceProvider`, `appConfigProvider`, `iapServiceProvider`, `adManagerProvider` (lib/modules/ads/ad_manager.dart).

Đọc:
- Trong widget/notifier: `ref.read(xProvider)` / `ref.watch(xProvider)`.
- Chỗ không có `ref` (interceptor, guard, static helper, AppInitializer): `globalContainer.read(xProvider)` — import `core/di/global_providers.dart`.
- Viết tắt có sẵn: `ref.dio` (dio_provider.dart).

Chọn kiểu provider:
- Service dùng chung nhiều nơi / cần override trong test → `@Riverpod(keepAlive: true)` functional.
- Service Retrofit chỉ 1 notifier dùng → tạo thẳng trong `build()`: `_service = VoucherService(ref.dio);`.
- State màn hình → `@riverpod class ... with BaseNotifier<T>` (xem skill `state-management`).

Sau khi sửa `@Riverpod`/`@riverpod`: `make gen`.

## Lưu trữ

Dùng thẳng thư viện, không có lớp bọc:
```dart
final prefs = ref.read(sharedPrefsProvider);          // SharedPreferences (sync read)
await prefs.setString('theme_variant', v.name);
final raw = prefs.getString('theme_variant');

final secure = ref.read(secureStorageProvider);       // FlutterSecureStorage (Keychain/Keystore)
await secure.write(key: AuthKeys.accessToken, value: token);
final token = await secure.read(key: AuthKeys.accessToken);
```
- Token, secret → `secureStorageProvider`. Prefs thường (theme, locale, cờ ads) → `sharedPrefsProvider`.
- Key đặt hằng `static const _key = '...'` trong class dùng nó (xem `ThemeNotifier`, `LocaleNotifier`), key auth ở `AuthKeys`.
- Xoá auth: chỉ `delete` đúng key, không `deleteAll` (xem `SessionNotifier.logout`).
- Cache dữ liệu API trong RAM: `ref.cacheFor(Duration)` trong `build()` của provider autoDispose. Không có HTTP cache.

## Log

`talker` toàn cục (lib/core/utils/logger.dart):
```dart
talker.info('[TAG] message');
talker.warning('[TAG] ...');
talker.error('Mô tả', e, s);   // tự gửi Crashlytics + Sentry, đã che PII (maskPii)
```
Không dùng `print`/`debugPrint`. Xem log trên máy: `openTalkerScreen(context)`. Riverpod log = `TalkerRiverpodObserver` (chỉ bật khi `enableLogging`), HTTP log = `TalkerDioLogger`, route log = `TalkerRouteObserver`.

## Thông báo UI

`toast` là hằng toàn cục (lib/core/utils/toast.dart): `toast.success/error/warning/info(msg, title: ...)`, `toast.loading([msg])` / `toast.stopLoading()`. Trong notifier không gọi toast trực tiếp — trả `successMessage`/`errorMessage` cho BaseNotifier, view tự bắn.

## Quy tắc

- Import bằng `package:lingua/...` (lint `always_use_package_imports`).
- Tên mới trong code bằng tiếng Anh; comment và chữ hiển thị được tiếng Việt.
- Ưu tiên thư viện có sẵn; không thêm code "để sẵn" khi chưa dùng.
