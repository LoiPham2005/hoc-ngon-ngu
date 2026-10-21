// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'file.dart';
import 'direct_upload_response_data_upload.dart';

part 'direct_upload_response_data.freezed.dart';
part 'direct_upload_response_data.g.dart';

@Freezed()
abstract class DirectUploadResponseData with _$DirectUploadResponseData {
  const factory DirectUploadResponseData({
    required File file,
    required DirectUploadResponseDataUpload upload,
  }) = _DirectUploadResponseData;

  factory DirectUploadResponseData.fromJson(Map<String, Object?> json) =>
      _$DirectUploadResponseDataFromJson(json);
}
