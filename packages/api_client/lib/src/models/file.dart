// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'file_kind_kind.dart';

part 'file.freezed.dart';
part 'file.g.dart';

@Freezed()
abstract class File with _$File {
  const factory File({
    required String id,
    required String key,
    required String url,
    required String originalName,
    required String contentType,
    required FileKindKind? kind,
    required int size,
    required bool attached,
    required bool retained,
    required String? uploadedById,
    required DateTime createdAt,
  }) = _File;

  factory File.fromJson(Map<String, Object?> json) => _$FileFromJson(json);
}
