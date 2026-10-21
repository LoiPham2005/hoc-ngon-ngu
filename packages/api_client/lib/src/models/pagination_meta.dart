// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'pagination_meta.freezed.dart';
part 'pagination_meta.g.dart';

@Freezed()
abstract class PaginationMeta with _$PaginationMeta {
  const factory PaginationMeta({
    required int page,
    required int limit,
    required int total,
    required int totalPages,
    required bool hasNext,
  }) = _PaginationMeta;

  factory PaginationMeta.fromJson(Map<String, Object?> json) =>
      _$PaginationMetaFromJson(json);
}
