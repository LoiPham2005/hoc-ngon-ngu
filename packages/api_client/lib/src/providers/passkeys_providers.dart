// GENERATED CODE - DO NOT MODIFY BY HAND
// Sinh bởi gen_api.dart — chạy lại `make gen-api` là bị ghi đè.
// ignore_for_file: type=lint

import 'dart:async';

import 'package:api_client/api_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'passkeys_providers.g.dart';

/// Danh sách passkey của tài khoản hiện tại.
@riverpod
Future<PasskeysListResponse> getAuthPasskeys(Ref ref) =>
    ref.watch(restClientProvider).passkeys.getAuthPasskeys();

/// Thao tác GHI nhóm `passkeys`. State = đang chạy / lỗi của lần gọi gần nhất; lỗi được NÉM LẠI cho
/// nơi gọi. Thành công thì làm mới mọi provider GET của nhóm.
///
/// `await ref.read(passkeysActionsProvider.notifier).<method>(...)`
@Riverpod(keepAlive: true)
class PasskeysActions extends _$PasskeysActions {
  @override
  FutureOr<void> build() {}

  PasskeysClient get _api => ref.read(restClientProvider).passkeys;

  Future<R> _run<R>(Future<R> Function() call) async {
    state = const AsyncLoading();
    try {
      final result = await call();
      if (ref.mounted) {
        state = const AsyncData(null);
        ref.invalidate(getAuthPasskeysProvider);
      }
      return result;
    } catch (e, st) {
      if (ref.mounted) state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Bước 1 — tuỳ chọn cho navigator.credentials.create().
  Future<WebAuthnOptionsResponse> postAuthPasskeysRegisterOptions() =>
      _run(() => _api.postAuthPasskeysRegisterOptions());

  /// Bước 2 — xác minh và lưu passkey.
  Future<PasskeyResponse> postAuthPasskeysRegisterVerify({
    required RegisterPasskeyRequest body,
  }) => _run(() => _api.postAuthPasskeysRegisterVerify(body: body));

  /// Bước 1 — tuỳ chọn cho navigator.credentials.get(). KHÔNG nhận tham số: bắt nhập email trước vừa thừa một bước, vừa biến endpoint thành công cụ dò xem email nào đã đăng ký.
  Future<WebAuthnOptionsResponse> postAuthPasskeysLoginOptions() =>
      _run(() => _api.postAuthPasskeysLoginOptions());

  /// Bước 2 — đăng nhập bằng passkey. Không cần mật khẩu và KHÔNG hỏi thêm 2FA: passkey với userVerification=required đã là hai yếu tố.
  Future<TokenResponse> postAuthPasskeysLoginVerify({
    required LoginPasskeyRequest body,
  }) => _run(() => _api.postAuthPasskeysLoginVerify(body: body));

  /// Đổi tên passkey.
  Future<PasskeyResponse> patchAuthPasskeysId({
    required String id,
    required RenamePasskeyRequest body,
  }) => _run(() => _api.patchAuthPasskeysId(id: id, body: body));

  /// Xoá passkey — từ chối nếu đây là cách đăng nhập CUỐI CÙNG.
  Future<IdResponse> deleteAuthPasskeysId({required String id}) =>
      _run(() => _api.deleteAuthPasskeysId(id: id));
}
