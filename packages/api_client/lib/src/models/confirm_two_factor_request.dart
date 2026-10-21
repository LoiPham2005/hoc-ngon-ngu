// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'confirm_two_factor_request.freezed.dart';
part 'confirm_two_factor_request.g.dart';

@Freezed()
abstract class ConfirmTwoFactorRequest with _$ConfirmTwoFactorRequest {
  const factory ConfirmTwoFactorRequest({
    required String code,
  }) = _ConfirmTwoFactorRequest;

  factory ConfirmTwoFactorRequest.fromJson(Map<String, Object?> json) =>
      _$ConfirmTwoFactorRequestFromJson(json);
}
