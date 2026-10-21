// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'login_passkey_request.freezed.dart';
part 'login_passkey_request.g.dart';

@Freezed()
abstract class LoginPasskeyRequest with _$LoginPasskeyRequest {
  const factory LoginPasskeyRequest({
    required String challengeToken,
    required Map<String, dynamic> response,
  }) = _LoginPasskeyRequest;

  factory LoginPasskeyRequest.fromJson(Map<String, Object?> json) =>
      _$LoginPasskeyRequestFromJson(json);
}
