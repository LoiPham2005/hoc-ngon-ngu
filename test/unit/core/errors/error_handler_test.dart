import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingua/core/errors/error_handler.dart';
import 'package:lingua/core/errors/failures.dart';

DioException _dio(
  DioExceptionType type, {
  int? statusCode,
  Object? data,
  Object? error,
  String? message,
}) {
  final req = RequestOptions(path: '/test');
  return DioException(
    requestOptions: req,
    type: type,
    error: error,
    message: message,
    response: statusCode == null && data == null
        ? null
        : Response<Object?>(
            requestOptions: req,
            statusCode: statusCode,
            data: data,
          ),
  );
}

void main() {
  group('ErrorHandler.handle — passthrough & exception mapping', () {
    test('Failure đi qua nguyên vẹn (không bọc lại)', () {
      const f = ServerFailure('boom', code: 500);
      expect(ErrorHandler.handle(f), same(f));
    });

    test('SocketException trần → NetworkFailure', () {
      expect(
        ErrorHandler.handle(const SocketException('no route')),
        isA<NetworkFailure>(),
      );
    });

    test('lỗi lạ → UnknownFailure với toString', () {
      final r = ErrorHandler.handle(const FormatException('bad'));
      expect(r, isA<UnknownFailure>());
      expect(r.message, contains('bad'));
    });
  });

  group('ErrorHandler._fromDio — qua handle(DioException)', () {
    test('SocketException bọc trong DioException → NetworkFailure', () {
      final r = ErrorHandler.handle(
        _dio(DioExceptionType.unknown, error: const SocketException('x')),
      );
      expect(r, isA<NetworkFailure>());
    });

    test('mọi loại timeout → NetworkFailure "Kết nối quá hạn"', () {
      for (final t in [
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
        DioExceptionType.transformTimeout,
      ]) {
        final r = ErrorHandler.handle(_dio(t));
        expect(r, isA<NetworkFailure>(), reason: '$t');
        expect(r.message, 'Kết nối quá hạn', reason: '$t');
      }
    });

    test('connectionError → NetworkFailure', () {
      expect(
        ErrorHandler.handle(_dio(DioExceptionType.connectionError)),
        isA<NetworkFailure>(),
      );
    });

    test('badResponse 401 → UnauthorizedFailure', () {
      final r = ErrorHandler.handle(
        _dio(DioExceptionType.badResponse, statusCode: 401),
      );
      expect(r, isA<UnauthorizedFailure>());
    });

    test('badResponse 500 → ServerFailure + trích message từ body', () {
      final r = ErrorHandler.handle(
        _dio(
          DioExceptionType.badResponse,
          statusCode: 500,
          data: {'message': 'server sập'},
        ),
      );
      expect(r, isA<ServerFailure>());
      expect(r.code, 500);
      expect(r.message, 'server sập');
    });

    test('badResponse chuẩn {error: {code, message}}', () {
      final r = ErrorHandler.handle(
        _dio(
          DioExceptionType.badResponse,
          statusCode: 422,
          data: {
            'error': {'code': 'VALIDATION', 'message': 'Email không hợp lệ'},
          },
        ),
      );
      expect(r.message, 'Email không hợp lệ');
    });

    test('badResponse trích key "error" khi thiếu "message"', () {
      final r = ErrorHandler.handle(
        _dio(
          DioExceptionType.badResponse,
          statusCode: 400,
          data: {'error': 'sai param'},
        ),
      );
      expect(r.message, 'sai param');
    });

    test('badResponse body không phải map → message mặc định', () {
      final r = ErrorHandler.handle(
        _dio(DioExceptionType.badResponse, statusCode: 502, data: 'html...'),
      );
      expect(r, isA<ServerFailure>());
      expect(r.message, 'Lỗi server');
    });

    test('cancel → UnknownFailure "Yêu cầu bị huỷ"', () {
      final r = ErrorHandler.handle(_dio(DioExceptionType.cancel));
      expect(r, isA<UnknownFailure>());
      expect(r.message, 'Yêu cầu bị huỷ');
    });

    test('unknown → UnknownFailure giữ message của Dio', () {
      final r = ErrorHandler.handle(
        _dio(DioExceptionType.unknown, message: 'weird'),
      );
      expect(r, isA<UnknownFailure>());
      expect(r.message, 'weird');
    });
  });
}
