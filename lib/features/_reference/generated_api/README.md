# Mẫu dùng provider sinh sẵn bởi `make gen-api`

`make gen-api` (hoặc `make gen-api-server`) sinh luôn provider Riverpod vào
`packages/api_client/lib/src/providers/`, export qua `package:api_client/api_client.dart`.
Không sửa tay — chạy lại là bị ghi đè.
Bảng mọi endpoint (tên provider, tham số, kiểu trả về): `packages/api_client/API_USAGE.md`.

| API | Sinh ra | Dùng |
| --- | --- | --- |
| `GET`  | `getXxxProvider(...)` (family theo tham số, autoDispose) | `ref.watch(getUsersProvider(page: 1))` |
| `POST/PUT/PATCH/DELETE` | `<Nhóm>Actions` (keepAlive) | `await ref.read(usersActionsProvider.notifier).deleteUsersId(id: id)` |

- Ghi thành công → tự `invalidate` mọi provider GET cùng nhóm (danh sách tự tải lại).
- Ghi lỗi → **ném lỗi** ra nơi gọi; `ref.watch(usersActionsProvider)` cho biết đang chạy / lỗi.
- App nối Dio một lần: `apiClientOverrides` trong `core/network/api_client_provider.dart`, đã gắn ở
  `main.dart` và `test/helpers/pump_app.dart`.

## Cách 1 — dùng thẳng trong widget (màn đơn giản)

Xem [generated_user_list_page.dart](generated_user_list_page.dart): danh sách có phân trang,
dialog chi tiết, khoá/mở khoá, xoá — không viết notifier nào.

## Cách 2 — bọc trong notifier của feature (cần toast chung, cập nhật lạc quan, gộp API...)

Actions ném lỗi nên ghép thẳng vào `run` của `BaseNotifier`:

```dart
Future<void> delete(String id) => run(
  () => ref.read(usersActionsProvider.notifier).deleteUsersId(id: id),
  apply: (list, _) => list.where((u) => u.id != id).toList(),
  successMessage: 'Đã xoá người dùng',
);
```

Đọc dữ liệu trong notifier: `await ref.watch(getUsersIdProvider(id: id).future)`.
Mẫu notifier đầy đủ (cuộn vô hạn, BaseNotifier) xem `_reference/openapi_user`.
