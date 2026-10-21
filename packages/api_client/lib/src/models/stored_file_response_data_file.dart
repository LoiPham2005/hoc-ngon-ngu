// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'stored_file_response_data_file.freezed.dart';
part 'stored_file_response_data_file.g.dart';

@Freezed()
abstract class StoredFileResponseDataFile with _$StoredFileResponseDataFile {
  const factory StoredFileResponseDataFile({
    required String key,
    required String url,
    required int size,
    required String contentType,
  }) = _StoredFileResponseDataFile;

  factory StoredFileResponseDataFile.fromJson(Map<String, Object?> json) =>
      _$StoredFileResponseDataFileFromJson(json);
}
