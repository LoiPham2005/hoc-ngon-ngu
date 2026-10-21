// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'file.dart';
import 'pagination_meta.dart';

part 'files_list_response_data.freezed.dart';
part 'files_list_response_data.g.dart';

@Freezed()
abstract class FilesListResponseData with _$FilesListResponseData {
  const factory FilesListResponseData({
    required List<File> items,
    required PaginationMeta meta,
  }) = _FilesListResponseData;

  factory FilesListResponseData.fromJson(Map<String, Object?> json) =>
      _$FilesListResponseDataFromJson(json);
}
