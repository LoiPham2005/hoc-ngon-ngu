// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'role_key_response_data.freezed.dart';
part 'role_key_response_data.g.dart';

@Freezed()
abstract class RoleKeyResponseData with _$RoleKeyResponseData {
  const factory RoleKeyResponseData({
    required String key,
  }) = _RoleKeyResponseData;

  factory RoleKeyResponseData.fromJson(Map<String, Object?> json) =>
      _$RoleKeyResponseDataFromJson(json);
}
