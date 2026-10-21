// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'disable_two_factor_request.freezed.dart';
part 'disable_two_factor_request.g.dart';

@Freezed()
abstract class DisableTwoFactorRequest with _$DisableTwoFactorRequest {
  const factory DisableTwoFactorRequest({
    required String code,
    String? password,
  }) = _DisableTwoFactorRequest;

  factory DisableTwoFactorRequest.fromJson(Map<String, Object?> json) =>
      _$DisableTwoFactorRequestFromJson(json);
}
