// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'role.dart';

part 'role_response_data.freezed.dart';
part 'role_response_data.g.dart';

@Freezed()
abstract class RoleResponseData with _$RoleResponseData {
  const factory RoleResponseData({
    required Role role,
  }) = _RoleResponseData;

  factory RoleResponseData.fromJson(Map<String, Object?> json) =>
      _$RoleResponseDataFromJson(json);
}
