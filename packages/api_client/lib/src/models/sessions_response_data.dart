// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'session.dart';

part 'sessions_response_data.freezed.dart';
part 'sessions_response_data.g.dart';

@Freezed()
abstract class SessionsResponseData with _$SessionsResponseData {
  const factory SessionsResponseData({
    required List<Session> sessions,
  }) = _SessionsResponseData;

  factory SessionsResponseData.fromJson(Map<String, Object?> json) =>
      _$SessionsResponseDataFromJson(json);
}
