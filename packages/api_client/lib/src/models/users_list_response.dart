// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'users_list_response_data.dart';

part 'users_list_response.freezed.dart';
part 'users_list_response.g.dart';

@Freezed()
abstract class UsersListResponse with _$UsersListResponse {
  const factory UsersListResponse({
    required UsersListResponseData data,
  }) = _UsersListResponse;

  factory UsersListResponse.fromJson(Map<String, Object?> json) =>
      _$UsersListResponseFromJson(json);
}
