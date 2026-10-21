---
name: new-feature
description: Quy trình tạo feature/màn hình mới: kiểm tra API đã có trong packages/api_client chưa (có → dùng thẳng, không viết model/service; chưa có → tự viết model freezed + service Retrofit theo mẫu voucher) → notifier BaseNotifier → page AsyncView → route → make gen → test và checklist review code theo chuẩn lingua. Dùng khi user nói "tạo feature/màn hình mới", bắt đầu một phần nghiệp vụ mới, hoặc nhờ "review code / kiểm tra có đúng pattern không".
---

# Tạo feature mới & review

Không có scaffold tự động — copy tay từ mẫu. Chọn mẫu:
| Trường hợp | Mẫu |
|---|---|
| List/CRUD gọi service Retrofit tự viết | `_reference/voucher` |
| List phân trang (load more) | `_reference/pagination_demo` |
| Endpoint đã có trong `packages/api_client` (OpenAPI), cần notifier | `_reference/openapi_user` |
| Màn đơn giản, dùng thẳng provider sinh sẵn | `_reference/generated_api` |

## Các bước (ví dụ feature `product`)

0. **Kiểm tra API đã có sẵn chưa** — tìm trong `packages/api_client` (`API_USAGE.md` hoặc `grep -rn "/products" packages/api_client/lib/src`). Thiếu endpoint mới thêm ở backend → chạy `make gen-api` trước.
   - **Đã có** → KHÔNG viết model/service: dùng thẳng client (`ref.apiClient.products.getProducts(...)`) + model sinh sẵn của nó. Bỏ bước 2–3. Mẫu `_reference/openapi_user`.
   - **Chưa có** (API ngoài, backend khác không có OpenAPI…) → viết tay model + service như bước 2–3. Mẫu `_reference/voucher`.

1. **Thư mục** — page để thẳng ở gốc feature; thư mục con theo vai trò. `models/` + `services/` CHỈ tạo khi API chưa có trong api_client.
   ```
   # API có sẵn trong api_client          # API chưa có → tự viết
   lib/features/product/                  lib/features/product/
     product_list_page.dart                 product_list_page.dart
     providers/product_notifier.dart        models/product_model.dart
                                            services/product_service.dart
                                            providers/product_notifier.dart
   ```
   Màn không cần notifier (dùng thẳng provider sinh sẵn) → chỉ có file page. Widget con riêng của page → `widgets/`.
2. **Model** (chỉ khi API chưa có) — `@freezed abstract class ProductModel with _$ProductModel`, `fromJson`, `@JsonKey(name: 'snake_case')` khi khác tên. Request body = class `@freezed` riêng.
3. **Service** (chỉ khi API chưa có) — `@RestApi() abstract class ProductService { factory ProductService(Dio dio) = _ProductService; ... }`, trả `Future<ApiResponse<T>>` / `Future<T>` / `Future<void>`.
   Endpoint không cần token (đăng nhập, quên mật khẩu…) → thêm vào `_publicPaths` trong `auth_interceptor.dart` (cả khi dùng api_client).
4. **Notifier**
   ```dart
   part 'product_notifier.g.dart';

   @riverpod
   class ProductNotifier extends _$ProductNotifier
       with BaseNotifier<List<ProductModel>> {
     late ProductService _service;

     @override
     Future<List<ProductModel>> build() async {
       _service = ProductService(ref.dio);
       return _fetch();
     }

     Future<List<ProductModel>> _fetch() async =>
         (await _service.getProducts()).data;
     // Dùng api_client: Future<List<Product>> _fetch() async =>
     //     (await ref.apiClient.products.getProducts()).data.items;

     Future<void> refresh() => run(_fetch);
   }
   ```
   Ghi dữ liệu → `run(action, apply:, successMessage:)`; phân trang → thêm `PaginatedNotifier<E>` (skill `state-management`).
5. **Page**
   ```dart
   @RoutePage()
   class ProductListPage extends HookConsumerWidget {
     const ProductListPage({super.key});

     @override
     Widget build(BuildContext context, WidgetRef ref) {
       final state = ref.watch(productProvider);
       final notifier = ref.read(productProvider.notifier);
       return AppScaffold(
         appBar: AppBar(title: const Text('Sản phẩm')),
         body: AsyncView<List<ProductModel>>(
           state: state,
           notifier: notifier,
           onRetry: notifier.refresh,
           onRefresh: notifier.refresh,
           emptyTitle: 'Chưa có sản phẩm',
           builder: (context, list) => _ProductList(list),
         ),
       );
     }
   }
   ```
