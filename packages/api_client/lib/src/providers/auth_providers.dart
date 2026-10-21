// GENERATED CODE - DO NOT MODIFY BY HAND
// Sinh bởi gen_api.dart — chạy lại `make gen-api` là bị ghi đè.
// ignore_for_file: type=lint

import 'dart:async';

import 'package:api_client/api_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_providers.g.dart';

/// Hồ sơ user đang đăng nhập — luôn đọc lại từ database, không tin token.
@riverpod
Future<UserResponse> getAuthMe(Ref ref) =>
    ref.watch(restClientProvider).auth.getAuthMe();

/// Thiết bị đang đăng nhập — CHỈ của chính mình. Response không tự đánh dấu phiên hiện tại: client đối chiếu với `sessionId` nhận được lúc đăng nhập/refresh (access token không mang thông tin đó).
@riverpod
Future<SessionsResponse> getAuthSessions(Ref ref) =>
    ref.watch(restClientProvider).auth.getAuthSessions();

/// Thao tác GHI nhóm `auth`. State = đang chạy / lỗi của lần gọi gần nhất; lỗi được NÉM LẠI cho
/// nơi gọi. Thành công thì làm mới mọi provider GET của nhóm.
///
/// `await ref.read(authActionsProvider.notifier).<method>(...)`
@Riverpod(keepAlive: true)
class AuthActions extends _$AuthActions {
  @override
  FutureOr<void> build() {}

  AuthClient get _api => ref.read(restClientProvider).auth;

  Future<R> _run<R>(Future<R> Function() call) async {
    state = const AsyncLoading();
    try {
      final result = await call();
      if (ref.mounted) {
        state = const AsyncData(null);
        ref.invalidate(getAuthMeProvider);
        ref.invalidate(getAuthSessionsProvider);
      }
      return result;
    } catch (e, st) {
      if (ref.mounted) state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Đăng nhập — trả về token, HOẶC vé 2FA nếu tài khoản đã bật.
  Future<AuthLoginResponse> postAuthLogin({required LoginRequest body}) =>
      _run(() => _api.postAuthLogin(body: body));

  /// Tạo tài khoản mới — luôn gán vai trò USER.
  Future<TokenResponse> postAuthRegister({required RegisterRequest body}) =>
      _run(() => _api.postAuthRegister(body: body));

  /// Đổi refresh token lấy access token mới.
  Future<TokenResponse> postAuthRefresh({required RefreshRequest body}) =>
      _run(() => _api.postAuthRefresh(body: body));

  /// Thu hồi refresh token hiện tại.
  Future<EmptyResponse> postAuthLogout() => _run(() => _api.postAuthLogout());

  /// Đổi mật khẩu khi đang đăng nhập — thu hồi mọi phiên khác.
  Future<EmptyResponse> postAuthChangePassword({
    required ChangePasswordRequest body,
  }) => _run(() => _api.postAuthChangePassword(body: body));

  /// Gửi link đặt lại mật khẩu — LUÔN trả 200 dù email có tồn tại hay không.
  Future<EmptyResponse> postAuthForgotPassword({
    required ForgotPasswordRequest body,
  }) => _run(() => _api.postAuthForgotPassword(body: body));

  /// Đặt lại mật khẩu bằng token trong email.
  Future<EmptyResponse> postAuthResetPassword({
    required ResetPasswordRequest body,
  }) => _run(() => _api.postAuthResetPassword(body: body));

  /// Xác thực email bằng token trong link.
  Future<UserResponse> postAuthVerifyEmail({
    required VerifyEmailRequest body,
  }) => _run(() => _api.postAuthVerifyEmail(body: body));

  /// Gửi lại email xác thực.
  Future<EmptyResponse> postAuthVerifyEmailRequest() =>
      _run(() => _api.postAuthVerifyEmailRequest());

  /// Xin đổi email — gửi link xác nhận tới địa chỉ MỚI. Email chỉ đổi thật khi link được bấm; đổi ngay thì gõ nhầm một ký tự là mất đường đăng nhập.
  Future<EmptyResponse> postAuthChangeEmail({
    required RequestEmailChangeRequest body,
  }) => _run(() => _api.postAuthChangeEmail(body: body));

  /// Xác nhận đổi email bằng token trong link (KHÔNG cần đăng nhập).
  Future<UserResponse> postAuthChangeEmailConfirm({
    required ConfirmEmailChangeRequest body,
  }) => _run(() => _api.postAuthChangeEmailConfirm(body: body));

  /// Gửi OTP xác thực số điện thoại. ⚠️ MẶC ĐỊNH TẮT (PHONE_VERIFICATION_ENABLED=0) vì mỗi SMS tốn tiền thật.
  Future<EmptyResponse> postAuthPhoneRequestOtp({
    required RequestPhoneOtpRequest body,
  }) => _run(() => _api.postAuthPhoneRequestOtp(body: body));

  /// Xác nhận OTP số điện thoại.
  Future<UserResponse> postAuthPhoneVerify({
    required VerifyPhoneOtpRequest body,
  }) => _run(() => _api.postAuthPhoneVerify(body: body));

  /// Đăng xuất MỌI thiết bị khác. Giữ lại phiên hiện tại (nhận ra qua `sid` trong access token) — đăng xuất luôn người đang bấm nút thì họ phải đăng nhập lại ngay.
  Future<EmptyResponse> deleteAuthSessions() =>
      _run(() => _api.deleteAuthSessions());

  /// Đăng xuất một thiết bị. Trả 404 cho cả phiên không tồn tại lẫn phiên của người khác — phân biệt hai ca đó là xác nhận id có thật.
  Future<IdResponse> deleteAuthSessionsId({required String id}) =>
      _run(() => _api.deleteAuthSessionsId(id: id));
}
