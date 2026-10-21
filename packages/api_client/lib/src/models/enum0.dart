// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

/// Giữ trong thư viện, không dọn — chỉ file:manage.
/// Name not received and was auto-generated.
@JsonEnum()
enum Enum0 {
  /// The name has been replaced because it contains a keyword. Original name: `true`.
  @JsonValue('true')
  valueTrue('true'),

  /// The name has been replaced because it contains a keyword. Original name: `false`.
  @JsonValue('false')
  valueFalse('false'),

  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null)
  ;

  const Enum0(this.json);

  factory Enum0.fromJson(String json) => values.firstWhere(
    (e) => e.json == json,
    orElse: () => $unknown,
  );

  final String? json;

  String toJson() => json ?? 'null';

  @override
  String toString() => json ?? super.toString();

  /// Returns all defined enum values excluding the $unknown value.
  static List<Enum0> get $valuesDefined =>
      values.where((value) => value != $unknown).toList();
}
