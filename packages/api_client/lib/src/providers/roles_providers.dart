// GENERATED CODE - DO NOT MODIFY BY HAND
// Sinh bởi gen_api.dart — chạy lại `make gen-api` là bị ghi đè.
// ignore_for_file: type=lint

import 'dart:async';

import 'package:api_client/api_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'roles_providers.g.dart';

/// Danh mục quyền TỒN TẠI. Đến từ CODE (src/lib/permissions.ts), không phải database — database chỉ giữ việc GÁN quyền cho vai trò.
@riverpod
Future<PermissionCatalogResponse> getPermissions(Ref ref) =>
    ref.watch(restClientProvider).roles.getPermissions();

/// Danh sách vai trò kèm bảng phân quyền, VÀ danh mục quyền tồn tại. Danh mục đến từ code (src/lib/permissions.ts), không phải database.
@riverpod
Future<RolesListResponse> getRoles(Ref ref) =>
    ref.watch(restClientProvider).roles.getRoles();

/// Chi tiết một vai trò.
@riverpod
Future<RoleResponse> getRolesKey(Ref ref, {required String key}) =>
    ref.watch(restClientProvider).roles.getRolesKey(key: key);

/// Thao tác GHI nhóm `roles`. State = đang chạy / lỗi của lần gọi gần nhất; lỗi được NÉM LẠI cho
/// nơi gọi. Thành công thì làm mới mọi provider GET của nhóm.
///
/// `await ref.read(rolesActionsProvider.notifier).<method>(...)`
@Riverpod(keepAlive: true)
class RolesActions extends _$RolesActions {
  @override
  FutureOr<void> build() {}

  RolesClient get _api => ref.read(restClientProvider).roles;

  Future<R> _run<R>(Future<R> Function() call) async {
    state = const AsyncLoading();
    try {
      final result = await call();
      if (ref.mounted) {
        state = const AsyncData(null);
        ref.invalidate(getPermissionsProvider);
        ref.invalidate(getRolesProvider);
        ref.invalidate(getRolesKeyProvider);
      }
      return result;
    } catch (e, st) {
      if (ref.mounted) state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Tạo vai trò mới — key không đổi được sau khi tạo.
  Future<RoleResponse> postRoles({required CreateRoleRequest body}) =>
      _run(() => _api.postRoles(body: body));

  /// Đổi tên/mô tả và/hoặc thay TOÀN BỘ danh sách quyền. `permissions` là thay thế, không phải thêm vào — gửi thiếu là gỡ mất.
  Future<RoleResponse> patchRolesKey({
    required String key,
    required UpdateRoleRequest body,
  }) => _run(() => _api.patchRolesKey(key: key, body: body));

  /// Xoá vai trò — không xoá được vai trò hệ thống hoặc vai trò còn người dùng.
  Future<RoleKeyResponse> deleteRolesKey({required String key}) =>
      _run(() => _api.deleteRolesKey(key: key));
}
