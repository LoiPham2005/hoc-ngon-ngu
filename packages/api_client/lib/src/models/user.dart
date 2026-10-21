// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'user_status_status.dart';

part 'user.freezed.dart';
part 'user.g.dart';

@Freezed()
abstract class User with _$User {
  const factory User({
    required String id,
    required String? email,
    required String? phone,
    required String? username,
    required String? fullName,
    required String? avatarUrl,
    required UserStatusStatus status,
    required DateTime? emailVerifiedAt,
    required DateTime? lockedUntil,
    required List<String> roles,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default(false) bool twoFactorEnabled,
  }) = _User;

  factory User.fromJson(Map<String, Object?> json) => _$UserFromJson(json);
}
