// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'passkey_response_data.dart';

part 'passkey_response.freezed.dart';
part 'passkey_response.g.dart';

@Freezed()
abstract class PasskeyResponse with _$PasskeyResponse {
  const factory PasskeyResponse({
    required PasskeyResponseData data,
  }) = _PasskeyResponse;

  factory PasskeyResponse.fromJson(Map<String, Object?> json) =>
      _$PasskeyResponseFromJson(json);
}
