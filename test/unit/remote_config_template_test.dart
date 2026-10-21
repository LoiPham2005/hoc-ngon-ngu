import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingua/modules/ads/ad_config.dart';
import 'package:lingua/modules/app_config/app_config.dart';

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

  test('app_config parse được', () {
    final raw = (params['app_config'] as Map<String, dynamic>)['defaultValue'];
    final cfg = AppConfig.fromJson(value(raw as Map<String, dynamic>));
    expect(cfg.isMaintenance, isFalse);
  });
}
