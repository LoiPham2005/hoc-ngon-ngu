// GENERATED CODE - DO NOT MODIFY BY HAND
// Sinh bởi gen_api.dart — chạy lại `make gen-api` là bị ghi đè.
// ignore_for_file: type=lint

import 'dart:async';

import 'package:api_client/api_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'o_auth_providers.g.dart';

/// Nhà cung cấp ĐÃ cấu hình — màn đăng nhập dùng để biết vẽ nút nào.
@riverpod
Future<OAuthProvidersResponse> getAuthOauthProviders(Ref ref) =>
    ref.watch(restClientProvider).oAuth.getAuthOauthProviders();

/// Tài khoản mạng xã hội đã liên kết.
@riverpod
Future<OAuthLinkedResponse> getAuthOauthLinked(Ref ref) =>
    ref.watch(restClientProvider).oAuth.getAuthOauthLinked();

/// Bắt đầu luồng OAuth — trả 302 tới nhà cung cấp. Mở bằng TRÌNH DUYỆT (hoặc Custom Tab / ASWebAuthenticationSession trên mobile), không phải bằng fetch: nhà cung cấp cần một phiên trình duyệt thật.
@riverpod
Future<void> getAuthOauthProviderStart(Ref ref, {required String provider}) =>
    ref
        .watch(restClientProvider)
        .oAuth
        .getAuthOauthProviderStart(provider: provider);

/// Nhà cung cấp gọi lại sau khi người dùng đồng ý. Trả 302 về ứng dụng — KHÔNG trả JSON, vì đích đến là thanh địa chỉ của trình duyệt.
@riverpod
Future<void> getAuthOauthProviderCallback(
  Ref ref, {
  required String provider,
  String? code,
  String? state,
  String? error,
}) => ref
    .watch(restClientProvider)
    .oAuth
    .getAuthOauthProviderCallback(
      provider: provider,
      code: code,
      state: state,
      error: error,
    );

/// Thao tác GHI nhóm `oAuth`. State = đang chạy / lỗi của lần gọi gần nhất; lỗi được NÉM LẠI cho
/// nơi gọi. Thành công thì làm mới mọi provider GET của nhóm.
///
/// `await ref.read(oAuthActionsProvider.notifier).<method>(...)`
@Riverpod(keepAlive: true)
class OAuthActions extends _$OAuthActions {
  @override
  FutureOr<void> build() {}

  OAuthClient get _api => ref.read(restClientProvider).oAuth;

  Future<R> _run<R>(Future<R> Function() call) async {
    state = const AsyncLoading();
    try {
      final result = await call();
      if (ref.mounted) {
        state = const AsyncData(null);
        ref.invalidate(getAuthOauthProvidersProvider);
        ref.invalidate(getAuthOauthLinkedProvider);
        ref.invalidate(getAuthOauthProviderStartProvider);
        ref.invalidate(getAuthOauthProviderCallbackProvider);
      }
      return result;
    } catch (e, st) {
      if (ref.mounted) state = AsyncError(e, st);
      rethrow;
    }
  }

  /// POST — `oAuth.postAuthOauthProviderCallback`.
  Future<void> postAuthOauthProviderCallback({
    required String provider,
    required AuthOauthProviderCallbackRequest body,
  }) => _run(
    () => _api.postAuthOauthProviderCallback(provider: provider, body: body),
  );

  /// Gỡ liên kết — từ chối nếu đây là cách đăng nhập cuối cùng.
  Future<EmptyResponse> deleteAuthOauthProvider({required String provider}) =>
      _run(() => _api.deleteAuthOauthProvider(provider: provider));
}
