// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'passkey.dart';

part 'passkeys_list_response_data.freezed.dart';
part 'passkeys_list_response_data.g.dart';

@Freezed()
abstract class PasskeysListResponseData with _$PasskeysListResponseData {
  const factory PasskeysListResponseData({
    required List<Passkey> passkeys,
    required bool available,
  }) = _PasskeysListResponseData;

  factory PasskeysListResponseData.fromJson(Map<String, Object?> json) =>
      _$PasskeysListResponseDataFromJson(json);
}
