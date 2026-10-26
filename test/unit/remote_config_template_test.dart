import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingua/modules/ads/ad_config.dart';
import 'package:lingua/modules/app_config/app_config.dart';
import 'package:lingua/modules/iap/iap_config.dart';

/// `firebase/remote_config.test.json` phải parse được bằng model của app.
void main() {
  final params =
      (jsonDecode(File('firebase/remote_config.test.json').readAsStringSync())
              as Map<String, dynamic>)['parameters']
          as Map<String, dynamic>;

  Map<String, dynamic> value(Map<String, dynamic> v) =>
      jsonDecode(v['value'] as String) as Map<String, dynamic>;

  test('ad_config (Android + iOS) parse đủ placement, toàn test ID', () {
    final ad = params['ad_config'] as Map<String, dynamic>;
    for (final raw in [
      ad['defaultValue'] as Map<String, dynamic>,
      (ad['conditionalValues'] as Map<String, dynamic>)['iOS']
          as Map<String, dynamic>,
    ]) {
      final cfg = AdConfig.fromJson(value(raw));
      expect(
        cfg.unit(AdType.interstitial, InterstitialPlacement.splash),
        isNotNull,
      );
      expect(
        cfg.unit(
          AdType.rewardedInterstitial,
          RewardedInterstitialPlacement.levelEnd,
        ),
        isNotNull,
      );
      expect(cfg.unit(AdType.banner, BannerPlacement.bottom), isNotNull);
      expect(
        cfg.adUnits.all.every((u) => u.id.startsWith(kGoogleTestPublisher)),
        isTrue,
      );
    }
  });

  test('ad_config: rules and every unit spell out all their fields', () {
    final ad = params['ad_config'] as Map<String, dynamic>;
    for (final raw in [
      ad['defaultValue'] as Map<String, dynamic>,
      ...(ad['conditionalValues'] as Map<String, dynamic>).values
          .cast<Map<String, dynamic>>(),
    ]) {
      expect(
        (value(raw)['rules'] as Map<String, dynamic>).keys,
        containsAll(const AdRules().toJson().keys),
        reason: 'rules',
      );
      final types = value(raw)['ad_units'] as Map<String, dynamic>;
      for (final MapEntry(key: type, value: units) in types.entries) {
        for (final unit in (units as Map<String, dynamic>).values) {
          final keys = (unit as Map<String, dynamic>).keys.toSet();
          expect(
            keys,
            containsAll(['id', 'fallback_ids', 'enable', 'preload']),
            reason: type,
          );
          if (type == 'interstitial') {
            expect(keys, contains('native_full_after'), reason: type);
          }
        }
      }
    }
  });

  test('app_config parse được', () {
    final raw = (params['app_config'] as Map<String, dynamic>)['defaultValue'];
    final cfg = AppConfig.fromJson(value(raw as Map<String, dynamic>));
    // Mẫu mặc định không được khoá app.
    expect(cfg.maintenance, isFalse);
    expect(cfg.mustUpdate('0.0.1'), isFalse);
    expect(cfg.hasNotice, isFalse);
  });

  test('iap_config parses; defaults keep selling and unlock nothing', () {
    final raw = (params['iap_config'] as Map<String, dynamic>)['defaultValue'];
    final cfg = IapConfig.fromJson(value(raw as Map<String, dynamic>));
    expect(cfg.purchaseEnabled, isTrue);
    expect(cfg.premiumForAll, isFalse);
  });
}
