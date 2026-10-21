// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'permission_catalog_response_data_permissions.dart';

part 'permission_catalog_response_data.freezed.dart';
part 'permission_catalog_response_data.g.dart';

@Freezed()
abstract class PermissionCatalogResponseData
    with _$PermissionCatalogResponseData {
  const factory PermissionCatalogResponseData({
    required List<PermissionCatalogResponseDataPermissions> permissions,
  }) = _PermissionCatalogResponseData;

  factory PermissionCatalogResponseData.fromJson(Map<String, Object?> json) =>
      _$PermissionCatalogResponseDataFromJson(json);
}
