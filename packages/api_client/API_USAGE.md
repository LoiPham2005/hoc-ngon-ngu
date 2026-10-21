# api_client — cách gọi API

> SINH TỰ ĐỘNG bởi `gen_api.dart` (`make gen-api`) — đừng sửa tay, chạy lại là bị ghi đè.
> Tên method / tham số / kiểu trả về dưới đây khớp đúng code sinh ra: tra ở đây, không cần mở `lib/src`.

```dart
import 'package:api_client/api_client.dart';
```

## 1. Gọi thẳng Retrofit (không cần Riverpod — Bloc, GetX, StatefulWidget... đều dùng được)

```dart
final api = RestClient(dio); // Dio của app: base URL, token, interceptor
final res = await api.users.getUsers(page: 1, limit: 20);
```

Lỗi HTTP ném `DioException`. Kiểu trả về là model Freezed, đã giải mã sẵn.

## 2. Riverpod (provider sinh sẵn trong `lib/src/providers/`)

**Nối Dio một lần** ở ProviderContainer/ProviderScope gốc (thiếu là báo `UnimplementedError`):

```dart
overrides: [restClientProvider.overrideWith((ref) => RestClient(ref.read(dioProvider)))]
```

**Đọc (GET)** — mỗi endpoint một provider `get...Provider`, family theo tham số, autoDispose:

```dart
final users = ref.watch(getUsersProvider(page: 1, limit: 20)); // AsyncValue<UsersListResponse>
ref.invalidate(getUsersProvider);                                // tải lại mọi trang
final user = await ref.read(getUsersIdProvider(id: id).future);  // lấy 1 lần trong code
```

**Ghi (POST/PUT/PATCH/DELETE)** — mỗi nhóm một `<Nhóm>Actions` (keepAlive):

```dart
await ref.read(usersActionsProvider.notifier).deleteUsersId(id: id);
final busy = ref.watch(usersActionsProvider).isLoading; // đang ghi?
```

- Thành công → tự `invalidate` mọi provider GET **cùng nhóm** (danh sách tự tải lại).
- Lỗi → **ném lại** cho nơi gọi (bắt bằng try/catch, hoặc bọc trong `runMutation` của notifier app).

```dart
// Trong notifier có BaseNotifier (toast tự động, cập nhật lạc quan):
Future<void> delete(String id) => runMutation(
  action: () => ref.read(usersActionsProvider.notifier).deleteUsersId(id: id),
  successMessage: 'Đã xoá',
);
```

## 3. Danh sách endpoint

Tham số ghi đúng chữ ký Dart (`required` = bắt buộc, `= x` = mặc định). Retrofit: `api.<nhóm>.<method>(...)`.

### `audit` — `api.audit`

| HTTP | Path | Mô tả | Method | Tham số | Trả về | Riverpod |
|---|---|---|---|---|---|---|
| GET | `/audit-logs` | Nhật ký thao tác. Chỉ ĐỌC — không có đường ghi, sửa hay xoá qua HTTP. | `getAuditLogs` | `{String? actorId, String? action, String? entity, String? entityId, DateTime? from, DateTime? to, int? page = 1, int? limit = 20}` | `AuditLogsListResponse` | `getAuditLogsProvider` |

### `auth` — `api.auth` · ghi: `authActionsProvider.notifier`

