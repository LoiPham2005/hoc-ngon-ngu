// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart' hide Headers;

import 'auth/auth_client.dart';
import 'fa/fa_client.dart';
import 'passkeys/passkeys_client.dart';
import 'o_auth/o_auth_client.dart';
import 'notifications/notifications_client.dart';
import 'devices/devices_client.dart';
import 'audit/audit_client.dart';
import 'roles/roles_client.dart';
import 'files/files_client.dart';
import 'users/users_client.dart';

/// nextjs_prisma_base API `v1.0.0`.
///
/// REST API cho client mobile — dùng Bearer token, khác cookie session của web. Tự sinh từ Zod schema thật trong src/schemas/*.ts, không phải viết tay riêng.
class RestClient {
  RestClient(
    Dio dio, {
    String? baseUrl,
  }) : _dio = dio,
       _baseUrl = baseUrl;

  final Dio _dio;
  final String? _baseUrl;

  static String get version => '1.0.0';

  AuthClient? _auth;
  FaClient? _fa;
  PasskeysClient? _passkeys;
  OAuthClient? _oAuth;
  NotificationsClient? _notifications;
  DevicesClient? _devices;
  AuditClient? _audit;
  RolesClient? _roles;
  FilesClient? _files;
  UsersClient? _users;

  AuthClient get auth => _auth ??= AuthClient(_dio, baseUrl: _baseUrl);

  FaClient get fa => _fa ??= FaClient(_dio, baseUrl: _baseUrl);

  PasskeysClient get passkeys =>
      _passkeys ??= PasskeysClient(_dio, baseUrl: _baseUrl);

  OAuthClient get oAuth => _oAuth ??= OAuthClient(_dio, baseUrl: _baseUrl);

  NotificationsClient get notifications =>
      _notifications ??= NotificationsClient(_dio, baseUrl: _baseUrl);

  DevicesClient get devices =>
      _devices ??= DevicesClient(_dio, baseUrl: _baseUrl);

  AuditClient get audit => _audit ??= AuditClient(_dio, baseUrl: _baseUrl);

  RolesClient get roles => _roles ??= RolesClient(_dio, baseUrl: _baseUrl);

  FilesClient get files => _files ??= FilesClient(_dio, baseUrl: _baseUrl);

  UsersClient get users => _users ??= UsersClient(_dio, baseUrl: _baseUrl);
}
