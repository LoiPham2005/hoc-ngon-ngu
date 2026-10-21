// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'verify_two_factor_request.freezed.dart';
part 'verify_two_factor_request.g.dart';

@Freezed()
abstract class VerifyTwoFactorRequest with _$VerifyTwoFactorRequest {
  const factory VerifyTwoFactorRequest({
    required String challengeToken,
    required String code,
  }) = _VerifyTwoFactorRequest;

  factory VerifyTwoFactorRequest.fromJson(Map<String, Object?> json) =>
      _$VerifyTwoFactorRequestFromJson(json);
}
