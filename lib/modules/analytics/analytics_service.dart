import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:lingua/config/flavor_config.dart';
import 'package:lingua/core/utils/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'analytics_service.g.dart';

/// Firebase Analytics. Flavor dev không gửi gì (tránh bẩn số liệu).
class AnalyticsService {
  bool get _enabled => !FlavorConfig.isDev;

  /// Param `null` tự bị bỏ (Firebase không nhận null).
  Future<void> logEvent(String name, [Map<String, Object?>? params]) async {
    if (!_enabled) return;
    try {
      await FirebaseAnalytics.instance.logEvent(
        name: name,
        parameters: params == null
            ? null
            : {
                for (final e in params.entries)
                  if (e.value != null) e.key: e.value!,
              },
      );
    } catch (e, s) {
      talker.error('Analytics logEvent "$name" failed', e, s);
    }
  }

  Future<void> logScreenView(String screenName) =>
      logEvent('screen_view', {'screen_name': screenName});

  Future<void> setUserId(String? id) async {
    if (!_enabled) return;
    try {
      await FirebaseAnalytics.instance.setUserId(id: id);
    } catch (e, s) {
      talker.error('Analytics setUserId failed', e, s);
    }
  }

  /// Doanh thu quảng cáo theo chuẩn Firebase (event `ad_impression`).
  Future<void> logAdRevenue({
    required double valueMicros,
    required String currency,
    required String adUnitName,
    required String adFormat,
  }) => logEvent('ad_impression', {
    'value': valueMicros / 1000000,
    'currency': currency,
    'ad_platform': 'AdMob',
    'ad_source': 'AdMob',
    'ad_unit_name': adUnitName,
    'ad_format': adFormat,
  });
}

@Riverpod(keepAlive: true)
AnalyticsService analyticsService(Ref ref) => AnalyticsService();
