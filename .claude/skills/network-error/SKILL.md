---
name: network-error
description: Tầng mạng và lỗi — dioProvider (AuthInterceptor refresh token + RetryInterceptor của dio_smart_retry + TalkerDioLogger), service Retrofit @RestApi, ApiResponse/PaginatedResponse Failure sealed + ErrorHandler.handle, trạng thái mạng isOnlineProvider + ConnectivityBanner. Đọc khi viết service gọi API, định nghĩa model request/response, xử lý lỗi HTTP, hoặc thêm interceptor.
---

# Network & Error

## Dio

`lib/core/network/dio_provider.dart` — dựng Dio ngay trong provider, `keepAlive`:
- `BaseOptions(baseUrl: FlavorConfig.current.apiBaseUrl)`, timeout 30s, header `Accept: application/json`.
- Interceptor theo thứ tự: `AuthInterceptor(ref.read(secureStorageProvider))` → `RetryInterceptor(dio: dio, retries: 2, logPrint: talker.debug)` (package `dio_smart_retry`) → `TalkerDioLogger` (ẩn request headers).
- Đọc: `ref.dio` hoặc `ref.read(dioProvider)`; ngoài widget tree: `globalContainer.read(dioProvider)`.

Thêm interceptor = thêm vào `dio.interceptors.addAll([...])` trong `dio()`. Ưu tiên interceptor có sẵn của thư viện. Không có lớp bọc Dio, không có HTTP cache, không có interceptor check mạng.

### AuthInterceptor (lib/core/network/auth_interceptor.dart)

- `onRequest`: gắn `Authorization: Bearer <access_token>` (đọc `FlutterSecureStorage`, key `AuthKeys.accessToken`), trừ path trong `_publicPaths` (đăng nhập, đăng ký, refresh, quên/đặt lại mật khẩu, check version).
- `onError` 401 (path không public, chưa retry): token đã được request khác làm mới → gửi lại luôn; ngược lại gọi `POST /auth/refresh` bằng Dio trần (đọc token trong `data`), nhiều request 401 cùng lúc chỉ refresh 1 lần. Thành công → ghi token mới, gửi lại request (`extra['_retried'] = true`). Refresh trả 401/403 hoặc không có refresh token → `logout()` → `app.dart` đưa về Login; lỗi mạng/5xx/429 → giữ phiên, chỉ trả lỗi.
- Endpoint không cần token mới → thêm vào `_publicPaths` trong `auth_interceptor.dart`.

## Service Retrofit

```dart
part 'voucher_service.g.dart';

@RestApi()
abstract class VoucherService {
  factory VoucherService(Dio dio) = _VoucherService;

  @GET('/vouchers')
  Future<ApiResponse<List<VoucherModel>>> getVouchers();

  @GET('/vouchers/{id}')
  Future<ApiResponse<VoucherModel>> getVoucherDetail(@Path('id') String id);

  @GET('/vouchers/search')
  Future<ApiResponse<List<VoucherModel>>> searchVouchers(@Query('q') String query);

  @DELETE('/vouchers/{id}')
  Future<ApiResponse<VoucherModel>> deleteVoucher(@Path('id') String id);
}
```
- Kiểu trả: `Future<ApiResponse<T>>` (backend bọc `{ "data": ... }`), `Future<T>` (backend trả object thô), hoặc `Future<void>`.
- Request body: class `@freezed` riêng (`LoginRequest`, `RegisterRequest`...).
- Path viết thẳng trên annotation Retrofit (`@GET('/items')`), không gom vào file hằng riêng.
- Tạo service: trong `build()` của notifier `VoucherService(ref.dio)`, hoặc provider keepAlive nếu dùng chung: `@Riverpod(keepAlive: true) FooService fooService(Ref ref) => FooService(ref.dio);`.
- Sửa xong `make gen`.

## Model

```dart
@freezed
abstract class VoucherModel with _$VoucherModel {
  const factory VoucherModel({
    required String id,
    required String title,
    String? description,
    @JsonKey(name: 'discount_percent') @Default(0) int discountPercent,
    @JsonKey(name: 'expires_at') DateTime? expiresAt,
  }) = _VoucherModel;

  factory VoucherModel.fromJson(Map<String, dynamic> json) =>
      _$VoucherModelFromJson(json);
}
```

## ApiResponse / PaginatedResponse (lib/core/network/api_response.dart)

Đúng dạng backend:
- `ApiResponse<T>`: chỉ có `data` (json `{ "data": ... }`). Không có `success`/`message` — lỗi đi bằng HTTP 4xx/5xx + `{ "error": { code, message, fields } }`, Dio ném → `ErrorHandler`.
- `PaginatedResponse<T>`: `items` + `meta` (`PageMeta`: `page`, `limit`, `total`, `totalPages`, `hasNext`); getter `hasMore` = `meta.hasNext`. Service: `Future<ApiResponse<PaginatedResponse<T>>>`.
- JSON camelCase, không đổi tên field (build.yaml không bật `field_rename`). Model đọc JSON snake_case (Remote Config) tự khai báo `@JsonSerializable(fieldRename: FieldRename.snake)`.
- Lấy dữ liệu trong notifier: `(await _service.getX()).data`.

## Lỗi

`lib/core/errors/failures.dart` — `sealed class Failure implements Exception` (`message`, `code`, `==` tự viết):
| Class | Khi nào |
|---|---|
| `NetworkFailure` | mất mạng, timeout, `SocketException` |
| `ServerFailure(message, code:)` | HTTP lỗi (≠401), lỗi nghiệp vụ tự ném |
| `UnauthorizedFailure` | 401 |
| `ValidationFailure(message, errors:)` | lỗi field (`Map<String, List<String>>`) |
| `UnknownFailure` | còn lại, request bị huỷ |

`ErrorHandler.handle(Object e) → Failure` (error_handler.dart): giữ nguyên nếu đã là `Failure`; `SocketException` → Network; `DioException` theo `type`; message server lấy từ `data['message'] ?? data['error'] ?? data['errors']` nếu là String.

Dùng:
- Trong notifier: không cần gọi — `run` tự `handle` + log + toast. Chỉ việc `throw ServerFailure('...')` khi gặp lỗi nghiệp vụ.
- Ngoài notifier (gọi Actions sinh sẵn, code tay): `catch (e) { toast.error(ErrorHandler.handle(e).message); }`.
- Switch theo loại: `switch (failure) { case NetworkFailure(): ... }` (sealed → compiler báo thiếu nhánh).
- Log lỗi: `talker.error('msg', e, s)`.

## Kiểm tra mạng

- Toàn app đã có `ConnectivityBanner` (gắn ở `app.dart`): mất mạng hiện thanh đỏ ở đầu màn, có lại hiện "Đã kết nối lại". KHÔNG làm màn "mất mạng" riêng, KHÔNG chặn ở splash.
- Màn gọi API lỗi mạng → `NetworkFailure` → `AsyncView` tự hiện lỗi + nút "Thử lại".
- Cần biết online trong code: `ref.watch(isOnlineProvider).value ?? true` (`core/services/connectivity_provider.dart`).
