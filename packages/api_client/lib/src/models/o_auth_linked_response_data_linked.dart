// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'o_auth_linked_response_data_linked.freezed.dart';
part 'o_auth_linked_response_data_linked.g.dart';

@Freezed()
abstract class OAuthLinkedResponseDataLinked
    with _$OAuthLinkedResponseDataLinked {
  const factory OAuthLinkedResponseDataLinked({
    required String provider,
    required DateTime createdAt,
  }) = _OAuthLinkedResponseDataLinked;

  factory OAuthLinkedResponseDataLinked.fromJson(Map<String, Object?> json) =>
      _$OAuthLinkedResponseDataLinkedFromJson(json);
}
