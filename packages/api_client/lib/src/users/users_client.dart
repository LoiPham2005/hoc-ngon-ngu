// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart' hide Headers;
import 'package:retrofit/retrofit.dart';
import 'package:retrofit/error_logger.dart';

import '../models/assign_roles_request.dart';
import '../models/create_user_request.dart';
import '../models/id_response.dart';
import '../models/set_user_permission_request.dart';
import '../models/status.dart';
import '../models/update_user_request.dart';
import '../models/update_user_status_request.dart';
import '../models/user_permissions_response.dart';
import '../models/user_response.dart';
import '../models/users_list_response.dart';

part 'users_client.g.dart';

@RestApi()
abstract class UsersClient {
  factory UsersClient(Dio dio, {String? baseUrl}) = _UsersClient;

  /// THAY TOÀN BỘ danh sách vai trò (PUT, không phải PATCH) — gửi thiếu là gỡ mất.
  ///
  /// [body] - Name not received - field will be skipped.
  ///
  /// Name not received - field will be skipped.
  @PUT('/users/{id}/roles')
  Future<UserResponse> putUsersIdRoles({
    @Path('id') required String id,
    @Body() required AssignRolesRequest body,
  });

  /// Quyền của một người, kèm NGUỒN: vai trò nào cấp, hay ngoại lệ riêng.
  ///
  /// Name not received - field will be skipped.
  @GET('/users/{id}/permissions')
  Future<UserPermissionsResponse> getUsersIdPermissions({
    @Path('id') required String id,
  });

  /// Ngoại lệ quyền cho TỪNG người, đè lên vai trò. Thứ tự: hợp vai trò → cộng phần cấp thêm → TRỪ phần bị tước. Cấm luôn thắng.
  ///
  /// [body] - Name not received - field will be skipped.
  ///
  /// Name not received - field will be skipped.
  @PUT('/users/{id}/permissions')
  Future<UserPermissionsResponse> putUsersIdPermissions({
    @Path('id') required String id,
    @Body() required SetUserPermissionRequest body,
  });

  /// Gỡ ngoại lệ, trả người dùng về đúng quyền của vai trò họ đang mang.
  ///
  /// Name not received - field will be skipped.
  @DELETE('/users/{id}/permissions/{permissionKey}')
  Future<UserPermissionsResponse> deleteUsersIdPermissionsPermissionKey({
    @Path('id') required String id,
    @Path('permissionKey') required String permissionKey,
  });

  /// Danh sách user — phân trang theo số trang, kèm tổng số bản ghi.
  ///
  /// [q] - Tìm theo email / username / số điện thoại / họ tên.
  ///
  /// Name not received - field will be skipped.
  @GET('/users')
  Future<UsersListResponse> getUsers({
    @Query('q') String? q,
    @Query('status') Status? status,
    @Query('roleKey') String? roleKey,
    @Query('page') int? page = 1,
    @Query('limit') int? limit = 20,
  });

  /// Admin tạo user mới, được phép chỉ định vai trò.
  ///
  /// [body] - Name not received - field will be skipped.
  ///
  /// Name not received - field will be skipped.
  @POST('/users')
  Future<UserResponse> postUsers({
    @Body() required CreateUserRequest body,
  });

  /// Xem 1 user — chính mình cần profile:read:own, xem người khác cần user:read.
  ///
  /// Name not received - field will be skipped.
  @GET('/users/{id}')
  Future<UserResponse> getUsersId({
    @Path('id') required String id,
  });

  /// Sửa hồ sơ — chính mình cần profile:update:own, sửa người khác cần user:update. Riêng roleKeys LUÔN đòi user:update, kể cả khi đang sửa chính mình.
  ///
  /// [body] - Name not received - field will be skipped.
  ///
  /// Name not received - field will be skipped.
  @PATCH('/users/{id}')
  Future<UserResponse> patchUsersId({
    @Path('id') required String id,
    @Body() required UpdateUserRequest body,
  });

  /// Xoá mềm user — không tự xoá được chính mình.
  ///
  /// Name not received - field will be skipped.
  @DELETE('/users/{id}')
  Future<IdResponse> deleteUsersId({
    @Path('id') required String id,
  });

  /// Khoá/mở khoá tài khoản — không tự khoá được chính mình.
  ///
  /// [body] - Name not received - field will be skipped.
  ///
  /// Name not received - field will be skipped.
  @PATCH('/users/{id}/status')
  Future<UserResponse> patchUsersIdStatus({
    @Path('id') required String id,
    @Body() required UpdateUserStatusRequest body,
  });

  /// Mở khoá sớm — xoá lockedUntil do sai mật khẩu liên tiếp, thay vì đợi hết hạn.
  ///
  /// Name not received - field will be skipped.
  @POST('/users/{id}/unlock')
  Future<UserResponse> postUsersIdUnlock({
    @Path('id') required String id,
  });
}
