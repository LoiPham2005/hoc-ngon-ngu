import 'dart:io';

import 'package:dio/dio.dart';
import 'package:lingua/core/errors/failures.dart';

abstract class ErrorHandler {
  static Failure handle(Object error) {
    if (error is Failure) return error;
    if (error is SocketException) return const NetworkFailure();
    if (error is DioException) return _fromDio(error);
    return UnknownFailure(error.toString());
  }

  static Failure _fromDio(DioException e) {
    // ⚡ Dio đôi khi bọc SocketException (mất mạng) vào bất kỳ type nào
    // (thường `unknown`/`connectionError`) → check trước, hiện đúng "mất mạng".
    if (e.error is SocketException) return const NetworkFailure();

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const NetworkFailure('Kết nối quá hạn');
      case DioExceptionType.connectionError:
        return const NetworkFailure();
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode;
        if (code == 401) {
          final msg = _extractMessage(e.response?.data);
          return msg == null
              ? const UnauthorizedFailure()
              : UnauthorizedFailure(msg);
        }
        return ServerFailure(
          _extractMessage(e.response?.data) ?? 'Lỗi server',
          code: code,
        );
      case DioExceptionType.cancel:
        return const UnknownFailure('Yêu cầu bị huỷ');
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        return UnknownFailure(e.message ?? 'Lỗi không xác định');
    }
  }

  /// Đọc message lỗi từ body: chuẩn `{"error": {"message"}}`, hoặc `message` / `error` dạng chuỗi.
  static String? _extractMessage(Object? data) {
    if (data is! Map) return null;
    final error = data['error'];
    final msg = error is Map ? error['message'] : data['message'] ?? error;
    return msg is String && msg.isNotEmpty ? msg : null;
  }
}
