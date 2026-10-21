import 'package:api_client/api_client.dart';
import 'package:lingua/core/network/api_client_provider.dart';
import 'package:lingua/core/network/api_response.dart';
import 'package:lingua/core/riverpod/base_notifier.dart';
import 'package:lingua/core/riverpod/paginated_notifier.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'openapi_user_notifier.g.dart';

/// Reference Notifier cho client sinh từ OpenAPI — pattern chuẩn để follow theo.
///
/// KHÁC voucher/character ở đúng một chỗ: client OpenAPI (Retrofit) trả THẲNG
/// model đã decode (`Future<UsersListResponse>`), không bọc `ApiResponse` như
/// service Retrofit khác của app → gọi `run` thẳng trên model.
///
/// Phân trang theo **số trang** (`page`/`limit`, backend trả `meta.totalPages`)
/// → dùng [PaginatedNotifier].
///
/// Lỗi HTTP thì client ném `DioException` — `ErrorHandler` của app đã xử lý sẵn,
/// khỏi bắt tay. Field trong response đều `required` (freezed) nên KHÔNG cần
/// null-check thủ công như bản built_value cũ — decode lỗi là ném lỗi ngay tại
/// `fromJson`, không lọt xuống đây dưới dạng `null`.
///
/// `RestClient` đọc qua [apiClientProvider] (tập trung 1 chỗ, giống
/// [dioProvider]) — KHÔNG dựng `RestClient(ref.read(dioProvider))` lại ở đây,
/// vì `RestClient` dùng chung nhiều feature chứ không riêng gì notifier này.
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
      meta: PageMeta(
        page: meta.page,
        limit: meta.limit,
        total: meta.total,
        totalPages: meta.totalPages,
        hasNext: meta.hasNext,
      ),
    );
  }

  /// Mutation mẫu — xoá 1 người dùng.
  ///
  /// `apply` gỡ khỏi list ngay tại chỗ, khỏi gọi lại API danh sách. Lỗi thì
  /// `run` giữ nguyên list cũ và chỉ bắn toast.
  Future<void> delete(String id) => run(
    () => _api.deleteUsersId(id: id),
    apply: (list, _) => list.where((u) => u.id != id).toList(),
    successMessage: 'Đã xoá người dùng',
  );

  /// Mutation có đổi nội dung một phần tử — khoá / mở khoá tài khoản.
  ///
  /// Lưu ý: request dùng enum RIÊNG (`UpdateUserStatusRequestStatusStatus`),
  /// không dùng chung `UserStatusStatus` của model đọc về. OpenAPI sinh mỗi
  /// schema một enum, dù giá trị trùng nhau — nên phải đổi qua lại, không gán
  /// thẳng được.
  Future<void> setStatus(String id, UserStatusStatus hienTai) => run(
    () async => (await _api.patchUsersIdStatus(
      id: id,
      body: UpdateUserStatusRequest(status: _daoTrangThai(hienTai)),
    )).data.user,
    apply: (list, updated) => [
      for (final u in list) u.id == updated.id ? updated : u,
    ],
    successMessage: 'Đã cập nhật trạng thái',
  );

  /// Đang ACTIVE thì khoá, đang BANNED thì mở.
  UpdateUserStatusRequestStatusStatus _daoTrangThai(UserStatusStatus s) =>
      s == UserStatusStatus.active
      ? UpdateUserStatusRequestStatusStatus.banned
      : UpdateUserStatusRequestStatusStatus.active;
}
