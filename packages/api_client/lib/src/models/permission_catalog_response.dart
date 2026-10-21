// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'permission_catalog_response_data.dart';

part 'permission_catalog_response.freezed.dart';
part 'permission_catalog_response.g.dart';

@Freezed()
abstract class PermissionCatalogResponse with _$PermissionCatalogResponse {
  const factory PermissionCatalogResponse({
    required PermissionCatalogResponseData data,
  }) = _PermissionCatalogResponse;

  factory PermissionCatalogResponse.fromJson(Map<String, Object?> json) =>
      _$PermissionCatalogResponseFromJson(json);
}
