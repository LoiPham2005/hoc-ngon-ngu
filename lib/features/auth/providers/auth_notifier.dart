import 'package:api_client/api_client.dart';
import 'package:lingua/core/di/global_providers.dart';
import 'package:lingua/core/errors/failures.dart';
import 'package:lingua/core/network/api_client_provider.dart';
import 'package:lingua/core/network/dio_provider.dart';
import 'package:lingua/core/riverpod/base_notifier.dart';
import 'package:lingua/core/services/session_notifier.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_notifier.g.dart';

/// User đang đăng nhập (`null` = chưa đăng nhập). Gọi backend qua `api_client`
/// (sinh từ OpenAPI); token lưu qua [SessionNotifier].
@Riverpod(keepAlive: true)
class AuthNotifier extends _$AuthNotifier with BaseNotifier<User?> {
  AuthClient get _api => ref.apiClient.auth;

  @override
  Future<User?> build() async {
    await ref.read(sessionProvider.notifier).ready;
    if (!ref.read(sessionProvider)) return null;
    return (await _api.getAuthMe()).data.user;
  }

  Future<bool> login({required String identifier, required String password}) =>
      run(() async {
        final res = await _api.postAuthLogin(
          body: LoginRequest(identifier: identifier, password: password),
        );
        if (res.toJson()['data'] case {'twoFactorRequired': true}) {
          throw const ServerFailure(
            'Tài khoản đã bật 2FA — app chưa hỗ trợ bước nhập mã',
          );
        }
        return _save(res.toTokenResponse().data);
      });

  Future<bool> register({
    required String email,
    required String password,
    String? fullName,
  }) => run(() async {
    final res = await _api.postAuthRegister(
      body: RegisterRequest(
        email: email,
        password: password,
        fullName: fullName == null || fullName.isEmpty ? null : fullName,
      ),
    );
    return _save(res.data);
  }, successMessage: 'Tạo tài khoản thành công');

  /// Tải lại hồ sơ từ `/auth/me`.
  Future<bool> refreshMe() =>
      run(() async => (await _api.getAuthMe()).data.user);

  /// Thu hồi phiên trên server (lỗi vẫn đăng xuất local). Không có token → chỉ xoá local.
  Future<void> logout() async {
    if (ref.read(sessionProvider)) {
      try {
        // Gửi refreshToken để server thu hồi nó. OpenAPI của backend chưa khai báo body cho
        // /auth/logout nên client sinh ra không có tham số → gọi Dio thẳng. Khi backend bổ sung
        // body vào spec + `make gen-api`, đổi lại `_api.postAuthLogout(body: ...)`.
        final refreshToken = await ref
            .read(secureStorageProvider)
            .read(key: AuthKeys.refreshToken);
        await ref.dio.post<void>(
          '/auth/logout',
          data: {'refreshToken': ?refreshToken},
        );
      } catch (_) {}
    }
    await ref.read(sessionProvider.notifier).logout();
    state = const AsyncData(null);
  }

  Future<User> _save(TokenPair token) async {
    await ref
        .read(sessionProvider.notifier)
        .login(token.accessToken, token.refreshToken);
    return token.user;
  }
}