| HTTP | Path | Mô tả | Method | Tham số | Trả về | Riverpod |
|---|---|---|---|---|---|---|
| POST | `/auth/login` | Đăng nhập — trả về token, HOẶC vé 2FA nếu tài khoản đã bật. | `postAuthLogin` | `{required LoginRequest body}` | `AuthLoginResponse` | `Actions.postAuthLogin` |
| POST | `/auth/register` | Tạo tài khoản mới — luôn gán vai trò USER. | `postAuthRegister` | `{required RegisterRequest body}` | `TokenResponse` | `Actions.postAuthRegister` |
| POST | `/auth/refresh` | Đổi refresh token lấy access token mới. | `postAuthRefresh` | `{required RefreshRequest body}` | `TokenResponse` | `Actions.postAuthRefresh` |
| POST | `/auth/logout` | Thu hồi refresh token hiện tại. | `postAuthLogout` |  | `EmptyResponse` | `Actions.postAuthLogout` |
| GET | `/auth/me` | Hồ sơ user đang đăng nhập — luôn đọc lại từ database, không tin token. | `getAuthMe` |  | `UserResponse` | `getAuthMeProvider` |
| POST | `/auth/change-password` | Đổi mật khẩu khi đang đăng nhập — thu hồi mọi phiên khác. | `postAuthChangePassword` | `{required ChangePasswordRequest body}` | `EmptyResponse` | `Actions.postAuthChangePassword` |
| POST | `/auth/forgot-password` | Gửi link đặt lại mật khẩu — LUÔN trả 200 dù email có tồn tại hay không. | `postAuthForgotPassword` | `{required ForgotPasswordRequest body}` | `EmptyResponse` | `Actions.postAuthForgotPassword` |
| POST | `/auth/reset-password` | Đặt lại mật khẩu bằng token trong email. | `postAuthResetPassword` | `{required ResetPasswordRequest body}` | `EmptyResponse` | `Actions.postAuthResetPassword` |
| POST | `/auth/verify-email` | Xác thực email bằng token trong link. | `postAuthVerifyEmail` | `{required VerifyEmailRequest body}` | `UserResponse` | `Actions.postAuthVerifyEmail` |
| POST | `/auth/verify-email/request` | Gửi lại email xác thực. | `postAuthVerifyEmailRequest` |  | `EmptyResponse` | `Actions.postAuthVerifyEmailRequest` |
| POST | `/auth/change-email` | Xin đổi email — gửi link xác nhận tới địa chỉ MỚI. Email chỉ đổi thật khi link được bấm; đổi ngay thì gõ nhầm một ký tự là mất đường đăng nhập. | `postAuthChangeEmail` | `{required RequestEmailChangeRequest body}` | `EmptyResponse` | `Actions.postAuthChangeEmail` |
| POST | `/auth/change-email/confirm` | Xác nhận đổi email bằng token trong link (KHÔNG cần đăng nhập). | `postAuthChangeEmailConfirm` | `{required ConfirmEmailChangeRequest body}` | `UserResponse` | `Actions.postAuthChangeEmailConfirm` |
| POST | `/auth/phone/request-otp` | Gửi OTP xác thực số điện thoại. ⚠️ MẶC ĐỊNH TẮT (PHONE_VERIFICATION_ENABLED=0) vì mỗi SMS tốn tiền thật. | `postAuthPhoneRequestOtp` | `{required RequestPhoneOtpRequest body}` | `EmptyResponse` | `Actions.postAuthPhoneRequestOtp` |
| POST | `/auth/phone/verify` | Xác nhận OTP số điện thoại. | `postAuthPhoneVerify` | `{required VerifyPhoneOtpRequest body}` | `UserResponse` | `Actions.postAuthPhoneVerify` |
| GET | `/auth/sessions` | Thiết bị đang đăng nhập — CHỈ của chính mình. Response không tự đánh dấu phiên hiện tại: client đối chiếu với `sessionId` nhận được lúc đăng nhập/refresh (access token không mang thông tin đó). | `getAuthSessions` |  | `SessionsResponse` | `getAuthSessionsProvider` |
| DELETE | `/auth/sessions` | Đăng xuất MỌI thiết bị khác. Giữ lại phiên hiện tại (nhận ra qua `sid` trong access token) — đăng xuất luôn người đang bấm nút thì họ phải đăng nhập lại ngay. | `deleteAuthSessions` |  | `EmptyResponse` | `Actions.deleteAuthSessions` |
| DELETE | `/auth/sessions/{id}` | Đăng xuất một thiết bị. Trả 404 cho cả phiên không tồn tại lẫn phiên của người khác — phân biệt hai ca đó là xác nhận id có thật. | `deleteAuthSessionsId` | `{required String id}` | `IdResponse` | `Actions.deleteAuthSessionsId` |

