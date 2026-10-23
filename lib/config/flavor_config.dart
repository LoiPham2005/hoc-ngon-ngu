import 'package:flutter/services.dart';

/// Tên phải trùng flavor trong `flavorizr.yaml`.
enum AppFlavor { dev, stg, prod }

/// Cấu hình theo flavor — tự lấy từ `--flavor dev|stg|prod` (`appFlavor` của Flutter),
/// thiếu `--flavor` thì dùng dev. Đọc ở bất kỳ đâu: `FlavorConfig.current.apiBaseUrl`.
class FlavorConfig {
  const FlavorConfig._({
    required this.flavor,
    required this.apiBaseUrl,
    required this.enableLogging,
    required this.enableCrashlytics,
    required this.useRemoteConfig,
    this.sentryDsn = '',
  });

  final AppFlavor flavor;
  final String apiBaseUrl;
  final bool enableLogging;
  final bool enableCrashlytics;

  /// Đọc cấu hình (ads, app_config…) từ Firebase Remote Config của project flavor đó.
  /// `false` → module dùng cấu hình local (ads: `kDevAdConfig` test ID Google).
  final bool useRemoteConfig;

  /// Rỗng = tắt Sentry.
  final String sentryDsn;

  static final FlavorConfig current =
      switch (AppFlavor.values.asNameMap()[appFlavor] ?? AppFlavor.dev) {
        AppFlavor.dev => const FlavorConfig._(
          flavor: AppFlavor.dev,
          apiBaseUrl: 'https://next-base.deploybox.io.vn/api/v1',
          enableLogging: true,
          enableCrashlytics: false,
          useRemoteConfig:
              false, // true = test cấu hình trên Remote Config của project dev
        ),
        AppFlavor.stg => const FlavorConfig._(
          flavor: AppFlavor.stg,
          apiBaseUrl: 'https://next-base.deploybox.io.vn/api/v1',
          enableLogging: true,
          enableCrashlytics: true,
          useRemoteConfig: false,
          sentryDsn: '', // điền DSN Sentry
        ),
        AppFlavor.prod => const FlavorConfig._(
          flavor: AppFlavor.prod,
          apiBaseUrl: 'https://api.example.com',
          enableLogging: false,
          enableCrashlytics: true,
          useRemoteConfig: false,
          sentryDsn: '', // điền DSN Sentry
        ),
      };

  static bool get isDev => current.flavor == AppFlavor.dev;
  static bool get isStg => current.flavor == AppFlavor.stg;
  static bool get isProd => current.flavor == AppFlavor.prod;
}