6. **Route** — import page vào `lib/routes/app_router.dart`, thêm `AutoRoute(page: ProductListRoute.page, path: '/products')` (+ `guards: _auth` nếu cần đăng nhập). Tab mới → xem skill `routing`.
7. **Sinh code** — `make gen` (thêm chuỗi ARB thì `make l10n`).
8. **Kiểm tra** — `make analyze`; chạy đúng file test liên quan.

## Test

- Widget: `pumpApp(tester, const ProductListPage(), overrides: [...])` (test/helpers/pump_app.dart, đã gắn `apiClientOverrides` + `AppTheme`). Widget có spinner vô hạn → `settle: false`.
- Notifier/logic: `ProviderContainer(overrides: [...])`, `await container.read(provider.future)`; mock bằng `mocktail`. Override được: `dioProvider.overrideWithValue(mockDio)`, `apiClientProvider`, hoặc provider service keepAlive.
- Mẫu: `test/unit/core/riverpod/base_notifier_test.dart`, `test/pagination_demo_notifier_test.dart`, `test/async_view_test.dart`.
- Tên test mới bằng tiếng Anh.

## Checklist review

**Cấu trúc & DI**
- [ ] File đúng chỗ theo skill `architecture`; import `package:lingua/...`, không import tương đối.
- [ ] Service singleton = `@Riverpod(keepAlive: true)` functional cạnh class; không tạo container/locator riêng.
- [ ] Không có `ref` → `globalContainer.read(...)`; có `ref` thì không dùng `globalContainer`.
- [ ] Lưu trữ dùng `sharedPrefsProvider` / `secureStorageProvider`; token chỉ ở secure storage.

**State**
- [ ] Notifier `with BaseNotifier<T>`; mọi thao tác async qua `run` (ghi có `apply` nếu cập nhật list tại chỗ).
- [ ] Không tự `try/catch` gán `state = AsyncError`, không `setState` cho logic async, không BLoC/Cubit/GetX.
- [ ] Search/filter có `cancelPrevious: true`; nút xoá/lưu có `dropIfBusy: true`.
- [ ] Page dùng `AsyncView`, truyền `notifier` khi có mutation.
- [ ] `ref.watch` trong build, `ref.read(...notifier)` trong callback; widget có hook là `HookConsumerWidget`.

**Network & lỗi**
- [ ] Service Retrofit `@RestApi`, body là class `@freezed`, không bọc kiểu kết quả riêng.
- [ ] Lỗi nghiệp vụ `throw ServerFailure(...)`; ngoài notifier dùng `ErrorHandler.handle(e).message`.
- [ ] Không sửa tay `packages/api_client` hay file `*.g.dart`, `*.freezed.dart`, `*.gr.dart`, `lib/gen/`.

**UI**
- [ ] Màu từ `AppColorTokens`/`colorScheme`, khoảng cách `AppDimensions`, chữ `textTheme`; không hard-code.
- [ ] Dùng widget có sẵn (`AppScaffold`, `AppButton`, `AppTextField`, `AppConfirmationDialog`, state widgets) trước khi viết mới.
- [ ] Widget con tách thành class, có `const` constructor khi được.
- [ ] Thông báo qua `toast`, log qua `talker` (không `print`).

**Điều hướng**
- [ ] Page có `@RoutePage()` và đã khai báo trong `AppRouter`; route cần đăng nhập có `guards: _auth`.
- [ ] Điều hướng bằng `context.router` / `appRouter`, không `Navigator.push` cho màn có route.

**Chung**
- [ ] Đã `make gen` sau khi sửa annotation; `make analyze` sạch.
- [ ] Tên mới (class/hàm/biến/file/test) bằng tiếng Anh; chữ hiển thị/comment được tiếng Việt.
- [ ] Không thêm code/dependency "để sẵn" khi chưa dùng; ưu tiên thư viện có sẵn.
