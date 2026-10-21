// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'passkey.dart';

part 'passkey_response_data.freezed.dart';
part 'passkey_response_data.g.dart';

@Freezed()
abstract class PasskeyResponseData with _$PasskeyResponseData {
  const factory PasskeyResponseData({
    required Passkey passkey,
  }) = _PasskeyResponseData;

  factory PasskeyResponseData.fromJson(Map<String, Object?> json) =>
      _$PasskeyResponseDataFromJson(json);
}
