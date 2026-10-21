// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'register_passkey_request.freezed.dart';
part 'register_passkey_request.g.dart';

@Freezed()
abstract class RegisterPasskeyRequest with _$RegisterPasskeyRequest {
  const factory RegisterPasskeyRequest({
    required String challengeToken,
    required Map<String, dynamic> response,
    String? name,
  }) = _RegisterPasskeyRequest;

  factory RegisterPasskeyRequest.fromJson(Map<String, Object?> json) =>
      _$RegisterPasskeyRequestFromJson(json);
}