### `devices` — `api.devices` · ghi: `devicesActionsProvider.notifier`

| HTTP | Path | Mô tả | Method | Tham số | Trả về | Riverpod |
|---|---|---|---|---|---|---|
| GET | `/devices` | Thiết bị đang nhận push. | `getDevices` |  | `DevicesListResponse` | `getDevicesProvider` |
| POST | `/devices` | Đăng ký thiết bị nhận push. `fcmToken` UNIQUE toàn bảng: cùng một máy có thể được hai người đăng nhập lần lượt và FCM cấp lại đúng token đó. | `postDevices` | `{required RegisterDeviceRequest body}` | `EmptyResponse` | `Actions.postDevices` |
| DELETE | `/devices` | Gỡ thiết bị khỏi danh sách nhận push — gọi lúc đăng xuất trên máy đó. | `deleteDevices` |  | `EmptyResponse` | `Actions.deleteDevices` |

### `fa` — `api.fa` · ghi: `faActionsProvider.notifier`

| HTTP | Path | Mô tả | Method | Tham số | Trả về | Riverpod |
|---|---|---|---|---|---|---|
| GET | `/auth/2fa` | Trạng thái 2FA của tài khoản hiện tại. | `getAuth2fa` |  | `TwoFactorStatusResponse` | `getAuth2faProvider` |
| DELETE | `/auth/2fa` | Tắt 2FA — cần mật khẩu và một mã hợp lệ. | `deleteAuth2fa` | `{required DisableTwoFactorRequest body}` | `EmptyResponse` | `Actions.deleteAuth2fa` |
| POST | `/auth/2fa/setup` | Bước 1 — sinh bí mật và URI cho mã QR (CHƯA bật). | `postAuth2faSetup` |  | `TwoFactorSetupResponse` | `Actions.postAuth2faSetup` |
| POST | `/auth/2fa/enable` | Bước 3 — xác nhận mã và bật 2FA, trả về mã khôi phục (chỉ hiện MỘT lần). | `postAuth2faEnable` | `{required ConfirmTwoFactorRequest body}` | `RecoveryCodesResponse` | `Actions.postAuth2faEnable` |
| POST | `/auth/2fa/recovery-codes` | Cấp lại bộ mã khôi phục — mã cũ mất hiệu lực ngay. | `postAuth2faRecoveryCodes` | `{required ConfirmTwoFactorRequest body}` | `RecoveryCodesResponse` | `Actions.postAuth2faRecoveryCodes` |
| POST | `/auth/2fa/verify` | Đổi vé 2FA + mã lấy token thật (KHÔNG cần access token). | `postAuth2faVerify` | `{required VerifyTwoFactorRequest body}` | `TokenResponse` | `Actions.postAuth2faVerify` |

### `files` — `api.files` · ghi: `filesActionsProvider.notifier`

