// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'update_user_status_request_status_status.dart';

part 'update_user_status_request.freezed.dart';
part 'update_user_status_request.g.dart';

@Freezed()
abstract class UpdateUserStatusRequest with _$UpdateUserStatusRequest {
  const factory UpdateUserStatusRequest({
    required UpdateUserStatusRequestStatusStatus status,
  }) = _UpdateUserStatusRequest;

  factory UpdateUserStatusRequest.fromJson(Map<String, Object?> json) =>
      _$UpdateUserStatusRequestFromJson(json);
}
