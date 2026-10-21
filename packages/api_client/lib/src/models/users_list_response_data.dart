// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'user.dart';
import 'pagination_meta.dart';

part 'users_list_response_data.freezed.dart';
part 'users_list_response_data.g.dart';

@Freezed()
abstract class UsersListResponseData with _$UsersListResponseData {
  const factory UsersListResponseData({
    required List<User> items,
    required PaginationMeta meta,
  }) = _UsersListResponseData;

  factory UsersListResponseData.fromJson(Map<String, Object?> json) =>
      _$UsersListResponseDataFromJson(json);
}
