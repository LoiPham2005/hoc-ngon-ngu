// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'role.freezed.dart';
part 'role.g.dart';

@Freezed()
abstract class Role with _$Role {
  const factory Role({
    required String key,
    required String name,
    required String? description,
    required bool isSystem,
    required int level,
    required List<String> permissions,
    required int userCount,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Role;

  factory Role.fromJson(Map<String, Object?> json) => _$RoleFromJson(json);
}
