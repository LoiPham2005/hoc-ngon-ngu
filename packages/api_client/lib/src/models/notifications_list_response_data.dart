// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'notification.dart';
import 'notifications_list_response_data_meta.dart';

part 'notifications_list_response_data.freezed.dart';
part 'notifications_list_response_data.g.dart';

@Freezed()
abstract class NotificationsListResponseData
    with _$NotificationsListResponseData {
  const factory NotificationsListResponseData({
    required List<Notification> items,
    required NotificationsListResponseDataMeta meta,
  }) = _NotificationsListResponseData;

  factory NotificationsListResponseData.fromJson(Map<String, Object?> json) =>
      _$NotificationsListResponseDataFromJson(json);
}
