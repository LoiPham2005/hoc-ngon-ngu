// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart' hide Headers;
import 'package:retrofit/retrofit.dart';
import 'package:retrofit/error_logger.dart';

import '../models/empty_response.dart';
import '../models/id_response.dart';
import '../models/notifications_list_response.dart';
import '../models/send_notification_request.dart';

part 'notifications_client.g.dart';

@RestApi()
abstract class NotificationsClient {
  factory NotificationsClient(Dio dio, {String? baseUrl}) =
      _NotificationsClient;

  /// Hộp thư của CHÍNH mình — userId lấy từ token, không từ tham số.
  ///
  /// Name not received - field will be skipped.
  @GET('/notifications')
  Future<NotificationsListResponse> getNotifications({
    @Query('page') int? page = 1,
    @Query('limit') int? limit = 20,
    @Query('unreadOnly') bool? unreadOnly = false,
  });

  /// Gửi thông báo — cần notification:send.
  ///
  /// [body] - Name not received - field will be skipped.
  ///
  /// Name not received - field will be skipped.
  @POST('/notifications')
  Future<EmptyResponse> postNotifications({
    @Body() required SendNotificationRequest body,
  });

  /// Số thông báo chưa đọc — cho chấm đỏ trên chuông.
  ///
  /// Name not received - field will be skipped.
  @GET('/notifications/unread-count')
  Future<EmptyResponse> getNotificationsUnreadCount();

  /// Đánh dấu đã đọc tất cả.
  ///
  /// Name not received - field will be skipped.
  @POST('/notifications/read-all')
  Future<EmptyResponse> postNotificationsReadAll();

  /// Đánh dấu đã đọc MỘT thông báo (id là bản ghi người nhận).
  ///
  /// Name not received - field will be skipped.
  @POST('/notifications/{id}/read')
  Future<IdResponse> postNotificationsIdRead({
    @Path('id') required String id,
  });
}
