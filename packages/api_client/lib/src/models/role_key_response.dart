// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'role_key_response_data.dart';

part 'role_key_response.freezed.dart';
part 'role_key_response.g.dart';

@Freezed()
abstract class RoleKeyResponse with _$RoleKeyResponse {
  const factory RoleKeyResponse({
    required RoleKeyResponseData data,
  }) = _RoleKeyResponse;

  factory RoleKeyResponse.fromJson(Map<String, Object?> json) =>
      _$RoleKeyResponseFromJson(json);
}
