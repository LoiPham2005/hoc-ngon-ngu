import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:lingua/config/flavor_config.dart';
import 'package:lingua/core/di/global_providers.dart';
import 'package:lingua/core/network/auth_interceptor.dart';
import 'package:lingua/core/utils/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:talker_dio_logger/talker_dio_logger.dart';

part 'dio_provider.g.dart';

@Riverpod(keepAlive: true)
Dio dio(Ref ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: FlavorConfig.current.apiBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: const {'Accept': 'application/json'},
    ),
  );
  dio.interceptors.addAll([
    AuthInterceptor(ref.read(secureStorageProvider)),
    RetryInterceptor(dio: dio, retries: 2, logPrint: talker.debug),
    TalkerDioLogger(
      talker: talker,
      // 1 dòng / request, body chỉ in khi lỗi; không in header (ẩn Authorization).
      settings: const TalkerDioLoggerSettings(
        printRequestData: false,
        printResponseData: false,
        printErrorHeaders: false, // lỗi chỉ in status + body
        printErrorMessage: false, // bỏ đoạn giải thích dài của Dio
      ),
    ),
  ]);
  return dio;
}

/// Viết tắt `ref.read(dioProvider)`.
extension RefDioX on Ref {
  Dio get dio => read(dioProvider);
}
