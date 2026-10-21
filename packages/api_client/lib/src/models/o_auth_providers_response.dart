// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'o_auth_providers_response_data.dart';

part 'o_auth_providers_response.freezed.dart';
part 'o_auth_providers_response.g.dart';

@Freezed()
abstract class OAuthProvidersResponse with _$OAuthProvidersResponse {
  const factory OAuthProvidersResponse({
    required OAuthProvidersResponseData data,
  }) = _OAuthProvidersResponse;

  factory OAuthProvidersResponse.fromJson(Map<String, Object?> json) =>
      _$OAuthProvidersResponseFromJson(json);
}
