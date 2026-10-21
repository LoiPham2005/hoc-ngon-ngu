// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'o_auth_linked_response_data_linked.dart';

part 'o_auth_linked_response_data.freezed.dart';
part 'o_auth_linked_response_data.g.dart';

@Freezed()
abstract class OAuthLinkedResponseData with _$OAuthLinkedResponseData {
  const factory OAuthLinkedResponseData({
    required List<OAuthLinkedResponseDataLinked> linked,
  }) = _OAuthLinkedResponseData;

  factory OAuthLinkedResponseData.fromJson(Map<String, Object?> json) =>
      _$OAuthLinkedResponseDataFromJson(json);
}
