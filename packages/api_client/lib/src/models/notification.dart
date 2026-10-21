// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification.freezed.dart';
part 'notification.g.dart';

@Freezed()
abstract class Notification with _$Notification {
  const factory Notification({
    required String id,
    required String title,
    required String body,
    required String type,
    required Map<String, dynamic>? data,
    required bool isRead,
    required DateTime? readAt,
    required DateTime createdAt,
  }) = _Notification;

  factory Notification.fromJson(Map<String, Object?> json) =>
      _$NotificationFromJson(json);
}
