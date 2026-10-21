// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'stored_file_response_data_file.dart';

part 'stored_file_response_data.freezed.dart';
part 'stored_file_response_data.g.dart';

@Freezed()
abstract class StoredFileResponseData with _$StoredFileResponseData {
  const factory StoredFileResponseData({
    required StoredFileResponseDataFile file,
  }) = _StoredFileResponseData;

  factory StoredFileResponseData.fromJson(Map<String, Object?> json) =>
      _$StoredFileResponseDataFromJson(json);
}
