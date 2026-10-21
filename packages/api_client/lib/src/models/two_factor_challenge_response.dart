// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'two_factor_challenge_response_data.dart';

part 'two_factor_challenge_response.freezed.dart';
part 'two_factor_challenge_response.g.dart';

@Freezed()
abstract class TwoFactorChallengeResponse with _$TwoFactorChallengeResponse {
  const factory TwoFactorChallengeResponse({
    required TwoFactorChallengeResponseData data,
  }) = _TwoFactorChallengeResponse;

  factory TwoFactorChallengeResponse.fromJson(Map<String, Object?> json) =>
      _$TwoFactorChallengeResponseFromJson(json);
}
