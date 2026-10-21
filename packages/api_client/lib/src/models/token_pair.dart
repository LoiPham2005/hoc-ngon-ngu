// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'user.dart';

part 'token_pair.freezed.dart';
part 'token_pair.g.dart';

@Freezed()
abstract class TokenPair with _$TokenPair {
  const factory TokenPair({
    required User user,
    required String accessToken,
    required int expiresIn,
    required String tokenType,
    required String refreshToken,
    required DateTime refreshExpiresAt,
    required String sessionId,
  }) = _TokenPair;

  factory TokenPair.fromJson(Map<String, Object?> json) =>
      _$TokenPairFromJson(json);
}
