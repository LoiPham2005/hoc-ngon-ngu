import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lingua/config/flavor_config.dart';
import 'package:lingua/config/system_ui_manager.dart';
import 'package:lingua/core/di/global_providers.dart';
import 'package:lingua/core/services/fcm_service.dart';
import 'package:lingua/core/services/notification_service.dart';
import 'package:lingua/core/services/remote_config_service.dart';
import 'package:lingua/core/utils/logger.dart';
import 'package:lingua/features/profile/providers/reminder_notifier.dart';
import 'package:lingua/modules/ads/ad_manager.dart';
import 'package:lingua/modules/attribution/attribution_service.dart';
import 'package:lingua/modules/iap/iap_service.dart';

/// Khởi tạo lúc boot. Mỗi bước tự bắt lỗi — 1 bước hỏng không chặn app.
abstract class AppInitializer {
  static Future<void> initialize() async {
    await initializeDateFormatting('vi_VN');

    await _step('Firebase', () async {
      await Firebase.initializeApp();
      if (FlavorConfig.current.enableCrashlytics) {
        await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
          !kDebugMode,
        );
      }
    });
    await _step(
      'Local notification',
      () => globalContainer.read(notificationServiceProvider).initialize(),
    );
    // Nhắc học: đặt lại lịch mỗi lần mở app (múi giờ / ngôn ngữ có thể đã đổi).
    await _step(
      'Reminder',
      () => globalContainer.read(reminderProvider.notifier).sync(),
    );
    await _step('FCM', () => globalContainer.read(fcmServiceProvider).init());
    await SystemUIManager.setup();
    await _step(
      'Remote Config',
      () => globalContainer.read(remoteConfigServiceProvider).initialize(),
    );
    // Nguồn cài đặt (Adjust, tắt khi chưa có app token) — trước Ads để chọn đúng `ad_config`.
    await _step(
      'Attribution',
      () => globalContainer.read(attributionServiceProvider).initialize(),
    );
    final iap = globalContainer.read(iapServiceProvider);
    final ads = globalContainer.read(adManagerProvider);
    await _step('IAP', iap.initialize);
    // Premium (đã mua / `premium_for_all` từ xa) → tắt quảng cáo. IAP giả lập (chưa có key):
    // lần đầu không ghi đè trạng thái tự đặt bằng `ads.setPremium`, chỉ đồng bộ khi đổi.
    globalContainer.listen<bool>(isPremiumProvider, (previous, premium) {
      if (!iap.isMock || previous != null || premium) ads.setPremium(premium);
    }, fireImmediately: true);
    await _step('Ads', ads.initialize);

    talker.info('✅ App ready (${FlavorConfig.current.flavor.name})');
  }

  static Future<void> _step(String name, Future<void> Function() fn) async {
    try {
      await fn();
    } catch (e, s) {
      talker.error('$name init failed', e, s);
    }
  }
}
