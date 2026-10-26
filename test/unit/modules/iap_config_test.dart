import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingua/modules/iap/iap_config.dart';
import 'package:lingua/modules/iap/iap_service.dart';

void main() {
  test('missing fields keep selling and grant nothing extra', () {
    final cfg = IapConfig.fromJson(const {});
    expect(cfg.purchaseEnabled, isTrue);
    expect(cfg.premiumForAll, isFalse);
  });

  group('isPremium', () {
    ProviderContainer container(IapConfig config, IapService iap) {
      final c = ProviderContainer(
        overrides: [
          iapConfigProvider.overrideWithValue(config),
          iapServiceProvider.overrideWithValue(iap),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    test('follows the purchase state', () {
      final iap = IapService();
      final c = container(const IapConfig(), iap);
      expect(c.read(isPremiumProvider), isFalse);
      iap.debugSetPremium(true);
      expect(c.read(isPremiumProvider), isTrue);
    });

    test('premium_for_all unlocks everyone', () {
      final c = container(const IapConfig(premiumForAll: true), IapService());
      expect(c.read(isPremiumProvider), isTrue);
    });

    test('stopping sales never takes premium away', () {
      final iap = IapService()..debugSetPremium(true);
      final c = container(const IapConfig(purchaseEnabled: false), iap);
      expect(c.read(isPremiumProvider), isTrue);
    });
  });
}
