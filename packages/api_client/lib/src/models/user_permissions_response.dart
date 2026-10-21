// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'user_permissions_response_data.dart';

part 'user_permissions_response.freezed.dart';
part 'user_permissions_response.g.dart';

@Freezed()
abstract class UserPermissionsResponse with _$UserPermissionsResponse {
  const factory UserPermissionsResponse({
    required UserPermissionsResponseData data,
  }) = _UserPermissionsResponse;

  factory UserPermissionsResponse.fromJson(Map<String, Object?> json) =>
      _$UserPermissionsResponseFromJson(json);
}
