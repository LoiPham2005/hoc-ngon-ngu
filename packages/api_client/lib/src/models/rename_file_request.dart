// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'rename_file_request.freezed.dart';
part 'rename_file_request.g.dart';

@Freezed()
abstract class RenameFileRequest with _$RenameFileRequest {
  const factory RenameFileRequest({
    required String originalName,
  }) = _RenameFileRequest;

  factory RenameFileRequest.fromJson(Map<String, Object?> json) =>
      _$RenameFileRequestFromJson(json);
}
