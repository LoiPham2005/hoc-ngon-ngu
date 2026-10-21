// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'permission_explanation.dart';

part 'user_permissions_response_data.freezed.dart';
part 'user_permissions_response_data.g.dart';

@Freezed()
abstract class UserPermissionsResponseData with _$UserPermissionsResponseData {
  const factory UserPermissionsResponseData({
    required List<PermissionExplanation> permissions,
  }) = _UserPermissionsResponseData;

  factory UserPermissionsResponseData.fromJson(Map<String, Object?> json) =>
      _$UserPermissionsResponseDataFromJson(json);
}
