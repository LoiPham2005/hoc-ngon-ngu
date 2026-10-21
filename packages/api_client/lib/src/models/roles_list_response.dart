// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'roles_list_response_data.dart';

part 'roles_list_response.freezed.dart';
part 'roles_list_response.g.dart';

@Freezed()
abstract class RolesListResponse with _$RolesListResponse {
  const factory RolesListResponse({
    required RolesListResponseData data,
  }) = _RolesListResponse;

  factory RolesListResponse.fromJson(Map<String, Object?> json) =>
      _$RolesListResponseFromJson(json);
}
