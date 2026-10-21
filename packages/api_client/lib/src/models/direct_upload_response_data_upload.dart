// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'direct_upload_response_data_upload.freezed.dart';
part 'direct_upload_response_data_upload.g.dart';

@Freezed()
abstract class DirectUploadResponseDataUpload
    with _$DirectUploadResponseDataUpload {
  const factory DirectUploadResponseDataUpload({
    required String url,
    required String method,
    required Map<String, String> headers,
    required DateTime expiresAt,
  }) = _DirectUploadResponseDataUpload;

  factory DirectUploadResponseDataUpload.fromJson(Map<String, Object?> json) =>
      _$DirectUploadResponseDataUploadFromJson(json);
}
