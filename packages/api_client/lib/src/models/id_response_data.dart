// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'id_response_data.freezed.dart';
part 'id_response_data.g.dart';

@Freezed()
abstract class IdResponseData with _$IdResponseData {
  const factory IdResponseData({
    required String id,
  }) = _IdResponseData;

  factory IdResponseData.fromJson(Map<String, Object?> json) =>
      _$IdResponseDataFromJson(json);
}
