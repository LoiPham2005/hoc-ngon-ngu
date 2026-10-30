import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingua/modules/ads/ad_config.dart';
import 'package:lingua/modules/app_config/app_config.dart';
import 'package:lingua/modules/attribution/attribution_config.dart';
import 'package:lingua/modules/iap/iap_config.dart';

/// `firebase/remote_config.test.json` phải parse được bằng model của app.
void main() {
  final params =
      (jsonDecode(File('firebase/remote_config.test.json').readAsStringSync())
              as Map<String, dynamic>)['parameters']
          as Map<String, dynamic>;

  Map<String, dynamic> value(Map<String, dynamic> v) =>
      jsonDecode(v['value'] as String) as Map<String, dynamic>;

  for (final key in const ['ad_config']) {
    test('$key (Android + iOS) parse đủ placement, toàn test ID', () {
      final ad = params[key] as Map<String, dynamic>;
      for (final raw in [
        ad['defaultValue'] as Map<String, dynamic>,
        (ad['conditionalValues'] as Map<String, dynamic>)['iOS']
            as Map<String, dynamic>,
      ]) {
        final cfg = AdConfig.fromJson(value(raw));
        // Đúng các vị trí của docs/ad-plan.md.
        expect(
          cfg.unit(AdType.interstitial, InterstitialPlacement.lessonDone),
          isNotNull,
        );
        expect(cfg.unit(AdType.appOpen, AppOpenPlacement.splash), isNotNull);
        expect(cfg.unit(AdType.appOpen, AppOpenPlacement.resume), isNotNull);
        expect(cfg.unit(AdType.native, NativePlacement.result), isNotNull);
        expect(cfg.unit(AdType.banner, BannerPlacement.list), isNotNull);
        for (final p in [
          InterstitialPlacement.openContent,
          InterstitialPlacement.openDetail,
          InterstitialPlacement.practiceStart,
          InterstitialPlacement.tabSwitch,
        ]) {
          expect(cfg.unit(AdType.interstitial, p), isNotNull, reason: p);
        }
        expect(
          cfg.unit(AdType.rewarded, RewardedPlacement.streakFreeze),
          isNotNull,
        );
        for (final p in [
          NativePlacement.list,
          NativePlacement.home,
          NativePlacement.onboarding,
          NativePlacement.detail,
        ]) {
          expect(cfg.unit(AdType.native, p), isNotNull, reason: p);
        }
        // Người dùng tự nhiên: không native toàn màn sau interstitial.
        expect(
          cfg.unit(AdType.native, NativePlacement.afterInterstitial),
          isNull,
        );
        expect(cfg.rules.interstitialInterval, greaterThanOrEqualTo(45));
        expect(
          cfg.adUnits.all.every((u) => u.id.startsWith(kGoogleTestPublisher)),
          isTrue,
        );
      }
    });

    test('$key: rules and every unit spell out all their fields', () {
      final ad = params[key] as Map<String, dynamic>;
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
  }

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

  // Thường chỉ ghi phần khác (giãn cách…). Ghi "id" riêng cũng được (tách doanh thu / giá sàn
  // cho người dùng mua về) — khi đó phải có giá trị iOS riêng như ad_config.
  group('ad_config_paid (only the differences, merged onto ad_config)', () {
    final paid = value(
      (params['ad_config_paid'] as Map<String, dynamic>)['defaultValue']
          as Map<String, dynamic>,
    );
    final ad = params['ad_config'] as Map<String, dynamic>;

    test('templates have no misspelled keys', () {
      for (final raw in [
        ad['defaultValue'] as Map<String, dynamic>,
        ...(ad['conditionalValues'] as Map<String, dynamic>).values
            .cast<Map<String, dynamic>>(),
      ]) {
        expect(unknownAdConfigKeys(value(raw)), isEmpty);
        expect(unknownAdConfigKeys(paid, base: value(raw)), isEmpty);
      }
    });

    test('merged result works on Android and iOS', () {
      for (final raw in [
        ad['defaultValue'] as Map<String, dynamic>,
        ...(ad['conditionalValues'] as Map<String, dynamic>).values
            .cast<Map<String, dynamic>>(),
      ]) {
        final cfg = AdConfig.fromJson(mergeAdConfigJson(value(raw), paid));
        expect(cfg.rules.interstitialInterval, 30);
        expect(
          cfg.unit(AdType.interstitial, InterstitialPlacement.lessonDone)?.id,
          startsWith(kGoogleTestPublisher),
        );
        // Người dùng mua về: native toàn màn sau interstitial được bật.
        expect(
          cfg
              .unit(AdType.interstitial, InterstitialPlacement.lessonDone)
              ?.nativeFullAfter,
          isTrue,
        );
        expect(
          cfg.unit(AdType.native, NativePlacement.afterInterstitial),
          isNotNull,
        );
      }
    });
  });

  test('attribution_config parses; defaults change nothing', () {
    final raw =
        (params['attribution_config'] as Map<String, dynamic>)['defaultValue'];
    final cfg = AttributionConfig.fromJson(value(raw as Map<String, dynamic>));
    expect(cfg.appToken, isEmpty);
    expect(cfg.paidWhenUnknown, isFalse);
    expect(cfg.valueEvents, isEmpty);
  });
}
