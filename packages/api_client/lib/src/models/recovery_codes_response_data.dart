// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'recovery_codes_response_data.freezed.dart';
part 'recovery_codes_response_data.g.dart';

@Freezed()
abstract class RecoveryCodesResponseData with _$RecoveryCodesResponseData {
  const factory RecoveryCodesResponseData({
    required List<String> recoveryCodes,
  }) = _RecoveryCodesResponseData;

  factory RecoveryCodesResponseData.fromJson(Map<String, Object?> json) =>
      _$RecoveryCodesResponseDataFromJson(json);
}