| HTTP | Path | Mô tả | Method | Tham số | Trả về | Riverpod |
|---|---|---|---|---|---|---|
| GET | `/files` | Danh sách tệp — người thường (file:upload) chỉ thấy tệp CỦA MÌNH, file:manage thấy tất cả. | `getFiles` | `{Kind? kind, String? q, Attached? attached, String? uploadedById, int? page = 1, int? limit = 20}` | `FilesListResponse` | `getFilesProvider` |
| POST | `/files` |  | `postFiles` | `{required MultipartFile file, String? folder, Enum0? retain}` | `FileResponse` | `Actions.postFiles` |
| POST | `/files/uploads` | Tải TRỰC TIẾP lên kho (video, tệp lớn): nhận URL ký sẵn -> client PUT nội dung kèm đúng `upload.headers` -> gọi POST /files/{id}/complete. Chỉ có khi kho là S3 (409 nếu không). | `postFilesUploads` | `{required CreateUploadRequest body}` | `DirectUploadResponse` | `Actions.postFilesUploads` |
| GET | `/files/{id}` | Chi tiết tệp — tệp của người khác (không có file:manage) trả 404. | `getFilesId` | `{required String id}` | `FileResponse` | `getFilesIdProvider` |
| PATCH | `/files/{id}` | Đổi TÊN hiển thị. Nội dung không sửa được — tải tệp mới rồi gắn lại. | `patchFilesId` | `{required String id, required RenameFileRequest body}` | `FileResponse` | `Actions.patchFilesId` |
| DELETE | `/files/{id}` | Xoá tệp khỏi kho. Tệp đang được dùng (vd. làm avatar) trả 409 — gỡ ra trước. | `deleteFilesId` | `{required String id}` | `IdResponse` | `Actions.deleteFilesId` |
| POST | `/files/{id}/complete` | Xác nhận đã PUT xong (tải trực tiếp). Máy chủ kiểm tệp THẬT trên kho: tồn tại, dung lượng, chữ ký đầu tệp. Không đạt thì xoá luôn và trả 422. | `postFilesIdComplete` | `{required String id}` | `FileResponse` | `Actions.postFilesIdComplete` |

### `notifications` — `api.notifications` · ghi: `notificationsActionsProvider.notifier`

| HTTP | Path | Mô tả | Method | Tham số | Trả về | Riverpod |
|---|---|---|---|---|---|---|
| GET | `/notifications` | Hộp thư của CHÍNH mình — userId lấy từ token, không từ tham số. | `getNotifications` | `{int? page = 1, int? limit = 20, bool? unreadOnly = false}` | `NotificationsListResponse` | `getNotificationsProvider` |
| POST | `/notifications` | Gửi thông báo — cần notification:send. | `postNotifications` | `{required SendNotificationRequest body}` | `EmptyResponse` | `Actions.postNotifications` |
| GET | `/notifications/unread-count` | Số thông báo chưa đọc — cho chấm đỏ trên chuông. | `getNotificationsUnreadCount` |  | `EmptyResponse` | `getNotificationsUnreadCountProvider` |
| POST | `/notifications/read-all` | Đánh dấu đã đọc tất cả. | `postNotificationsReadAll` |  | `EmptyResponse` | `Actions.postNotificationsReadAll` |
| POST | `/notifications/{id}/read` | Đánh dấu đã đọc MỘT thông báo (id là bản ghi người nhận). | `postNotificationsIdRead` | `{required String id}` | `IdResponse` | `Actions.postNotificationsIdRead` |

### `oAuth` — `api.oAuth` · ghi: `oAuthActionsProvider.notifier`

| HTTP | Path | Mô tả | Method | Tham số | Trả về | Riverpod |
|---|---|---|---|---|---|---|
| GET | `/auth/oauth/providers` | Nhà cung cấp ĐÃ cấu hình — màn đăng nhập dùng để biết vẽ nút nào. | `getAuthOauthProviders` |  | `OAuthProvidersResponse` | `getAuthOauthProvidersProvider` |
| GET | `/auth/oauth/linked` | Tài khoản mạng xã hội đã liên kết. | `getAuthOauthLinked` |  | `OAuthLinkedResponse` | `getAuthOauthLinkedProvider` |
| GET | `/auth/oauth/{provider}/start` | Bắt đầu luồng OAuth — trả 302 tới nhà cung cấp. Mở bằng TRÌNH DUYỆT (hoặc Custom Tab / ASWebAuthenticationSession trên mobile), không phải bằng fetch: nhà cung cấp cần một phiên trình duyệt thật. | `getAuthOauthProviderStart` | `{required String provider}` | `void` | `getAuthOauthProviderStartProvider` |
| GET | `/auth/oauth/{provider}/callback` | Nhà cung cấp gọi lại sau khi người dùng đồng ý. Trả 302 về ứng dụng — KHÔNG trả JSON, vì đích đến là thanh địa chỉ của trình duyệt. | `getAuthOauthProviderCallback` | `{required String provider, String? code, String? state, String? error}` | `void` | `getAuthOauthProviderCallbackProvider` |
| POST | `/auth/oauth/{provider}/callback` |  | `postAuthOauthProviderCallback` | `{required String provider, required AuthOauthProviderCallbackRequest body}` | `void` | `Actions.postAuthOauthProviderCallback` |
| DELETE | `/auth/oauth/{provider}` | Gỡ liên kết — từ chối nếu đây là cách đăng nhập cuối cùng. | `deleteAuthOauthProvider` | `{required String provider}` | `EmptyResponse` | `Actions.deleteAuthOauthProvider` |

