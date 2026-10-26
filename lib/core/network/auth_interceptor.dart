import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lingua/config/flavor_config.dart';
import 'package:lingua/core/di/global_providers.dart';
import 'package:lingua/core/services/session_notifier.dart';
import 'package:lingua/core/utils/logger.dart';

enum _Refresh { ok, invalid, failed }

/// Gắn Bearer token + tự refresh khi gặp 401.
/// - Nhiều request 401 cùng lúc → chỉ refresh 1 lần, các request khác chờ chung.
/// - Request gửi bằng token cũ về muộn (token đã được làm mới) → gửi lại luôn, không refresh nữa.
/// - Refresh token hết hạn / bị thu hồi (401, 403) hoặc không có → đăng xuất (app tự về Login).
/// - Refresh lỗi do mạng / timeout / 429 → giữ phiên, chỉ trả lỗi cho request đó.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(
    this._storage, {
    Dio? plainDio,
    Future<void> Function()? onExpired,
  }) : _plain = plainDio ?? _defaultDio(),
       _onExpired =
           onExpired ??
           (() => globalContainer.read(sessionProvider.notifier).logout());

  final FlutterSecureStorage _storage;

  static const _refreshPath = '/auth/refresh';

  /// Endpoint không gắn token và không tự refresh khi 401
  /// (vd đăng nhập sai mật khẩu trả 401 → báo lỗi, không đòi refresh).
  static const _publicPaths = {
    '/auth/login',
    '/auth/register',
    _refreshPath,
    '/auth/forgot-password',
    '/auth/reset-password',
  };

  /// Dio không gắn interceptor — dùng gọi refresh + gửi lại request (tránh lặp vô hạn).
  final Dio _plain;
  final Future<void> Function() _onExpired;
  static Future<_Refresh>? _refreshing;

  static Dio _defaultDio() => Dio(
    BaseOptions(
      baseUrl: FlavorConfig.current.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: const {'Accept': 'application/json'},
    ),
  );

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_isPublic(options.path)) {
      final token = await _storage.read(key: AuthKeys.accessToken);
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final req = err.requestOptions;
    if (err.response?.statusCode != 401 ||
        _isPublic(req.path) ||
        req.extra['_retried'] == true) {
      return handler.next(err);
    }

    // Chưa đăng nhập (không có token) → không có gì để refresh.
    final current = await _storage.read(key: AuthKeys.accessToken);
    if (current == null || current.isEmpty) return handler.next(err);

    // Token đã được request khác làm mới trong lúc request này đang chạy → chỉ cần gửi lại.
    if (req.headers['Authorization'] == 'Bearer $current') {
      final result = await (_refreshing ??= _refresh().whenComplete(
        () => _refreshing = null,
      ));
      if (result == _Refresh.invalid) await _onExpired();
      if (result != _Refresh.ok) return handler.next(err);
    }

    try {
      final token = await _storage.read(key: AuthKeys.accessToken);
      req.headers['Authorization'] = 'Bearer $token';
      req.extra['_retried'] = true;
      return handler.resolve(await _plain.fetch<dynamic>(req));
    } on DioException catch (e) {
      return handler.next(e);
    }
  }

  Future<_Refresh> _refresh() async {
    final refreshToken = await _storage.read(key: AuthKeys.refreshToken);
    if (refreshToken == null || refreshToken.isEmpty) return _Refresh.invalid;
    try {
      final res = await _plain.post<Map<String, dynamic>>(
        _refreshPath,
        data: {'refreshToken': refreshToken},
      );
      // Backend trả `{ "data": { "accessToken", "refreshToken", ... } }`.
      final data = res.data?['data'];
      final access = data is Map ? data['accessToken'] : null;
      if (access is! String || access.isEmpty) {
        talker.warning('[AUTH] Refresh trả về không có accessToken');
        return _Refresh.failed;
      }
      await _storage.write(key: AuthKeys.accessToken, value: access);
      final refresh = data['refreshToken'];
      if (refresh is String && refresh.isNotEmpty) {
        await _storage.write(key: AuthKeys.refreshToken, value: refresh);
      }
      return _Refresh.ok;
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 401 || code == 403) return _Refresh.invalid;
      talker.warning('[AUTH] Refresh lỗi (${code ?? e.type.name}) → giữ phiên');
      return _Refresh.failed;
    }
  }

  /// Khớp chính xác path public (tránh `/users/login` khớp nhầm `/login`).
  bool _isPublic(String path) => _publicPaths.any(
    (p) => path == p || path.startsWith('$p?') || path.startsWith('$p/'),
  );
}
