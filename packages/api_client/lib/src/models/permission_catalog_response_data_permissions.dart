// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'permission_catalog_response_data_permissions.freezed.dart';
part 'permission_catalog_response_data_permissions.g.dart';

@Freezed()
abstract class PermissionCatalogResponseDataPermissions
    with _$PermissionCatalogResponseDataPermissions {
  const factory PermissionCatalogResponseDataPermissions({
    required String key,
    required String name,
    required String category,
    required String description,
  }) = _PermissionCatalogResponseDataPermissions;

  factory PermissionCatalogResponseDataPermissions.fromJson(
    Map<String, Object?> json,
  ) => _$PermissionCatalogResponseDataPermissionsFromJson(json);
}
