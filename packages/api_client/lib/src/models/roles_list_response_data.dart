// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'role.dart';
import 'roles_list_response_data_permissions.dart';

part 'roles_list_response_data.freezed.dart';
part 'roles_list_response_data.g.dart';

@Freezed()
abstract class RolesListResponseData with _$RolesListResponseData {
  const factory RolesListResponseData({
    required List<Role> roles,
    required List<RolesListResponseDataPermissions> permissions,
  }) = _RolesListResponseData;

  factory RolesListResponseData.fromJson(Map<String, Object?> json) =>
      _$RolesListResponseDataFromJson(json);
}
