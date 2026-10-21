// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'file.dart';

part 'file_response_data.freezed.dart';
part 'file_response_data.g.dart';

@Freezed()
abstract class FileResponseData with _$FileResponseData {
  const factory FileResponseData({
    required File file,
  }) = _FileResponseData;

  factory FileResponseData.fromJson(Map<String, Object?> json) =>
      _$FileResponseDataFromJson(json);
}
