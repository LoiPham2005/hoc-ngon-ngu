// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'direct_upload_response_data.dart';

part 'direct_upload_response.freezed.dart';
part 'direct_upload_response.g.dart';

@Freezed()
abstract class DirectUploadResponse with _$DirectUploadResponse {
  const factory DirectUploadResponse({
    required DirectUploadResponseData data,
  }) = _DirectUploadResponse;

  factory DirectUploadResponse.fromJson(Map<String, Object?> json) =>
      _$DirectUploadResponseFromJson(json);
}
