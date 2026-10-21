// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'two_factor_challenge_response_data.freezed.dart';
part 'two_factor_challenge_response_data.g.dart';

@Freezed()
abstract class TwoFactorChallengeResponseData
    with _$TwoFactorChallengeResponseData {
  const factory TwoFactorChallengeResponseData({
    required bool twoFactorRequired,
    required String challengeToken,
    required int expiresIn,
  }) = _TwoFactorChallengeResponseData;

  factory TwoFactorChallengeResponseData.fromJson(Map<String, Object?> json) =>
      _$TwoFactorChallengeResponseDataFromJson(json);
}
