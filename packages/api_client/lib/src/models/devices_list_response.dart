// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'devices_list_response_data.dart';

part 'devices_list_response.freezed.dart';
part 'devices_list_response.g.dart';

@Freezed()
abstract class DevicesListResponse with _$DevicesListResponse {
  const factory DevicesListResponse({
    required DevicesListResponseData data,
  }) = _DevicesListResponse;

  factory DevicesListResponse.fromJson(Map<String, Object?> json) =>
      _$DevicesListResponseFromJson(json);
}
