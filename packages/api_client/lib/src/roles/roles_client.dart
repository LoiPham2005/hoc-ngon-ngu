// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart' hide Headers;
import 'package:retrofit/retrofit.dart';
import 'package:retrofit/error_logger.dart';

import '../models/create_role_request.dart';
import '../models/permission_catalog_response.dart';
import '../models/role_key_response.dart';
import '../models/role_response.dart';
import '../models/roles_list_response.dart';
import '../models/update_role_request.dart';

part 'roles_client.g.dart';

@RestApi()
abstract class RolesClient {
  factory RolesClient(Dio dio, {String? baseUrl}) = _RolesClient;

  /// Danh mục quyền TỒN TẠI. Đến từ CODE (src/lib/permissions.ts), không phải database — database chỉ giữ việc GÁN quyền cho vai trò.
  ///
  /// Name not received - field will be skipped.
  @GET('/permissions')
  Future<PermissionCatalogResponse> getPermissions();

  /// Danh sách vai trò kèm bảng phân quyền, VÀ danh mục quyền tồn tại. Danh mục đến từ code (src/lib/permissions.ts), không phải database.
  ///
  /// Name not received - field will be skipped.
  @GET('/roles')
  Future<RolesListResponse> getRoles();

  /// Tạo vai trò mới — key không đổi được sau khi tạo.
  ///
  /// [body] - Name not received - field will be skipped.
  ///
  /// Name not received - field will be skipped.
  @POST('/roles')
  Future<RoleResponse> postRoles({
    @Body() required CreateRoleRequest body,
  });

  /// Chi tiết một vai trò.
  ///
  /// Name not received - field will be skipped.
  @GET('/roles/{key}')
  Future<RoleResponse> getRolesKey({
    @Path('key') required String key,
  });

  /// Đổi tên/mô tả và/hoặc thay TOÀN BỘ danh sách quyền. `permissions` là thay thế, không phải thêm vào — gửi thiếu là gỡ mất.
  ///
  /// [body] - Name not received - field will be skipped.
  ///
  /// Name not received - field will be skipped.
  @PATCH('/roles/{key}')
  Future<RoleResponse> patchRolesKey({
    @Path('key') required String key,
    @Body() required UpdateRoleRequest body,
  });

  /// Xoá vai trò — không xoá được vai trò hệ thống hoặc vai trò còn người dùng.
  ///
  /// Name not received - field will be skipped.
  @DELETE('/roles/{key}')
  Future<RoleKeyResponse> deleteRolesKey({
    @Path('key') required String key,
  });
}
