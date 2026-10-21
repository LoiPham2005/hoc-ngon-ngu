// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'register_device_request_platform_platform.dart';

part 'register_device_request.freezed.dart';
part 'register_device_request.g.dart';

@Freezed()
abstract class RegisterDeviceRequest with _$RegisterDeviceRequest {
  const factory RegisterDeviceRequest({
    required RegisterDeviceRequestPlatformPlatform platform,
    required String fcmToken,
    String? deviceId,
    String? deviceName,
  }) = _RegisterDeviceRequest;

  factory RegisterDeviceRequest.fromJson(Map<String, Object?> json) =>
      _$RegisterDeviceRequestFromJson(json);
}
