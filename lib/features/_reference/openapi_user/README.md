# Mẫu gọi API sinh từ OpenAPI (Retrofit + Freezed)

Thư mục tham chiếu cho `packages/api_client` (sinh bằng `openapi_retrofit_generator`, chuẩn **Retrofit + Freezed**).

Copy cấu trúc phẳng này cho feature thật, không cần tạo thư mục `data/` hay `presentation/` trung gian.

---

### 📂 Cấu trúc Feature chuẩn khi dùng `api_client`:

```text
lib/features/users/ (hoặc feature bất kỳ)
  ├── user_list_page.dart    👉 Màn hình (AutoRoute @RoutePage) để thẳng ở gốc feature
  ├── user_detail_page.dart
  ├── providers/             👉 Chứa Notifier / State (Riverpod + BaseNotifier)
  │   ├── user_list_notifier.dart
  │   └── user_detail_notifier.dart
  └── widgets/               👉 Component con / UI riêng của feature (nếu có)
      ├── user_card.dart
      └── user_status_badge.dart
```

---

### 🌐 Hạ tầng dùng chung (Đã khai báo sẵn, không cần viết lại):

```text
lib/core/network/
├── dio_provider.dart          ← Dio của app (Interceptor token, retry, base URL)
└── api_client_provider.dart   ← Khai báo Provider cho từng client (authApiProvider, usersApiProvider,...)
```

---

### ⚡ Cách sử dụng trong Provider:

```dart
import 'package:api_client/api_client.dart';
import 'package:lingua/core/network/api_client_provider.dart';
import 'package:lingua/core/riverpod/base_notifier.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_list_notifier.g.dart';

@riverpod
class UserListNotifier extends _$UserListNotifier with BaseNotifier<List<User>> {
  late UsersClient _api;

  @override
  Future<List<User>> build() async {
    _api = ref.read(usersApiProvider);
    final res = await _api.getUsers(perPage: 20);
    return res.data.users;
  }
}
```
