// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

@JsonEnum()
enum Attached {
  /// The name has been replaced because it contains a keyword. Original name: `true`.
  @JsonValue('true')
  valueTrue('true'),

  /// The name has been replaced because it contains a keyword. Original name: `false`.
  @JsonValue('false')
  valueFalse('false'),

  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null)
  ;

  const Attached(this.json);

  factory Attached.fromJson(String json) => values.firstWhere(
    (e) => e.json == json,
    orElse: () => $unknown,
  );

  final String? json;

  String toJson() => json ?? 'null';

  @override
  String toString() => json ?? super.toString();

  /// Returns all defined enum values excluding the $unknown value.
  static List<Attached> get $valuesDefined =>
      values.where((value) => value != $unknown).toList();
}
