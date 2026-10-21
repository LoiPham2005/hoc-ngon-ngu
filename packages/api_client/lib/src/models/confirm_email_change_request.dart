// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'confirm_email_change_request.freezed.dart';
part 'confirm_email_change_request.g.dart';

@Freezed()
abstract class ConfirmEmailChangeRequest with _$ConfirmEmailChangeRequest {
  const factory ConfirmEmailChangeRequest({
    required String token,
  }) = _ConfirmEmailChangeRequest;

  factory ConfirmEmailChangeRequest.fromJson(Map<String, Object?> json) =>
      _$ConfirmEmailChangeRequestFromJson(json);
}
