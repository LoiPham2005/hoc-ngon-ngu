// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'o_auth_linked_response_data.dart';

part 'o_auth_linked_response.freezed.dart';
part 'o_auth_linked_response.g.dart';

@Freezed()
abstract class OAuthLinkedResponse with _$OAuthLinkedResponse {
  const factory OAuthLinkedResponse({
    required OAuthLinkedResponseData data,
  }) = _OAuthLinkedResponse;

  factory OAuthLinkedResponse.fromJson(Map<String, Object?> json) =>
      _$OAuthLinkedResponseFromJson(json);
}
