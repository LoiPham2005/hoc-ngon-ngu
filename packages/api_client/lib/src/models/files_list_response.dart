// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'files_list_response_data.dart';

part 'files_list_response.freezed.dart';
part 'files_list_response.g.dart';

@Freezed()
abstract class FilesListResponse with _$FilesListResponse {
  const factory FilesListResponse({
    required FilesListResponseData data,
  }) = _FilesListResponse;

  factory FilesListResponse.fromJson(Map<String, Object?> json) =>
      _$FilesListResponseFromJson(json);
}
