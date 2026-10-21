// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'stored_file_response_data.dart';

part 'stored_file_response.freezed.dart';
part 'stored_file_response.g.dart';

@Freezed()
abstract class StoredFileResponse with _$StoredFileResponse {
  const factory StoredFileResponse({
    required StoredFileResponseData data,
  }) = _StoredFileResponse;

  factory StoredFileResponse.fromJson(Map<String, Object?> json) =>
      _$StoredFileResponseFromJson(json);
}
