// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'token_pair.dart';
import 'two_factor_challenge_response_data.dart';

part 'auth_login_response.g.dart';

class AuthLoginResponse {
  final Map<String, dynamic> _json;

  const AuthLoginResponse(this._json);

  factory AuthLoginResponse.fromJson(Map<String, dynamic> json) =>
      AuthLoginResponse(json);

  Map<String, dynamic> toJson() => _json;

  AuthLoginResponseTokenResponse toTokenResponse() =>
      AuthLoginResponseTokenResponse.fromJson(_json);
  AuthLoginResponseTwoFactorChallengeResponse toTwoFactorChallengeResponse() =>
      AuthLoginResponseTwoFactorChallengeResponse.fromJson(_json);
}

@JsonSerializable()
class AuthLoginResponseTokenResponse {
  final TokenPair data;

  const AuthLoginResponseTokenResponse({
    required this.data,
  });

  factory AuthLoginResponseTokenResponse.fromJson(Map<String, Object?> json) =>
      _$AuthLoginResponseTokenResponseFromJson(json);

  Map<String, Object?> toJson() => _$AuthLoginResponseTokenResponseToJson(this);
}

@JsonSerializable()
class AuthLoginResponseTwoFactorChallengeResponse {
  final TwoFactorChallengeResponseData data;

  const AuthLoginResponseTwoFactorChallengeResponse({
    required this.data,
  });

  factory AuthLoginResponseTwoFactorChallengeResponse.fromJson(
    Map<String, Object?> json,
  ) => _$AuthLoginResponseTwoFactorChallengeResponseFromJson(json);

  Map<String, Object?> toJson() =>
      _$AuthLoginResponseTwoFactorChallengeResponseToJson(this);
}
