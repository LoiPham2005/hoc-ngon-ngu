// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'two_factor_setup_response_data.freezed.dart';
part 'two_factor_setup_response_data.g.dart';

@Freezed()
abstract class TwoFactorSetupResponseData with _$TwoFactorSetupResponseData {
  const factory TwoFactorSetupResponseData({
    required String secret,
    required String uri,
  }) = _TwoFactorSetupResponseData;

  factory TwoFactorSetupResponseData.fromJson(Map<String, Object?> json) =>
      _$TwoFactorSetupResponseDataFromJson(json);
}
