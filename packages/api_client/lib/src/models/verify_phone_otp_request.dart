// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'verify_phone_otp_request.freezed.dart';
part 'verify_phone_otp_request.g.dart';

@Freezed()
abstract class VerifyPhoneOtpRequest with _$VerifyPhoneOtpRequest {
  const factory VerifyPhoneOtpRequest({
    required String code,
  }) = _VerifyPhoneOtpRequest;

  factory VerifyPhoneOtpRequest.fromJson(Map<String, Object?> json) =>
      _$VerifyPhoneOtpRequestFromJson(json);
}
