// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'permission_explanation_override_override.dart';

part 'permission_explanation.freezed.dart';
part 'permission_explanation.g.dart';

@Freezed()
abstract class PermissionExplanation with _$PermissionExplanation {
  const factory PermissionExplanation({
    required String key,
    required bool granted,
    required List<String> fromRoles,
    @JsonKey(name: 'override') required PermissionExplanationOverrideOverride? overrideValue,
  }) = _PermissionExplanation;

  factory PermissionExplanation.fromJson(Map<String, Object?> json) =>
      _$PermissionExplanationFromJson(json);
}
