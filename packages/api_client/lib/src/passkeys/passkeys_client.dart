// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart' hide Headers;
import 'package:retrofit/retrofit.dart';
import 'package:retrofit/error_logger.dart';

import '../models/id_response.dart';
import '../models/login_passkey_request.dart';
import '../models/passkey_response.dart';
import '../models/passkeys_list_response.dart';
import '../models/register_passkey_request.dart';
import '../models/rename_passkey_request.dart';
import '../models/token_response.dart';
import '../models/web_authn_options_response.dart';

part 'passkeys_client.g.dart';

@RestApi()
abstract class PasskeysClient {
  factory PasskeysClient(Dio dio, {String? baseUrl}) = _PasskeysClient;

  /// Danh sách passkey của tài khoản hiện tại.
  ///
  /// Name not received - field will be skipped.
  @GET('/auth/passkeys')
  Future<PasskeysListResponse> getAuthPasskeys();

  /// Bước 1 — tuỳ chọn cho navigator.credentials.create().
  ///
  /// Name not received - field will be skipped.
  @POST('/auth/passkeys/register/options')
  Future<WebAuthnOptionsResponse> postAuthPasskeysRegisterOptions();

  /// Bước 2 — xác minh và lưu passkey.
  ///
  /// [body] - Name not received - field will be skipped.
  ///
  /// Name not received - field will be skipped.
  @POST('/auth/passkeys/register/verify')
  Future<PasskeyResponse> postAuthPasskeysRegisterVerify({
    @Body() required RegisterPasskeyRequest body,
  });

  /// Bước 1 — tuỳ chọn cho navigator.credentials.get(). KHÔNG nhận tham số: bắt nhập email trước vừa thừa một bước, vừa biến endpoint thành công cụ dò xem email nào đã đăng ký.
  ///
  /// Name not received - field will be skipped.
  @POST('/auth/passkeys/login/options')
  Future<WebAuthnOptionsResponse> postAuthPasskeysLoginOptions();

  /// Bước 2 — đăng nhập bằng passkey. Không cần mật khẩu và KHÔNG hỏi thêm 2FA: passkey với userVerification=required đã là hai yếu tố.
  ///
  /// [body] - Name not received - field will be skipped.
  ///
  /// Name not received - field will be skipped.
  @POST('/auth/passkeys/login/verify')
  Future<TokenResponse> postAuthPasskeysLoginVerify({
    @Body() required LoginPasskeyRequest body,
  });

  /// Đổi tên passkey.
  ///
  /// [body] - Name not received - field will be skipped.
  ///
  /// Name not received - field will be skipped.
  @PATCH('/auth/passkeys/{id}')
  Future<PasskeyResponse> patchAuthPasskeysId({
    @Path('id') required String id,
    @Body() required RenamePasskeyRequest body,
  });

  /// Xoá passkey — từ chối nếu đây là cách đăng nhập CUỐI CÙNG.
  ///
  /// Name not received - field will be skipped.
  @DELETE('/auth/passkeys/{id}')
  Future<IdResponse> deleteAuthPasskeysId({
    @Path('id') required String id,
  });
}
