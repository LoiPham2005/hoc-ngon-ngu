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
    final iap = globalContainer.read(iapServiceProvider);
    final ads = globalContainer.read(adManagerProvider);
    await _step('IAP', iap.initialize);
    // Mua premium → tắt quảng cáo (chỉ khi IAP thật, giả lập không ghi đè trạng thái đã lưu).
    if (!iap.isMock) {
      void syncPremium() => ads.setPremium(iap.premium.value);
      iap.premium.addListener(syncPremium);
      syncPremium();
    }
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
