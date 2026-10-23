# lingua — Project Instructions for Claude

Reply tiếng Việt. Code, tên class/file, thuật ngữ kỹ thuật giữ tiếng Anh.

## Kiến trúc

```
lib/
  config/        FlavorConfig, AppInfo (tên app, id/link store), AppInitializer (boot từng bước), SystemUIManager
  core/
    di/          globalContainer, sharedPrefsProvider, secureStorageProvider
    errors/      Failure (sealed) + ErrorHandler.handle(e)
    riverpod/    BaseNotifier (`run`), PaginatedNotifier, ref.cacheFor
    network/     dioProvider, AuthInterceptor, ApiResponse<T> / PaginatedResponse<T>
    services/    session_notifier (token đăng nhập), biometric (vân tay/Face ID), connectivity, notification, fcm, app_version, quick_actions
    utils/       talker (log), toast
  design/        theme (theme_tailor tokens) + l10n (+ context.l10n)
  shared/        base (AppScaffold, AppButton, AppTextField), dialogs, states (AsyncView, Loading/Empty/Error)
  features/{name}/
    {name}_page.dart                  HookConsumerWidget — page để thẳng ở gốc feature
    models/     {name}_model.dart     @freezed            ┐ CHỈ khi feature gọi API
    services/   {name}_service.dart   @RestApi (Retrofit) ┘
    providers/  {name}_notifier.dart  @riverpod class ... with BaseNotifier<T>
    widgets/    (khi page có widget con riêng)
  modules/       ads (AdManager), iap (isPremiumProvider), analytics, app_config — Remote Config dùng chung ở core/services
  routes/        app_router (`appRouter` toàn cục), route_guards
```

## DI = Riverpod (không get_it)

- Service singleton: functional provider đặt cạnh class.
  ```dart
  @Riverpod(keepAlive: true)
  FooService fooService(Ref ref) => FooService(ref.read(dioProvider));
  ```
- Chỗ không có `ref` (interceptor, guard, service khác): `globalContainer.read(fooServiceProvider)`.
- Lưu trữ: `ref.read(sharedPrefsProvider)` / `ref.read(secureStorageProvider)` — dùng thẳng, không wrapper.
- Router: `appRouter` (biến toàn cục) hoặc `context.router`.

## State — Riverpod (KHÔNG BLoC/Cubit/GetX)

```dart
@riverpod
class VoucherNotifier extends _$VoucherNotifier with BaseNotifier<List<VoucherModel>> {
  late VoucherService _service;

  @override
  Future<List<VoucherModel>> build() {
    _service = VoucherService(ref.dio);
    return _fetch();
  }

  Future<List<VoucherModel>> _fetch() async => (await _service.getVouchers()).data;

  Future<void> refresh() => run(_fetch);
  Future<void> search(String q) => run(() => _search(q), cancelPrevious: true);
  Future<void> delete(String id) => run(
        () => _service.deleteVoucher(id),
        apply: (list, _) => list.where((v) => v.id != id).toList(),
        successMessage: 'Đã xoá',
      );
}
```

Mọi thao tác async đi qua **một hàm `run(action, ...)`** (trả `true` khi thành công):

- Kết quả cùng kiểu state `T` → thay state. Khác kiểu → giữ state; muốn sửa tại chỗ thì truyền `apply: (current, result) => ...`.
- Đang chạy: còn data thì giữ data + thanh tiến trình. Lỗi: còn data → giữ data + toast; chưa có data → màn lỗi.
- Tuỳ chọn: `cancelPrevious` (search/filter), `dropIfBusy` (chống bấm 2 lần), `silent` (không hiện loading), `successMessage` / `errorMessage` (toast).
- Backend trả `{ "data": ... }` → service `Future<ApiResponse<T>>`, lấy `res.data`. Danh sách phân trang: `ApiResponse<PaginatedResponse<T>>` (`items` + `meta`: page, limit, total, totalPages, hasNext). Lỗi đi bằng HTTP status + `{error:{code,message,fields}}` → `ErrorHandler`.
- JSON backend là camelCase (không đổi tên field); JSON snake_case (Remote Config) → `@JsonSerializable(fieldRename: FieldRename.snake)` trên model.
- Phân trang: mixin `PaginatedNotifier<E>` (`fetchPage`, `loadFirstPage`, `loadMore`). Cache sau khi rời màn: `ref.cacheFor(Duration)`.

Page: dùng `AsyncView<T>(state:, notifier:, onRetry:, onRefresh:, builder:)` — tự lo loading/empty/error + toast. Xem `_reference/voucher/`.

## Network & lỗi

- Service Retrofit trả `Future<T>`, `Future<ApiResponse<T>>` hoặc `Future<void>` — KHÔNG bọc Result.
- Lỗi Dio → `ErrorHandler.handle(e)` → `Failure` (BaseNotifier tự làm). Ném lỗi nghiệp vụ: `throw ServerFailure('...')`.
- Request body: tạo `@freezed` Request class, không dùng `Map<String, dynamic>`.

## Log & thông báo

- `talker.info('[TAG] ...')`, `talker.error('msg', e, s)` — tự đẩy Crashlytics/Sentry, che PII.
- `toast.success/error(...)`, `toast.loading()` / `toast.stopLoading()`.

## Quy tắc

1. Ưu tiên thư viện có sẵn, không viết tay lại thứ thư viện đã làm.
2. Sau khi sửa `@riverpod`, `@freezed`, `@RestApi`, `@RoutePage`: `make gen`.
3. Feature mới gọi API: tự viết model `@freezed` + service Retrofit `@RestApi` trong feature (app hiện chạy offline, chưa có backend). Thêm route vào `app_router.dart`.
4. Code chưa dùng thì không thêm "để sẵn".

## Skills

`.claude/skills/` — đọc khi cần chi tiết: architecture, state-management, network-error, routing, design-system, modules, commands, new-feature.
