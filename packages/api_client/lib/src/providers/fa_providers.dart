// GENERATED CODE - DO NOT MODIFY BY HAND
// Sinh bởi gen_api.dart — chạy lại `make gen-api` là bị ghi đè.
// ignore_for_file: type=lint

import 'dart:async';

import 'package:api_client/api_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'fa_providers.g.dart';

/// Trạng thái 2FA của tài khoản hiện tại.
@riverpod
Future<TwoFactorStatusResponse> getAuth2fa(Ref ref) =>
    ref.watch(restClientProvider).fa.getAuth2fa();

/// Thao tác GHI nhóm `fa`. State = đang chạy / lỗi của lần gọi gần nhất; lỗi được NÉM LẠI cho
/// nơi gọi. Thành công thì làm mới mọi provider GET của nhóm.
///
/// `await ref.read(faActionsProvider.notifier).<method>(...)`
@Riverpod(keepAlive: true)
class FaActions extends _$FaActions {
  @override
  FutureOr<void> build() {}

  FaClient get _api => ref.read(restClientProvider).fa;

  Future<R> _run<R>(Future<R> Function() call) async {
    state = const AsyncLoading();
    try {
      final result = await call();
      if (ref.mounted) {
        state = const AsyncData(null);
        ref.invalidate(getAuth2faProvider);
      }
      return result;
    } catch (e, st) {
      if (ref.mounted) state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Tắt 2FA — cần mật khẩu và một mã hợp lệ.
  Future<EmptyResponse> deleteAuth2fa({
    required DisableTwoFactorRequest body,
  }) => _run(() => _api.deleteAuth2fa(body: body));

  /// Bước 1 — sinh bí mật và URI cho mã QR (CHƯA bật).
  Future<TwoFactorSetupResponse> postAuth2faSetup() =>
      _run(() => _api.postAuth2faSetup());

  /// Bước 3 — xác nhận mã và bật 2FA, trả về mã khôi phục (chỉ hiện MỘT lần).
  Future<RecoveryCodesResponse> postAuth2faEnable({
    required ConfirmTwoFactorRequest body,
  }) => _run(() => _api.postAuth2faEnable(body: body));

  /// Cấp lại bộ mã khôi phục — mã cũ mất hiệu lực ngay.
  Future<RecoveryCodesResponse> postAuth2faRecoveryCodes({
    required ConfirmTwoFactorRequest body,
  }) => _run(() => _api.postAuth2faRecoveryCodes(body: body));

  /// Đổi vé 2FA + mã lấy token thật (KHÔNG cần access token).
  Future<TokenResponse> postAuth2faVerify({
    required VerifyTwoFactorRequest body,
  }) => _run(() => _api.postAuth2faVerify(body: body));
}
