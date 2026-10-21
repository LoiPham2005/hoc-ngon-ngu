// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'request_phone_otp_request.freezed.dart';
part 'request_phone_otp_request.g.dart';

@Freezed()
abstract class RequestPhoneOtpRequest with _$RequestPhoneOtpRequest {
  const factory RequestPhoneOtpRequest({
    required String phone,
  }) = _RequestPhoneOtpRequest;

  factory RequestPhoneOtpRequest.fromJson(Map<String, Object?> json) =>
      _$RequestPhoneOtpRequestFromJson(json);
}
