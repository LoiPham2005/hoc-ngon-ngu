// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart' hide Headers;
import 'package:retrofit/retrofit.dart';
import 'package:retrofit/error_logger.dart';

import '../models/devices_list_response.dart';
import '../models/empty_response.dart';
import '../models/register_device_request.dart';

part 'devices_client.g.dart';

@RestApi()
abstract class DevicesClient {
  factory DevicesClient(Dio dio, {String? baseUrl}) = _DevicesClient;

  /// Thiết bị đang nhận push.
  ///
  /// Name not received - field will be skipped.
  @GET('/devices')
  Future<DevicesListResponse> getDevices();

  /// Đăng ký thiết bị nhận push. `fcmToken` UNIQUE toàn bảng: cùng một máy có thể được hai người đăng nhập lần lượt và FCM cấp lại đúng token đó.
  ///
  /// [body] - Name not received - field will be skipped.
  ///
  /// Name not received - field will be skipped.
  @POST('/devices')
  Future<EmptyResponse> postDevices({
    @Body() required RegisterDeviceRequest body,
  });

  /// Gỡ thiết bị khỏi danh sách nhận push — gọi lúc đăng xuất trên máy đó.
  ///
  /// Name not received - field will be skipped.
  @DELETE('/devices')
  Future<EmptyResponse> deleteDevices();
}