### `passkeys` — `api.passkeys` · ghi: `passkeysActionsProvider.notifier`

| HTTP | Path | Mô tả | Method | Tham số | Trả về | Riverpod |
|---|---|---|---|---|---|---|
| GET | `/auth/passkeys` | Danh sách passkey của tài khoản hiện tại. | `getAuthPasskeys` |  | `PasskeysListResponse` | `getAuthPasskeysProvider` |
| POST | `/auth/passkeys/register/options` | Bước 1 — tuỳ chọn cho navigator.credentials.create(). | `postAuthPasskeysRegisterOptions` |  | `WebAuthnOptionsResponse` | `Actions.postAuthPasskeysRegisterOptions` |
| POST | `/auth/passkeys/register/verify` | Bước 2 — xác minh và lưu passkey. | `postAuthPasskeysRegisterVerify` | `{required RegisterPasskeyRequest body}` | `PasskeyResponse` | `Actions.postAuthPasskeysRegisterVerify` |
| POST | `/auth/passkeys/login/options` | Bước 1 — tuỳ chọn cho navigator.credentials.get(). KHÔNG nhận tham số: bắt nhập email trước vừa thừa một bước, vừa biến endpoint thành công cụ dò xem email nào đã đăng ký. | `postAuthPasskeysLoginOptions` |  | `WebAuthnOptionsResponse` | `Actions.postAuthPasskeysLoginOptions` |
| POST | `/auth/passkeys/login/verify` | Bước 2 — đăng nhập bằng passkey. Không cần mật khẩu và KHÔNG hỏi thêm 2FA: passkey với userVerification=required đã là hai yếu tố. | `postAuthPasskeysLoginVerify` | `{required LoginPasskeyRequest body}` | `TokenResponse` | `Actions.postAuthPasskeysLoginVerify` |
| PATCH | `/auth/passkeys/{id}` | Đổi tên passkey. | `patchAuthPasskeysId` | `{required String id, required RenamePasskeyRequest body}` | `PasskeyResponse` | `Actions.patchAuthPasskeysId` |
| DELETE | `/auth/passkeys/{id}` | Xoá passkey — từ chối nếu đây là cách đăng nhập CUỐI CÙNG. | `deleteAuthPasskeysId` | `{required String id}` | `IdResponse` | `Actions.deleteAuthPasskeysId` |

### `roles` — `api.roles` · ghi: `rolesActionsProvider.notifier`

| HTTP | Path | Mô tả | Method | Tham số | Trả về | Riverpod |
|---|---|---|---|---|---|---|
| GET | `/permissions` | Danh mục quyền TỒN TẠI. Đến từ CODE (src/lib/permissions.ts), không phải database — database chỉ giữ việc GÁN quyền cho vai trò. | `getPermissions` |  | `PermissionCatalogResponse` | `getPermissionsProvider` |
| GET | `/roles` | Danh sách vai trò kèm bảng phân quyền, VÀ danh mục quyền tồn tại. Danh mục đến từ code (src/lib/permissions.ts), không phải database. | `getRoles` |  | `RolesListResponse` | `getRolesProvider` |
| POST | `/roles` | Tạo vai trò mới — key không đổi được sau khi tạo. | `postRoles` | `{required CreateRoleRequest body}` | `RoleResponse` | `Actions.postRoles` |
| GET | `/roles/{key}` | Chi tiết một vai trò. | `getRolesKey` | `{required String key}` | `RoleResponse` | `getRolesKeyProvider` |
| PATCH | `/roles/{key}` | Đổi tên/mô tả và/hoặc thay TOÀN BỘ danh sách quyền. `permissions` là thay thế, không phải thêm vào — gửi thiếu là gỡ mất. | `patchRolesKey` | `{required String key, required UpdateRoleRequest body}` | `RoleResponse` | `Actions.patchRolesKey` |
| DELETE | `/roles/{key}` | Xoá vai trò — không xoá được vai trò hệ thống hoặc vai trò còn người dùng. | `deleteRolesKey` | `{required String key}` | `RoleKeyResponse` | `Actions.deleteRolesKey` |

