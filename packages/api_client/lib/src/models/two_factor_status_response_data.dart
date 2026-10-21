// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'two_factor_status_response_data.freezed.dart';
part 'two_factor_status_response_data.g.dart';

@Freezed()
abstract class TwoFactorStatusResponseData with _$TwoFactorStatusResponseData {
  const factory TwoFactorStatusResponseData({
    required bool enabled,
    required DateTime? enabledAt,
    required int remainingRecoveryCodes,
    required bool available,
  }) = _TwoFactorStatusResponseData;

  factory TwoFactorStatusResponseData.fromJson(Map<String, Object?> json) =>
      _$TwoFactorStatusResponseDataFromJson(json);
}
