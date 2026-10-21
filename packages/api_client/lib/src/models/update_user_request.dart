// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'update_user_request_status_status.dart';

part 'update_user_request.freezed.dart';
part 'update_user_request.g.dart';

@Freezed()
abstract class UpdateUserRequest with _$UpdateUserRequest {
  const factory UpdateUserRequest({
    String? email,
    String? phone,
    String? username,
    String? fullName,
    UpdateUserRequestStatusStatus? status,
    List<String>? roleKeys,
    String? avatarFileId,
  }) = _UpdateUserRequest;

  factory UpdateUserRequest.fromJson(Map<String, Object?> json) =>
      _$UpdateUserRequestFromJson(json);
}