### `users` — `api.users` · ghi: `usersActionsProvider.notifier`

| HTTP | Path | Mô tả | Method | Tham số | Trả về | Riverpod |
|---|---|---|---|---|---|---|
| PUT | `/users/{id}/roles` | THAY TOÀN BỘ danh sách vai trò (PUT, không phải PATCH) — gửi thiếu là gỡ mất. | `putUsersIdRoles` | `{required String id, required AssignRolesRequest body}` | `UserResponse` | `Actions.putUsersIdRoles` |
| GET | `/users/{id}/permissions` | Quyền của một người, kèm NGUỒN: vai trò nào cấp, hay ngoại lệ riêng. | `getUsersIdPermissions` | `{required String id}` | `UserPermissionsResponse` | `getUsersIdPermissionsProvider` |
| PUT | `/users/{id}/permissions` | Ngoại lệ quyền cho TỪNG người, đè lên vai trò. Thứ tự: hợp vai trò → cộng phần cấp thêm → TRỪ phần bị tước. Cấm luôn thắng. | `putUsersIdPermissions` | `{required String id, required SetUserPermissionRequest body}` | `UserPermissionsResponse` | `Actions.putUsersIdPermissions` |
| DELETE | `/users/{id}/permissions/{permissionKey}` | Gỡ ngoại lệ, trả người dùng về đúng quyền của vai trò họ đang mang. | `deleteUsersIdPermissionsPermissionKey` | `{required String id, required String permissionKey}` | `UserPermissionsResponse` | `Actions.deleteUsersIdPermissionsPermissionKey` |
| GET | `/users` | Danh sách user — phân trang theo số trang, kèm tổng số bản ghi. | `getUsers` | `{String? q, Status? status, String? roleKey, int? page = 1, int? limit = 20}` | `UsersListResponse` | `getUsersProvider` |
| POST | `/users` | Admin tạo user mới, được phép chỉ định vai trò. | `postUsers` | `{required CreateUserRequest body}` | `UserResponse` | `Actions.postUsers` |
| GET | `/users/{id}` | Xem 1 user — chính mình cần profile:read:own, xem người khác cần user:read. | `getUsersId` | `{required String id}` | `UserResponse` | `getUsersIdProvider` |
| PATCH | `/users/{id}` | Sửa hồ sơ — chính mình cần profile:update:own, sửa người khác cần user:update. Riêng roleKeys LUÔN đòi user:update, kể cả khi đang sửa chính mình. | `patchUsersId` | `{required String id, required UpdateUserRequest body}` | `UserResponse` | `Actions.patchUsersId` |
| DELETE | `/users/{id}` | Xoá mềm user — không tự xoá được chính mình. | `deleteUsersId` | `{required String id}` | `IdResponse` | `Actions.deleteUsersId` |
| PATCH | `/users/{id}/status` | Khoá/mở khoá tài khoản — không tự khoá được chính mình. | `patchUsersIdStatus` | `{required String id, required UpdateUserStatusRequest body}` | `UserResponse` | `Actions.patchUsersIdStatus` |
| POST | `/users/{id}/unlock` | Mở khoá sớm — xoá lockedUntil do sai mật khẩu liên tiếp, thay vì đợi hết hạn. | `postUsersIdUnlock` | `{required String id}` | `UserResponse` | `Actions.postUsersIdUnlock` |

