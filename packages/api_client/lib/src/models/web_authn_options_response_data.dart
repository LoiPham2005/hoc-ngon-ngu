// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'web_authn_options_response_data.freezed.dart';
part 'web_authn_options_response_data.g.dart';

@Freezed()
abstract class WebAuthnOptionsResponseData with _$WebAuthnOptionsResponseData {
  const factory WebAuthnOptionsResponseData({
    required Map<String, dynamic> options,
    required String challengeToken,
  }) = _WebAuthnOptionsResponseData;

  factory WebAuthnOptionsResponseData.fromJson(Map<String, Object?> json) =>
      _$WebAuthnOptionsResponseDataFromJson(json);
}
