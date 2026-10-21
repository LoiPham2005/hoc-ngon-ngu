---
name: state-management
description: State bằng Riverpod codegen + mixin BaseNotifier (1 hàm `run` cho mọi thao tác async), PaginatedNotifier cho phân trang, ref.cacheFor, AsyncView (render + toast), provider sinh sẵn từ api_client, trạng thái đăng nhập sessionProvider. Đọc khi viết Notifier mới, gọi API từ UI, xử lý loading/error/empty, search, phân trang, create/update/delete. Cấm BLoC/Cubit/GetX, cấm setState cho logic async.
---

# State management — Riverpod + BaseNotifier

File: `lib/core/riverpod/` — `base_notifier.dart`, `paginated_notifier.dart`, `ref_extensions.dart`.

## Notifier chuẩn (mẫu `_reference/voucher`)

```dart
part 'voucher_notifier.g.dart';

@riverpod
class VoucherNotifier extends _$VoucherNotifier
    with BaseNotifier<List<VoucherModel>> {
  late VoucherService _service;

  @override
  Future<List<VoucherModel>> build() {
    _service = VoucherService(ref.dio);
    return _fetch();
  }

  Future<List<VoucherModel>> _fetch() async =>
      (await _service.getVouchers()).data;

  Future<void> refresh() => run(_fetch);

  Future<void> search(String query) => run(
    () async => query.isEmpty
        ? _fetch()
        : (await _service.searchVouchers(query)).data,
    cancelPrevious: true,
  );

  Future<void> delete(String id) => run(
    () async => (await _service.deleteVoucher(id)).data,
    apply: (list, _) => list.where((v) => v.id != id).toList(),
    dropIfBusy: true,
    successMessage: 'Đã xoá voucher',
  );
}
```
Provider sinh ra tên `voucherProvider` (bỏ hậu tố `Notifier`). `@riverpod` = autoDispose; state sống suốt app (user, cấu hình) thì `@Riverpod(keepAlive: true)`.

## API của BaseNotifier — một hàm `run`

```dart
Future<bool> run<R>(
  Future<R> Function() action, {
  T Function(T current, R result)? apply,
  bool silent = false,         // không đẩy loading (load-more, chạy nền)
  bool cancelPrevious = false, // search/filter: bỏ kết quả lần gọi cũ
  bool dropIfBusy = false,     // chống bấm 2 lần
  String? successMessage,      // toast khi thành công
  String? errorMessage,        // tiền tố toast lỗi: '$errorMessage: ${failure.message}'
})
```

- Thành công: có `apply` → `state = apply(state, result)`; không có mà `result` cùng kiểu `T` → thay state; khác kiểu → giữ state. Trả `true`.
- Đang chạy: còn data → giữ data + `isLoading` (AsyncView hiện thanh tiến trình); chưa có → `AsyncLoading`.
- Lỗi (`ErrorHandler.handle` → `Failure`, log qua talker): còn data → giữ data + phát `RunMessage` lỗi (toast); chưa có data → `AsyncError(failure)` (màn lỗi). Trả `false`.
- `ApiResponse<T>` → `.data` (backend lỗi thì Dio đã ném, có response là có `data`).
- Getter: `isBusy`, `messages` (`Stream<RunMessage>`, AsyncView tự nghe khi truyền `notifier`).
- Gán state tay khi cần (logout, optimistic): `state = AsyncData(x)`.
- Lưu ý: `T` nullable (vd `User?`) mà action trả `null` → state thành `null`.

Quy tắc:
- Lỗi nghiệp vụ → `throw ServerFailure('...')` (hoặc Failure khác) trong `action`, không tự `try/catch` rồi gán state.
- Không bọc kết quả bằng kiểu Either/kết quả riêng — service trả `Future<T>`, lỗi đi bằng exception.
- `build()` chỉ trả `Future<T>`; các hàm sau dùng `run`, không gán `state = AsyncLoading()` bằng tay.

## Phân trang — PaginatedNotifier

