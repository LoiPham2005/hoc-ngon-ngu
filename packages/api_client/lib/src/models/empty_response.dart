// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'empty_response.freezed.dart';
part 'empty_response.g.dart';

@Freezed()
abstract class EmptyResponse with _$EmptyResponse {
  const factory EmptyResponse({
    required dynamic data,
  }) = _EmptyResponse;

  factory EmptyResponse.fromJson(Map<String, Object?> json) =>
      _$EmptyResponseFromJson(json);
}
