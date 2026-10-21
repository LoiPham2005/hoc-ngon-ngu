// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'send_notification_request_type_type.dart';

part 'send_notification_request.freezed.dart';
part 'send_notification_request.g.dart';

@Freezed()
abstract class SendNotificationRequest with _$SendNotificationRequest {
  const factory SendNotificationRequest({
    required String title,
    required String body,
    @Default(SendNotificationRequestTypeType.direct)
    SendNotificationRequestTypeType type,
    String? imageUrl,
    String? actionUrl,
    Map<String, dynamic>? data,
    List<String>? userIds,
  }) = _SendNotificationRequest;

  factory SendNotificationRequest.fromJson(Map<String, Object?> json) =>
      _$SendNotificationRequestFromJson(json);
}
