// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart' hide Headers;
import 'package:retrofit/retrofit.dart';
import 'package:retrofit/error_logger.dart';

import '../models/auth_login_response.dart';
import '../models/change_password_request.dart';
import '../models/confirm_email_change_request.dart';
import '../models/empty_response.dart';
import '../models/forgot_password_request.dart';
import '../models/id_response.dart';
import '../models/login_request.dart';
import '../models/refresh_request.dart';
import '../models/register_request.dart';
import '../models/request_email_change_request.dart';
import '../models/request_phone_otp_request.dart';
import '../models/reset_password_request.dart';
import '../models/sessions_response.dart';
import '../models/token_response.dart';
import '../models/user_response.dart';
import '../models/verify_email_request.dart';
import '../models/verify_phone_otp_request.dart';

part 'auth_client.g.dart';

@RestApi()
abstract class AuthClient {
  factory AuthClient(Dio dio, {String? baseUrl}) = _AuthClient;

  /// Đăng nhập — trả về token, HOẶC vé 2FA nếu tài khoản đã bật.
  ///
  /// [body] - Name not received - field will be skipped.
  ///
  /// Name not received - field will be skipped.
  @POST('/auth/login')
  Future<AuthLoginResponse> postAuthLogin({
    @Body() required LoginRequest body,
  });

  /// Tạo tài khoản mới — luôn gán vai trò USER.
  ///
  /// [body] - Name not received - field will be skipped.
  ///
  /// Name not received - field will be skipped.
  @POST('/auth/register')
  Future<TokenResponse> postAuthRegister({
    @Body() required RegisterRequest body,
  });

  /// Đổi refresh token lấy access token mới.
  ///
  /// [body] - Name not received - field will be skipped.
  ///
  /// Name not received - field will be skipped.
  @POST('/auth/refresh')
  Future<TokenResponse> postAuthRefresh({
    @Body() required RefreshRequest body,
  });

  /// Thu hồi refresh token hiện tại.
  ///
  /// Name not received - field will be skipped.
  @POST('/auth/logout')
  Future<EmptyResponse> postAuthLogout();

  /// Hồ sơ user đang đăng nhập — luôn đọc lại từ database, không tin token.
  ///
  /// Name not received - field will be skipped.
  @GET('/auth/me')
  Future<UserResponse> getAuthMe();

  /// Đổi mật khẩu khi đang đăng nhập — thu hồi mọi phiên khác.
  ///
  /// [body] - Name not received - field will be skipped.
  ///
  /// Name not received - field will be skipped.
  @POST('/auth/change-password')
  Future<EmptyResponse> postAuthChangePassword({
    @Body() required ChangePasswordRequest body,
  });

  /// Gửi link đặt lại mật khẩu — LUÔN trả 200 dù email có tồn tại hay không.
  ///
  /// [body] - Name not received - field will be skipped.
  ///
  /// Name not received - field will be skipped.
  @POST('/auth/forgot-password')
  Future<EmptyResponse> postAuthForgotPassword({
    @Body() required ForgotPasswordRequest body,
  });

  /// Đặt lại mật khẩu bằng token trong email.
  ///
  /// [body] - Name not received - field will be skipped.
  ///
  /// Name not received - field will be skipped.
  @POST('/auth/reset-password')
  Future<EmptyResponse> postAuthResetPassword({
    @Body() required ResetPasswordRequest body,
  });

  /// Xác thực email bằng token trong link.
  ///
  /// [body] - Name not received - field will be skipped.
  ///
  /// Name not received - field will be skipped.
  @POST('/auth/verify-email')
  Future<UserResponse> postAuthVerifyEmail({
    @Body() required VerifyEmailRequest body,
  });

  /// Gửi lại email xác thực.
  ///
  /// Name not received - field will be skipped.
  @POST('/auth/verify-email/request')
  Future<EmptyResponse> postAuthVerifyEmailRequest();

  /// Xin đổi email — gửi link xác nhận tới địa chỉ MỚI. Email chỉ đổi thật khi link được bấm; đổi ngay thì gõ nhầm một ký tự là mất đường đăng nhập.
  ///
  /// [body] - Name not received - field will be skipped.
  ///
  /// Name not received - field will be skipped.
  @POST('/auth/change-email')
  Future<EmptyResponse> postAuthChangeEmail({
    @Body() required RequestEmailChangeRequest body,
  });

  /// Xác nhận đổi email bằng token trong link (KHÔNG cần đăng nhập).
  ///
  /// [body] - Name not received - field will be skipped.
  ///
  /// Name not received - field will be skipped.
  @POST('/auth/change-email/confirm')
  Future<UserResponse> postAuthChangeEmailConfirm({
    @Body() required ConfirmEmailChangeRequest body,
  });

  /// Gửi OTP xác thực số điện thoại. ⚠️ MẶC ĐỊNH TẮT (PHONE_VERIFICATION_ENABLED=0) vì mỗi SMS tốn tiền thật.
  ///
  /// [body] - Name not received - field will be skipped.
  ///
  /// Name not received - field will be skipped.
  @POST('/auth/phone/request-otp')
  Future<EmptyResponse> postAuthPhoneRequestOtp({
    @Body() required RequestPhoneOtpRequest body,
  });

  /// Xác nhận OTP số điện thoại.
  ///
  /// [body] - Name not received - field will be skipped.
  ///
  /// Name not received - field will be skipped.
  @POST('/auth/phone/verify')
  Future<UserResponse> postAuthPhoneVerify({
    @Body() required VerifyPhoneOtpRequest body,
  });

  /// Thiết bị đang đăng nhập — CHỈ của chính mình. Response không tự đánh dấu phiên hiện tại: client đối chiếu với `sessionId` nhận được lúc đăng nhập/refresh (access token không mang thông tin đó).
  ///
  /// Name not received - field will be skipped.
  @GET('/auth/sessions')
  Future<SessionsResponse> getAuthSessions();

  /// Đăng xuất MỌI thiết bị khác. Giữ lại phiên hiện tại (nhận ra qua `sid` trong access token) — đăng xuất luôn người đang bấm nút thì họ phải đăng nhập lại ngay.
  ///
  /// Name not received - field will be skipped.
  @DELETE('/auth/sessions')
  Future<EmptyResponse> deleteAuthSessions();

  /// Đăng xuất một thiết bị. Trả 404 cho cả phiên không tồn tại lẫn phiên của người khác — phân biệt hai ca đó là xác nhận id có thật.
  ///
  /// Name not received - field will be skipped.
  @DELETE('/auth/sessions/{id}')
  Future<IdResponse> deleteAuthSessionsId({
    @Path('id') required String id,
  });
}
