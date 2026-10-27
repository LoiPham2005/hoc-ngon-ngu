import 'package:flutter_test/flutter_test.dart';
import 'package:lingua/modules/ads/ad_config.dart';

void main() {
  test('fromJson snake_case, field thiếu dùng mặc định', () {
    final cfg = AdConfig.fromJson({
      'show_all_ads': true,
      'enable_app_open': false,
      'rules': {'interstitial_interval': 10, 'max_interstitial_per_session': 2},
      'enable_rewarded_interstitial': false,
      'ad_units': {
        'rewarded_interstitial': {
          'level_end': {'id': 'c'},
        },
        'interstitial': {
          'splash': {'id': 'a', 'native_full_after': false},
        },
        'app_open': {
          'resume': {'id': 'b'},
        },
      },
    });
    expect(cfg.rules.interstitialInterval, 10);
    expect(cfg.rules.maxInterstitialPerSession, 2);
    expect(cfg.rules.appOpenInterval, 30); // mặc định
    expect(cfg.adUnits.interstitial['splash']?.nativeFullAfter, false);
    expect(cfg.adUnits.appOpen['resume']?.id, 'b');
    expect(cfg.enableAppOpen, false);
    expect(cfg.adUnits.rewardedInterstitial['level_end']?.id, 'c');
    expect(
      cfg.unit(AdType.rewardedInterstitial, 'level_end'),
      isNull,
    ); // loại bị tắt
  });

  group('unit() — chỉ trả unit được phép hiện', () {
    const cfg = AdConfig(
      enableBanner: false,
      adUnits: AdUnits(
        interstitial: {
          'on': AdUnit(id: 'x'),
          'off': AdUnit(id: 'x', enable: false),
          'no_id': AdUnit(),
        },
        banner: {'home': AdUnit(id: 'y')},
      ),
    );

    test('unit bật + có id → trả về', () {
      expect(cfg.unit(AdType.interstitial, 'on')?.id, 'x');
    });

    test('unit tắt / thiếu id / không có placement → null', () {
      expect(cfg.unit(AdType.interstitial, 'off'), isNull);
      expect(cfg.unit(AdType.interstitial, 'no_id'), isNull);
      expect(cfg.unit(AdType.interstitial, 'missing'), isNull);
    });

    test('tắt loại → null', () {
      expect(cfg.unit(AdType.banner, 'home'), isNull);
    });

    test('tắt tổng (disabled / showAllAds=false) → null', () {
      expect(
        cfg.copyWith(showAllAds: false).unit(AdType.interstitial, 'on'),
        isNull,
      );
      expect(AdConfig.disabled.unit(AdType.interstitial, 'on'), isNull);
    });
  });

  test('rules: 0 = không giới hạn, lấy đúng theo loại', () {
    const rules = AdRules(maxRewardedPerSession: 0, appOpenInterval: 15);
    expect(rules.maxPerSessionOf(AdType.rewarded), 0);
    expect(rules.intervalOf(AdType.appOpen), 15);
  });

  test('fallback ids are tried after the main id, blanks skipped', () {
    final unit = AdUnit.fromJson(const {
      'id': 'high-floor',
      'fallback_ids': ['normal', ''],
    });
    expect(unit.ids, ['high-floor', 'normal']);
    expect(const AdUnit(id: 'only').ids, ['only']);
  });

  test(
    'mergeAdConfigJson: nested objects merge, other values are replaced',
    () {
      final merged = mergeAdConfigJson(
        {
          'preload': true,
          'rules': {'interstitial_interval': 30, 'app_open_interval': 15},
          'ad_units': {
            'interstitial': {
              'splash': {'id': 'A', 'native_full_after': true},
            },
          },
        },
        {
          'preload': false,
          'rules': {'interstitial_interval': 45},
          'ad_units': {
            'interstitial': {
              'splash': {'native_full_after': false},
            },
          },
        },
      );
      expect(merged['preload'], isFalse);
      expect(merged['rules'], {
        'interstitial_interval': 45,
        'app_open_interval': 15,
      });
      expect((merged['ad_units'] as Map)['interstitial'], {
        'splash': {'id': 'A', 'native_full_after': false},
      });
    },
  );

  group('unknownAdConfigKeys', () {
    test('valid keys pass, typos are reported at every level', () {
      expect(
        unknownAdConfigKeys({
          'show_all_ads': true,
          'rules': {'interstitial_interval': 30},
          'ad_units': {
            'interstitial': {
              'after_quiz': {'id': 'x', 'native_full_after': true},
            },
          },
        }),
        isEmpty,
      );
      expect(
        unknownAdConfigKeys({
          'show_all_adz': true,
          'rules': {'interstitial_intervall': 30},
          'ad_units': {
            'interstital': <String, dynamic>{},
            'interstitial': {
              'after_quiz': {'native_full_afer': true},
            },
          },
        }),
        [
          'show_all_adz',
          'rules.interstitial_intervall',
          'ad_units.interstital',
          'ad_units.interstitial.after_quiz.native_full_afer',
        ],
      );
    });

    test('override: a placement missing from ad_config is reported', () {
      const base = {
        'ad_units': {
          'interstitial': {
            'after_quiz': {'id': 'x'},
          },
        },
      };
      expect(
        unknownAdConfigKeys({
          'ad_units': {
            'interstitial': {
              'after_quizz': {'native_full_after': true},
            },
          },
        }, base: base),
        ['ad_units.interstitial.after_quizz (không có trong ad_config)'],
      );
    });
  });

  test('rewarded interstitial has its own limits, separate from rewarded', () {
    const rules = AdRules(
      rewardedInterval: 10,
      maxRewardedPerSession: 0,
      rewardedInterstitialInterval: 90,
      maxRewardedInterstitialPerSession: 2,
    );
    expect(rules.intervalOf(AdType.rewarded), 10);
    expect(rules.maxPerSessionOf(AdType.rewarded), 0);
    expect(rules.intervalOf(AdType.rewardedInterstitial), 90);
    expect(rules.maxPerSessionOf(AdType.rewardedInterstitial), 2);
  });

  test('cấu hình dev chỉ dùng Google test ID', () {
    expect(
      kDevAdConfig.adUnits.all.every(
        (u) => u.id.startsWith(kGoogleTestPublisher),
      ),
      isTrue,
    );
  });
}
