// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'audit_log.freezed.dart';
part 'audit_log.g.dart';

@Freezed()
abstract class AuditLog with _$AuditLog {
  const factory AuditLog({
    required String id,
    required String action,
    required String entity,
    required String? entityId,
    required String? actorId,
    required String? actorEmail,
    required Map<String, dynamic>? metadata,
    required String? ip,
    required String? userAgent,
    required DateTime createdAt,
  }) = _AuditLog;

  factory AuditLog.fromJson(Map<String, Object?> json) =>
      _$AuditLogFromJson(json);
}
