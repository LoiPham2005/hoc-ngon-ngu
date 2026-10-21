// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'passkeys_list_response_data.dart';

part 'passkeys_list_response.freezed.dart';
part 'passkeys_list_response.g.dart';

@Freezed()
abstract class PasskeysListResponse with _$PasskeysListResponse {
  const factory PasskeysListResponse({
    required PasskeysListResponseData data,
  }) = _PasskeysListResponse;

  factory PasskeysListResponse.fromJson(Map<String, Object?> json) =>
      _$PasskeysListResponseFromJson(json);
}
