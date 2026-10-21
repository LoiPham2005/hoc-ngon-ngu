// GENERATED CODE - DO NOT MODIFY BY HAND
// Sinh bởi gen_api.dart — chạy lại `make gen-api` là bị ghi đè.
// ignore_for_file: type=lint

import 'package:api_client/api_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'audit_providers.g.dart';

/// Nhật ký thao tác. Chỉ ĐỌC — không có đường ghi, sửa hay xoá qua HTTP.
@riverpod
Future<AuditLogsListResponse> getAuditLogs(
  Ref ref, {
  String? actorId,
  String? action,
  String? entity,
  String? entityId,
  DateTime? from,
  DateTime? to,
  int? page = 1,
  int? limit = 20,
}) => ref
    .watch(restClientProvider)
    .audit
    .getAuditLogs(
      actorId: actorId,
      action: action,
      entity: entity,
      entityId: entityId,
      from: from,
      to: to,
      page: page,
      limit: limit,
    );
