// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'passkey.freezed.dart';
part 'passkey.g.dart';

@Freezed()
abstract class Passkey with _$Passkey {
  const factory Passkey({
    required String id,
    required String? name,
    required String? deviceType,
    required bool backedUp,
    required DateTime createdAt,
    required DateTime? lastUsedAt,
  }) = _Passkey;

  factory Passkey.fromJson(Map<String, Object?> json) =>
      _$PasskeyFromJson(json);
}
