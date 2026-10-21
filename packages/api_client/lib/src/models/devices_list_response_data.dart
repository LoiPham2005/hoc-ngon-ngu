// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'device.dart';

part 'devices_list_response_data.freezed.dart';
part 'devices_list_response_data.g.dart';

@Freezed()
abstract class DevicesListResponseData with _$DevicesListResponseData {
  const factory DevicesListResponseData({
    required List<Device> devices,
  }) = _DevicesListResponseData;

  factory DevicesListResponseData.fromJson(Map<String, Object?> json) =>
      _$DevicesListResponseDataFromJson(json);
}
