// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'two_factor_setup_response_data.dart';

part 'two_factor_setup_response.freezed.dart';
part 'two_factor_setup_response.g.dart';

@Freezed()
abstract class TwoFactorSetupResponse with _$TwoFactorSetupResponse {
  const factory TwoFactorSetupResponse({
    required TwoFactorSetupResponseData data,
  }) = _TwoFactorSetupResponse;

  factory TwoFactorSetupResponse.fromJson(Map<String, Object?> json) =>
      _$TwoFactorSetupResponseFromJson(json);
}
