// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'rename_passkey_request.freezed.dart';
part 'rename_passkey_request.g.dart';

@Freezed()
abstract class RenamePasskeyRequest with _$RenamePasskeyRequest {
  const factory RenamePasskeyRequest({
    required String name,
  }) = _RenamePasskeyRequest;

  factory RenamePasskeyRequest.fromJson(Map<String, Object?> json) =>
      _$RenamePasskeyRequestFromJson(json);
}
