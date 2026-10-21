// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'sessions_response_data.dart';

part 'sessions_response.freezed.dart';
part 'sessions_response.g.dart';

@Freezed()
abstract class SessionsResponse with _$SessionsResponse {
  const factory SessionsResponse({
    required SessionsResponseData data,
  }) = _SessionsResponse;

  factory SessionsResponse.fromJson(Map<String, Object?> json) =>
      _$SessionsResponseFromJson(json);
}
