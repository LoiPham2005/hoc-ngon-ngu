// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'web_authn_options_response_data.dart';

part 'web_authn_options_response.freezed.dart';
part 'web_authn_options_response.g.dart';

@Freezed()
abstract class WebAuthnOptionsResponse with _$WebAuthnOptionsResponse {
  const factory WebAuthnOptionsResponse({
    required WebAuthnOptionsResponseData data,
  }) = _WebAuthnOptionsResponse;

  factory WebAuthnOptionsResponse.fromJson(Map<String, Object?> json) =>
      _$WebAuthnOptionsResponseFromJson(json);
}
