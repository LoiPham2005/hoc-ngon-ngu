// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'role_response_data.dart';

part 'role_response.freezed.dart';
part 'role_response.g.dart';

@Freezed()
abstract class RoleResponse with _$RoleResponse {
  const factory RoleResponse({
    required RoleResponseData data,
  }) = _RoleResponse;

  factory RoleResponse.fromJson(Map<String, Object?> json) =>
      _$RoleResponseFromJson(json);
}
