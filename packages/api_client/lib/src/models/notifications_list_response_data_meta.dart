// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'notifications_list_response_data_meta.freezed.dart';
part 'notifications_list_response_data_meta.g.dart';

@Freezed()
abstract class NotificationsListResponseDataMeta
    with _$NotificationsListResponseDataMeta {
  const factory NotificationsListResponseDataMeta({
    required int page,
    required int limit,
    required int total,
    required int totalPages,
    required bool hasNext,
    required int unreadCount,
  }) = _NotificationsListResponseDataMeta;

  factory NotificationsListResponseDataMeta.fromJson(
    Map<String, Object?> json,
  ) => _$NotificationsListResponseDataMetaFromJson(json);
}
