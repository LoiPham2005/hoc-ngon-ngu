// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'request_email_change_request.freezed.dart';
part 'request_email_change_request.g.dart';

@Freezed()
abstract class RequestEmailChangeRequest with _$RequestEmailChangeRequest {
  const factory RequestEmailChangeRequest({
    required String newEmail,
    required String password,
  }) = _RequestEmailChangeRequest;

  factory RequestEmailChangeRequest.fromJson(Map<String, Object?> json) =>
      _$RequestEmailChangeRequestFromJson(json);
}
