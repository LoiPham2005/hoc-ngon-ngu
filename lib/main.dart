import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingua/app.dart';
import 'package:lingua/config/app_initializer.dart';
import 'package:lingua/config/flavor_config.dart';
import 'package:lingua/core/di/global_providers.dart';
import 'package:lingua/core/utils/logger.dart';
import 'package:lingua/shared/states/app_error_screen.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talker_riverpod_logger/talker_riverpod_logger.dart';

/// Một entry cho mọi flavor — chạy `flutter run --flavor dev|stg|prod` (không cần `-t`).
/// Cấu hình theo flavor ở `FlavorConfig.current`.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = FlavorConfig.current;

  final crashOn = config.enableCrashlytics && !kDebugMode;
  final sentryOn = config.sentryDsn.isNotEmpty && crashOn;
  configureTalker(
    enableConsole: config.enableLogging,
    maskSensitive: !FlavorConfig.isDev,
    crashReporting: crashOn,
    sentryEnabled: sentryOn,
  );

  if (sentryOn) {
    await SentryFlutter.init((options) {
      options.dsn = config.sentryDsn;
      options.environment = config.flavor.name;
      options.tracesSampleRate = FlavorConfig.isProd ? 0.2 : 1.0;
      options.attachStacktrace = true;
    });
  }

  // Bắt lỗi NGAY sau Sentry (trước khi khởi động Firebase, Remote Config…) để lỗi lúc boot cũng
  // được ghi. Giữ handler Sentry cài lúc init (chain) → Sentry vẫn capture Flutter error.
  final priorFlutterOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    // Firebase chưa khởi động xong (lỗi rất sớm lúc boot) → bỏ qua Crashlytics, không tự ném lỗi.
    if (crashOn && Firebase.apps.isNotEmpty) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    }
    priorFlutterOnError?.call(details);
  };
  // Lỗi async không ai bắt (thay cho runZonedGuarded — cách Flutter khuyến nghị từ 3.3).
  // talker.error tự đẩy sang Crashlytics + Sentry.
  PlatformDispatcher.instance.onError = (error, stack) {
    talker.error('Platform error', error, stack);
    return true;
  };

  globalContainer = ProviderContainer(
    observers: [
      if (config.enableLogging)
        TalkerRiverpodObserver(
          talker: talker,
          // Chỉ log provider lỗi — add/update/dispose quá ồn.
          settings: const TalkerRiverpodLoggerSettings(
            printProviderAdded: false,
            printProviderUpdated: false,
            printProviderDisposed: false,
          ),
        ),
    ],
    overrides: [
      sharedPrefsProvider.overrideWithValue(
        await SharedPreferences.getInstance(),
      ),
    ],
  );

  await AppInitializer.initialize();

  // Lỗi lúc dựng widget → màn báo lỗi của app thay cho màn đỏ (debug) / ô xám (release).
  // Đặt trước runApp để cả lỗi ở khung hình đầu tiên cũng dùng màn này.
  ErrorWidget.builder = (details) => AppErrorScreen(details: details);
  runApp(const App());
}
