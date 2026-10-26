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

  /// Màn đang xem — `AnalyticsRouteObserver` tự gọi mỗi lần chuyển màn, không cần gọi tay.
  Future<void> logScreenView(String screenName) async {
    if (!_enabled) return;
    try {
      await FirebaseAnalytics.instance.logScreenView(
        screenName: screenName,
        screenClass: screenName,
      );
    } catch (e, s) {
      talker.error('Analytics logScreenView "$screenName" failed', e, s);
    }
  }

  Future<void> setUserId(String? id) async {
    if (!_enabled) return;
    try {
      await FirebaseAnalytics.instance.setUserId(id: id);
    } catch (e, s) {
      talker.error('Analytics setUserId failed', e, s);
    }
  }
}

@Riverpod(keepAlive: true)
AnalyticsService analyticsService(Ref ref) => AnalyticsService();
