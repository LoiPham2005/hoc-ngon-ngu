// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'set_user_permission_request.freezed.dart';
part 'set_user_permission_request.g.dart';

@Freezed()
abstract class SetUserPermissionRequest with _$SetUserPermissionRequest {
  const factory SetUserPermissionRequest({
    required String permissionKey,
    required bool isGranted,
    DateTime? expiresAt,
  }) = _SetUserPermissionRequest;

  factory SetUserPermissionRequest.fromJson(Map<String, Object?> json) =>
      _$SetUserPermissionRequestFromJson(json);
}
