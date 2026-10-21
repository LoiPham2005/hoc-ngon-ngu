// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'roles_list_response_data_permissions.freezed.dart';
part 'roles_list_response_data_permissions.g.dart';

@Freezed()
abstract class RolesListResponseDataPermissions
    with _$RolesListResponseDataPermissions {
  const factory RolesListResponseDataPermissions({
    required String key,
    required String description,
  }) = _RolesListResponseDataPermissions;

  factory RolesListResponseDataPermissions.fromJson(
    Map<String, Object?> json,
  ) => _$RolesListResponseDataPermissionsFromJson(json);
}
