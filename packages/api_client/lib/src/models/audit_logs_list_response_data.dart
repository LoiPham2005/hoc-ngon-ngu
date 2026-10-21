// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'audit_log.dart';
import 'pagination_meta.dart';

part 'audit_logs_list_response_data.freezed.dart';
part 'audit_logs_list_response_data.g.dart';

@Freezed()
abstract class AuditLogsListResponseData with _$AuditLogsListResponseData {
  const factory AuditLogsListResponseData({
    required List<AuditLog> items,
    required PaginationMeta meta,
  }) = _AuditLogsListResponseData;

  factory AuditLogsListResponseData.fromJson(Map<String, Object?> json) =>
      _$AuditLogsListResponseDataFromJson(json);
}
