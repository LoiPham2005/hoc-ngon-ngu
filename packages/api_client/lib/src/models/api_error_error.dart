// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'api_error_error.freezed.dart';
part 'api_error_error.g.dart';

@Freezed()
abstract class ApiErrorError with _$ApiErrorError {
  const factory ApiErrorError({
    required String code,
    required String message,
    Map<String, List<String>>? fields,
  }) = _ApiErrorError;

  factory ApiErrorError.fromJson(Map<String, Object?> json) =>
      _$ApiErrorErrorFromJson(json);
}