Mẫu `_reference/openapi_user` (client OpenAPI trả meta riêng → map sang `PaginatedResponse`):
```dart
@riverpod
class OpenapiUserNotifier extends _$OpenapiUserNotifier
    with BaseNotifier<List<User>>, PaginatedNotifier<User> {
  late UsersClient _api;

  @override
  Future<List<User>> build() {
    _api = ref.apiClient.users;
    return loadFirstPage();
  }

  @override
  Future<PaginatedResponse<User>> fetchPage(int page) async {
    final res = await _api.getUsers(page: page, limit: 20);
    final meta = res.data.meta;
    return PaginatedResponse(
      items: res.data.items,
      meta: PageMeta(page: meta.page, limit: meta.limit, total: meta.total,
          totalPages: meta.totalPages, hasNext: meta.hasNext),
    );
  }
}
```
Service Retrofit đã trả `ApiResponse<PaginatedResponse<E>>` thì chỉ cần unwrap `res.data` (xem `_reference/pagination_demo`). Có sẵn: `loadFirstPage()`, `refresh()`, `loadMore()` (bỏ kết quả nếu refresh chen ngang), `hasMore` (`meta.hasNext`), `isLoadingMore`, `currentPage`. Chỉ phân trang theo số trang.

UI gọi `notifier.loadMore()` khi gần cuối list (`NotificationListener<ScrollNotification>`, xem `pagination_demo_page.dart`); footer spinner đọc `notifier.isLoadingMore`.

## Cache sau khi rời màn

Gọi `ref.cacheFor(const Duration(minutes: 2));` đầu `build()` của provider autoDispose — giữ data thêm 2 phút sau khi không còn ai nghe.

## Page

```dart
@RoutePage()
class VoucherListPage extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(voucherProvider);
    final notifier = ref.read(voucherProvider.notifier);
    return AppScaffold(
      appBar: AppBar(title: const Text('Voucher')),
      body: AsyncView<List<VoucherModel>>(
        state: state,
        notifier: notifier,          // bỏ nếu trang chỉ đọc, không có mutation
        onRetry: notifier.refresh,
        onRefresh: notifier.refresh, // bật pull-to-refresh
        emptyTitle: 'Không có voucher nào',
        builder: (context, list) => _VoucherList(list, onDelete: notifier.delete),
      ),
    );
  }
}
```
`AsyncView` (lib/shared/states/) = render loading/empty/error/data + thanh refresh + `RefreshIndicator` (khi có `onRefresh`) + toast từ `notifier.messages` (khi truyền `notifier`). Tham số thêm: `isEmpty`, `emptyMessage`, `showRefreshBar`.

Cần toast mà không dùng AsyncView: gọi hook `useRunMessages(notifier)` (lib/core/riverpod/use_run_messages.dart) — chỉ màn trên cùng mới toast, tránh nhiều màn cùng nghe 1 notifier keepAlive bắn trùng.

Widget dùng hook → `HookConsumerWidget`; không hook → `ConsumerWidget`. `ref.watch` trong `build`, `ref.read(...notifier)` cho callback.

## Provider sinh sẵn từ api_client

GET → `ref.watch(getUsersProvider(page: 1, limit: 20))`; ghi → `ref.read(usersActionsProvider.notifier).deleteUsersId(id: id)` (ném lỗi, xong tự invalidate GET cùng nhóm). Màn đơn giản dùng thẳng (`_reference/generated_api`); cần toast chung/optimistic thì đặt lời gọi Actions vào `run(...)` của notifier. Chi tiết ở skill `network-error`.

## Trạng thái đăng nhập

- `sessionProvider` (lib/core/services/session_notifier.dart): state `bool` (có access token). `await ref.read(sessionProvider.notifier).ready` trước khi đọc lúc cold start. `login(access, [refresh])` ghi token, `logout()` xoá token.
- `authProvider` (features/auth, `BaseNotifier<User?>` — `User` của `api_client`, keepAlive): gọi backend qua `ref.apiClient.auth` — `login`, `register`, `refreshMe` (`GET /auth/me`), `logout` (thu hồi phiên server + xoá token). Đăng nhập xong lưu token qua `sessionProvider.notifier.login(...)`.
- `app.dart` lắng nghe `sessionProvider`: `true → false` thì về `LoginRoute`.

