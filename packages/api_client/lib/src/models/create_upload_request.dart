// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'create_upload_request.freezed.dart';
part 'create_upload_request.g.dart';

@Freezed()
abstract class CreateUploadRequest with _$CreateUploadRequest {
  const factory CreateUploadRequest({
    required String fileName,
    required String contentType,
    required int size,
    String? folder,
    bool? retain,
  }) = _CreateUploadRequest;

  factory CreateUploadRequest.fromJson(Map<String, Object?> json) =>
      _$CreateUploadRequestFromJson(json);
}
