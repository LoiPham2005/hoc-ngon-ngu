// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart' hide Headers;
import 'package:retrofit/retrofit.dart';
import 'package:retrofit/error_logger.dart';

import '../models/audit_logs_list_response.dart';

part 'audit_client.g.dart';

@RestApi()
abstract class AuditClient {
  factory AuditClient(Dio dio, {String? baseUrl}) = _AuditClient;

  /// Nhật ký thao tác. Chỉ ĐỌC — không có đường ghi, sửa hay xoá qua HTTP.
  ///
  /// Name not received - field will be skipped.
  @GET('/audit-logs')
  Future<AuditLogsListResponse> getAuditLogs({
    @Query('actorId') String? actorId,
    @Query('action') String? action,
    @Query('entity') String? entity,
    @Query('entityId') String? entityId,
    @Query('from') DateTime? from,
    @Query('to') DateTime? to,
    @Query('page') int? page = 1,
    @Query('limit') int? limit = 20,
  });
}
