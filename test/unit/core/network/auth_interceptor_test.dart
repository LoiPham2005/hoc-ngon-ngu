import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingua/core/network/auth_interceptor.dart';
import 'package:lingua/core/services/session_notifier.dart';

/// Server giả: trả response theo path + Authorization; đếm số lần gọi refresh.
class _FakeServer implements HttpClientAdapter {
  _FakeServer({this.refreshStatus = 200});

  static const validToken = 'new-access';
  final int refreshStatus;
  int refreshCalls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path == '/auth/refresh') {
      refreshCalls++;
      if (refreshStatus != 200) {
        return _json(refreshStatus, {'error': <String, Object>{}});
      }
      return _json(200, {
        'data': {'accessToken': validToken, 'refreshToken': 'new-refresh'},
      });
    }
    final ok = options.headers['Authorization'] == 'Bearer $validToken';
    return ok ? _json(200, {'ok': true}) : _json(401, {});
  }

  ResponseBody _json(int status, Object body) => ResponseBody.fromString(
    jsonEncode(body),
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );

  @override
  void close({bool force = false}) {}
}

void main() {
  const storage = FlutterSecureStorage();
  late _FakeServer server;
  late int expiredCalls;

  Dio buildDio({int refreshStatus = 200}) {
    server = _FakeServer(refreshStatus: refreshStatus);
    expiredCalls = 0;
    final plain = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = server;
    return Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = server
      ..interceptors.add(
        AuthInterceptor(
          storage,
          plainDio: plain,
          onExpired: () async => expiredCalls++,
        ),
      );
  }

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({
      AuthKeys.accessToken: 'old-access',
      AuthKeys.refreshToken: 'old-refresh',
    });
  });

  test('401 → refresh (đọc token trong "data") → gửi lại thành công', () async {
    final dio = buildDio();
    final res = await dio.get<dynamic>('/me');
    expect(res.statusCode, 200);
    expect(server.refreshCalls, 1);
    expect(await storage.read(key: AuthKeys.accessToken), 'new-access');
    expect(await storage.read(key: AuthKeys.refreshToken), 'new-refresh');
    expect(expiredCalls, 0);
  });

  test('nhiều request 401 cùng lúc → chỉ refresh 1 lần', () async {
    final dio = buildDio();
    final results = await Future.wait([
      dio.get<dynamic>('/a'),
      dio.get<dynamic>('/b'),
      dio.get<dynamic>('/c'),
    ]);
    expect(results.every((r) => r.statusCode == 200), isTrue);
    expect(server.refreshCalls, 1);
  });

  test('refresh token hết hạn (401) → đăng xuất', () async {
    final dio = buildDio(refreshStatus: 401);
    await expectLater(dio.get<dynamic>('/me'), throwsA(isA<DioException>()));
    expect(expiredCalls, 1);
  });

  test('refresh lỗi server/mạng (500) → KHÔNG đăng xuất', () async {
    final dio = buildDio(refreshStatus: 500);
    await expectLater(dio.get<dynamic>('/me'), throwsA(isA<DioException>()));
    expect(expiredCalls, 0);
    expect(await storage.read(key: AuthKeys.refreshToken), 'old-refresh');
  });

  test('không có refresh token → đăng xuất, không gọi refresh', () async {
    FlutterSecureStorage.setMockInitialValues({
      AuthKeys.accessToken: 'old-access',
    });
    final dio = buildDio();
    await expectLater(dio.get<dynamic>('/me'), throwsA(isA<DioException>()));
    expect(server.refreshCalls, 0);
    expect(expiredCalls, 1);
  });

  test(
    'chưa đăng nhập (không có token) → 401 trả thẳng, không refresh, không đăng xuất',
    () async {
      FlutterSecureStorage.setMockInitialValues({});
      final dio = buildDio();
      await expectLater(
        dio.post<dynamic>('/auth/logout'),
        throwsA(isA<DioException>()),
      );
      expect(server.refreshCalls, 0);
      expect(expiredCalls, 0);
    },
  );

  test('endpoint public không gắn token, không refresh', () async {
    final dio = buildDio();
    await expectLater(
      dio.post<dynamic>('/auth/login'),
      throwsA(isA<DioException>()),
    );
    expect(server.refreshCalls, 0);
  });
}
