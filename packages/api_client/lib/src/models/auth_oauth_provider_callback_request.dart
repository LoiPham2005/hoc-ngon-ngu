// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_oauth_provider_callback_request.freezed.dart';
part 'auth_oauth_provider_callback_request.g.dart';

@Freezed()
abstract class AuthOauthProviderCallbackRequest
    with _$AuthOauthProviderCallbackRequest {
  const factory AuthOauthProviderCallbackRequest({
    String? code,
    String? state,
    String? error,

    /// JSON họ tên, Apple chỉ gửi LẦN ĐẦU
    String? user,
  }) = _AuthOauthProviderCallbackRequest;

  factory AuthOauthProviderCallbackRequest.fromJson(
    Map<String, Object?> json,
  ) => _$AuthOauthProviderCallbackRequestFromJson(json);
}
