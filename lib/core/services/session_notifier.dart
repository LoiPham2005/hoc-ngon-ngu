import 'dart:async';

import 'package:lingua/core/di/global_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'session_notifier.g.dart';

/// Key lưu token trong secure storage.
abstract class AuthKeys {
  static const accessToken = 'access_token';
  static const refreshToken = 'refresh_token';
}

/// Trạng thái đăng nhập toàn app (`true` = có access token).
@Riverpod(keepAlive: true)
class SessionNotifier extends _$SessionNotifier {
  /// Xong khi đã đọc token lần đầu — guard/splash `await ready` trước khi đọc state,
  /// tránh đẩy nhầm user đã login về Login lúc cold start.
  final Completer<void> _restored = Completer<void>();
  Future<void> get ready => _restored.future;

  @override
  bool build() {
    _restore();
    return false;
  }

  Future<void> _restore() async {
    try {
      final token = await ref
          .read(secureStorageProvider)
          .read(key: AuthKeys.accessToken);
      state = token != null && token.isNotEmpty;
    } finally {
      if (!_restored.isCompleted) _restored.complete();
    }
  }

  Future<void> login(String accessToken, [String? refreshToken]) async {
    final storage = ref.read(secureStorageProvider);
    await storage.write(key: AuthKeys.accessToken, value: accessToken);
    if (refreshToken != null) {
      await storage.write(key: AuthKeys.refreshToken, value: refreshToken);
    }
    state = true;
  }

  /// Chỉ xoá auth keys (không `deleteAll` để giữ key khác trong secure storage).
  Future<void> logout() async {
    final storage = ref.read(secureStorageProvider);
    await storage.delete(key: AuthKeys.accessToken);
    await storage.delete(key: AuthKeys.refreshToken);
    state = false;
  }
}
