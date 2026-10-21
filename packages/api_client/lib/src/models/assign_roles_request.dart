// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'assign_roles_request.freezed.dart';
part 'assign_roles_request.g.dart';

@Freezed()
abstract class AssignRolesRequest with _$AssignRolesRequest {
  const factory AssignRolesRequest({
    required List<String> roleKeys,
  }) = _AssignRolesRequest;

  factory AssignRolesRequest.fromJson(Map<String, Object?> json) =>
      _$AssignRolesRequestFromJson(json);
}
