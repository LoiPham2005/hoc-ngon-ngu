// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'notifications_list_response_data.dart';

part 'notifications_list_response.freezed.dart';
part 'notifications_list_response.g.dart';

@Freezed()
abstract class NotificationsListResponse with _$NotificationsListResponse {
  const factory NotificationsListResponse({
    required NotificationsListResponseData data,
  }) = _NotificationsListResponse;

  factory NotificationsListResponse.fromJson(Map<String, Object?> json) =>
      _$NotificationsListResponseFromJson(json);
}
