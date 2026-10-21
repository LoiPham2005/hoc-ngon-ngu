// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'two_factor_status_response_data.dart';

part 'two_factor_status_response.freezed.dart';
part 'two_factor_status_response.g.dart';

@Freezed()
abstract class TwoFactorStatusResponse with _$TwoFactorStatusResponse {
  const factory TwoFactorStatusResponse({
    required TwoFactorStatusResponseData data,
  }) = _TwoFactorStatusResponse;

  factory TwoFactorStatusResponse.fromJson(Map<String, Object?> json) =>
      _$TwoFactorStatusResponseFromJson(json);
}
