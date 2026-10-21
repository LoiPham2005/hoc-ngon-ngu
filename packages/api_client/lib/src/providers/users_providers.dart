// GENERATED CODE - DO NOT MODIFY BY HAND
// Sinh bởi gen_api.dart — chạy lại `make gen-api` là bị ghi đè.
// ignore_for_file: type=lint

import 'dart:async';

import 'package:api_client/api_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'users_providers.g.dart';

/// Quyền của một người, kèm NGUỒN: vai trò nào cấp, hay ngoại lệ riêng.
@riverpod
Future<UserPermissionsResponse> getUsersIdPermissions(
  Ref ref, {
  required String id,
}) => ref.watch(restClientProvider).users.getUsersIdPermissions(id: id);

/// Danh sách user — phân trang theo số trang, kèm tổng số bản ghi.
@riverpod
Future<UsersListResponse> getUsers(
  Ref ref, {
  String? q,
  Status? status,
  String? roleKey,
  int? page = 1,
  int? limit = 20,
}) => ref
    .watch(restClientProvider)
    .users
    .getUsers(q: q, status: status, roleKey: roleKey, page: page, limit: limit);

/// Xem 1 user — chính mình cần profile:read:own, xem người khác cần user:read.
@riverpod
Future<UserResponse> getUsersId(Ref ref, {required String id}) =>
    ref.watch(restClientProvider).users.getUsersId(id: id);

/// Thao tác GHI nhóm `users`. State = đang chạy / lỗi của lần gọi gần nhất; lỗi được NÉM LẠI cho
/// nơi gọi. Thành công thì làm mới mọi provider GET của nhóm.
///
/// `await ref.read(usersActionsProvider.notifier).<method>(...)`
@Riverpod(keepAlive: true)
class UsersActions extends _$UsersActions {
  @override
  FutureOr<void> build() {}

  UsersClient get _api => ref.read(restClientProvider).users;

  Future<R> _run<R>(Future<R> Function() call) async {
    state = const AsyncLoading();
    try {
      final result = await call();
      if (ref.mounted) {
        state = const AsyncData(null);
        ref.invalidate(getUsersIdPermissionsProvider);
        ref.invalidate(getUsersProvider);
        ref.invalidate(getUsersIdProvider);
      }
      return result;
    } catch (e, st) {
      if (ref.mounted) state = AsyncError(e, st);
      rethrow;
    }
  }

  /// THAY TOÀN BỘ danh sách vai trò (PUT, không phải PATCH) — gửi thiếu là gỡ mất.
  Future<UserResponse> putUsersIdRoles({
    required String id,
    required AssignRolesRequest body,
  }) => _run(() => _api.putUsersIdRoles(id: id, body: body));

  /// Ngoại lệ quyền cho TỪNG người, đè lên vai trò. Thứ tự: hợp vai trò → cộng phần cấp thêm → TRỪ phần bị tước. Cấm luôn thắng.
  Future<UserPermissionsResponse> putUsersIdPermissions({
    required String id,
    required SetUserPermissionRequest body,
  }) => _run(() => _api.putUsersIdPermissions(id: id, body: body));

  /// Gỡ ngoại lệ, trả người dùng về đúng quyền của vai trò họ đang mang.
  Future<UserPermissionsResponse> deleteUsersIdPermissionsPermissionKey({
    required String id,
    required String permissionKey,
  }) => _run(
    () => _api.deleteUsersIdPermissionsPermissionKey(
      id: id,
      permissionKey: permissionKey,
    ),
  );

  /// Admin tạo user mới, được phép chỉ định vai trò.
  Future<UserResponse> postUsers({required CreateUserRequest body}) =>
      _run(() => _api.postUsers(body: body));

  /// Sửa hồ sơ — chính mình cần profile:update:own, sửa người khác cần user:update. Riêng roleKeys LUÔN đòi user:update, kể cả khi đang sửa chính mình.
  Future<UserResponse> patchUsersId({
    required String id,
    required UpdateUserRequest body,
  }) => _run(() => _api.patchUsersId(id: id, body: body));

  /// Xoá mềm user — không tự xoá được chính mình.
  Future<IdResponse> deleteUsersId({required String id}) =>
      _run(() => _api.deleteUsersId(id: id));

  /// Khoá/mở khoá tài khoản — không tự khoá được chính mình.
  Future<UserResponse> patchUsersIdStatus({
    required String id,
    required UpdateUserStatusRequest body,
  }) => _run(() => _api.patchUsersIdStatus(id: id, body: body));

  /// Mở khoá sớm — xoá lockedUntil do sai mật khẩu liên tiếp, thay vì đợi hết hạn.
  Future<UserResponse> postUsersIdUnlock({required String id}) =>
      _run(() => _api.postUsersIdUnlock(id: id));
}
