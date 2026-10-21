// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart' hide Headers;
import 'package:retrofit/retrofit.dart';
import 'package:retrofit/error_logger.dart';

import '../models/confirm_two_factor_request.dart';
import '../models/disable_two_factor_request.dart';
import '../models/empty_response.dart';
import '../models/recovery_codes_response.dart';
import '../models/token_response.dart';
import '../models/two_factor_setup_response.dart';
import '../models/two_factor_status_response.dart';
import '../models/verify_two_factor_request.dart';

part 'fa_client.g.dart';

@RestApi()
abstract class FaClient {
  factory FaClient(Dio dio, {String? baseUrl}) = _FaClient;

  /// Trạng thái 2FA của tài khoản hiện tại.
  ///
  /// Name not received - field will be skipped.
  @GET('/auth/2fa')
  Future<TwoFactorStatusResponse> getAuth2fa();

  /// Tắt 2FA — cần mật khẩu và một mã hợp lệ.
  ///
  /// [body] - Name not received - field will be skipped.
  ///
  /// Name not received - field will be skipped.
  @DELETE('/auth/2fa')
  Future<EmptyResponse> deleteAuth2fa({
    @Body() required DisableTwoFactorRequest body,
  });

  /// Bước 1 — sinh bí mật và URI cho mã QR (CHƯA bật).
  ///
  /// Name not received - field will be skipped.
  @POST('/auth/2fa/setup')
  Future<TwoFactorSetupResponse> postAuth2faSetup();

  /// Bước 3 — xác nhận mã và bật 2FA, trả về mã khôi phục (chỉ hiện MỘT lần).
  ///
  /// [body] - Name not received - field will be skipped.
  ///
  /// Name not received - field will be skipped.
  @POST('/auth/2fa/enable')
  Future<RecoveryCodesResponse> postAuth2faEnable({
    @Body() required ConfirmTwoFactorRequest body,
  });

  /// Cấp lại bộ mã khôi phục — mã cũ mất hiệu lực ngay.
  ///
  /// [body] - Name not received - field will be skipped.
  ///
  /// Name not received - field will be skipped.
  @POST('/auth/2fa/recovery-codes')
  Future<RecoveryCodesResponse> postAuth2faRecoveryCodes({
    @Body() required ConfirmTwoFactorRequest body,
  });

  /// Đổi vé 2FA + mã lấy token thật (KHÔNG cần access token).
  ///
  /// [body] - Name not received - field will be skipped.
  ///
  /// Name not received - field will be skipped.
  @POST('/auth/2fa/verify')
  Future<TokenResponse> postAuth2faVerify({
    @Body() required VerifyTwoFactorRequest body,
  });
}
