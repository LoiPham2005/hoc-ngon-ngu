import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingua/app.dart';
import 'package:lingua/config/app_initializer.dart';
import 'package:lingua/config/flavor_config.dart';
import 'package:lingua/core/di/global_providers.dart';
import 'package:lingua/core/utils/logger.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talker_riverpod_logger/talker_riverpod_logger.dart';

/// Một entry cho mọi flavor — chạy `flutter run --flavor dev|stg|prod` (không cần `-t`).
/// Cấu hình theo flavor ở `FlavorConfig.current`.
Future<void> main() async {
  // `ensureInitialized` và `runApp` PHẢI cùng zone → Sentry init không dùng appRunner.
  await runZonedGuarded<Future<void>>(() async {
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

    // Giữ handler Sentry cài lúc init (chain) → Sentry vẫn capture Flutter error.
    final priorFlutterOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      if (crashOn) {
        FirebaseCrashlytics.instance.recordFlutterFatalError(details);
      }
      priorFlutterOnError?.call(details);
    };
    // talker.error tự đẩy sang Crashlytics + Sentry.
    PlatformDispatcher.instance.onError = (error, stack) {
      talker.error('Platform error', error, stack);
      return true;
    };

    runApp(const App());
  }, (error, stack) => talker.error('Zoned error', error, stack));
}
