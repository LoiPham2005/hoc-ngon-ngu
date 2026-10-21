// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'o_auth_providers_response_data.freezed.dart';
part 'o_auth_providers_response_data.g.dart';

@Freezed()
abstract class OAuthProvidersResponseData with _$OAuthProvidersResponseData {
  const factory OAuthProvidersResponseData({
    required List<String> providers,
  }) = _OAuthProvidersResponseData;

  factory OAuthProvidersResponseData.fromJson(Map<String, Object?> json) =>
      _$OAuthProvidersResponseDataFromJson(json);
}
