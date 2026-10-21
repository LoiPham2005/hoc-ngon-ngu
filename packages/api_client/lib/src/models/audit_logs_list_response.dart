// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'audit_logs_list_response_data.dart';

part 'audit_logs_list_response.freezed.dart';
part 'audit_logs_list_response.g.dart';

@Freezed()
abstract class AuditLogsListResponse with _$AuditLogsListResponse {
  const factory AuditLogsListResponse({
    required AuditLogsListResponseData data,
  }) = _AuditLogsListResponse;

  factory AuditLogsListResponse.fromJson(Map<String, Object?> json) =>
      _$AuditLogsListResponseFromJson(json);
}
