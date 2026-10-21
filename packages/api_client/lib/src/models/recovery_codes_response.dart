// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'recovery_codes_response_data.dart';

part 'recovery_codes_response.freezed.dart';
part 'recovery_codes_response.g.dart';

@Freezed()
abstract class RecoveryCodesResponse with _$RecoveryCodesResponse {
  const factory RecoveryCodesResponse({
    required RecoveryCodesResponseData data,
  }) = _RecoveryCodesResponse;

  factory RecoveryCodesResponse.fromJson(Map<String, Object?> json) =>
      _$RecoveryCodesResponseFromJson(json);
}
