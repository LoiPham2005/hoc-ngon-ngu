// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'create_user_request_status_status.dart';

part 'create_user_request.freezed.dart';
part 'create_user_request.g.dart';

@Freezed()
abstract class CreateUserRequest with _$CreateUserRequest {
  const factory CreateUserRequest({
    @Default(CreateUserRequestStatusStatus.active)
    CreateUserRequestStatusStatus status,
    String? email,
    String? phone,
    String? username,
    String? password,
    String? fullName,
    List<String>? roleKeys,
  }) = _CreateUserRequest;

  factory CreateUserRequest.fromJson(Map<String, Object?> json) =>
      _$CreateUserRequestFromJson(json);
}
