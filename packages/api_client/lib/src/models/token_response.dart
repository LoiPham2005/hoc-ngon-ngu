// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'token_pair.dart';

part 'token_response.freezed.dart';
part 'token_response.g.dart';

@Freezed()
abstract class TokenResponse with _$TokenResponse {
  const factory TokenResponse({
    required TokenPair data,
  }) = _TokenResponse;

  factory TokenResponse.fromJson(Map<String, Object?> json) =>
      _$TokenResponseFromJson(json);
}
