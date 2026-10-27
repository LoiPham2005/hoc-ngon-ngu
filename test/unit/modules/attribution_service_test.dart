import 'package:flutter_test/flutter_test.dart';
import 'package:lingua/modules/attribution/attribution_config.dart';
import 'package:lingua/modules/attribution/attribution_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late AttributionConfig config;
  late List<String> started;
  late List<String> sentEvents;

  Future<AttributionService> service([
    Map<String, Object> prefs = const {},
  ]) async {
    SharedPreferences.setMockInitialValues(prefs);
    return AttributionService(
      await SharedPreferences.getInstance(),
      config: () => config,
      start: started.add,
      sendEvent: sentEvents.add,
    );
  }

  setUp(() {
    config = const AttributionConfig();
    started = [];
    sentEvents = [];
  });

  group('app token', () {
    test('no token anywhere → Adjust stays off', () async {
      final s = await service();
      await s.initialize();
      expect(s.enabled, isFalse);
      expect(started, isEmpty);
    });

    test('token from Remote Config starts Adjust', () async {
      config = const AttributionConfig(appToken: 'remote123');
      final s = await service();
      await s.initialize();
      expect(started, ['remote123']);
    });

    test('token arriving later (first launch) starts Adjust once', () async {
      final s = await service();
      await s.initialize(); // Remote Config chưa tải
      config = const AttributionConfig(appToken: 'late456');
      s
        ..onConfigChanged()
        ..onConfigChanged();
      expect(started, ['late456']);
    });
  });

  group('paid or organic', () {
    test('campaign networks are paid, organic ones are not', () async {
      final s = await service();
      s.recordNetwork('Facebook Installs');
      expect(s.isPaid.value, isTrue);
      s.recordNetwork('Organic');
      expect(s.isPaid.value, isFalse);
      s.recordNetwork('Google Organic Search');
      expect(s.isPaid.value, isFalse);
    });

    test(
      'unknown source follows paid_when_unknown (default organic)',
      () async {
        final s = await service();
        s.recordNetwork('Unattributed');
        expect(s.isPaid.value, isFalse);

        config = const AttributionConfig(paidWhenUnknown: true);
        s.onConfigChanged();
        expect(s.isPaid.value, isTrue);
      },
    );

    test('a fresh install is organic; a saved source is kept', () async {
      expect((await service()).isPaid.value, isFalse);
      final saved = await service({
        'attribution_network_v1': 'TikTok for Business',
      });
      expect(saved.isPaid.value, isTrue);
    });
  });

  group('value events', () {
    test('sent once when revenue or impressions cross the threshold', () async {
      config = const AttributionConfig(
        appToken: 'x',
        valueEvents: [
          ValueEvent(token: 'rev', adRevenue: 0.03),
          ValueEvent(token: 'imp', adImpressions: 3),
        ],
      );
      final s = await service();
      await s.initialize();
      void show() => s.trackAdRevenue(
        valueMicros: 12000, // 0.012 USD
        currency: 'USD',
        placement: 'interstitial.after_quiz',
      );

      show();
      show();
      expect(sentEvents, isEmpty);
      show(); // 0.036 USD, 3 lượt
      expect(sentEvents, ['rev', 'imp']);
      show();
      expect(sentEvents, ['rev', 'imp']); // không gửi lại
    });

    test(
      'revenue in another currency does not count toward a USD threshold',
      () async {
        config = const AttributionConfig(
          appToken: 'x',
          valueEvents: [ValueEvent(token: 'rev', adRevenue: 0.01)],
        );
        final s = await service();
        await s.initialize();
        s.trackAdRevenue(
          valueMicros: 500000000,
          currency: 'VND',
          placement: 'p',
        );
        expect(sentEvents, isEmpty);
      },
    );
  });
}
