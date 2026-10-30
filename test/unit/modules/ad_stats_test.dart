import 'package:flutter_test/flutter_test.dart';
import 'package:lingua/modules/ads/ad_stats.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    'counts per placement like the AdMob report and survives restart',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      const key = 'interstitial.lesson_done';
      AdStats(prefs)
        ..request(key, matched: true)
        ..request(key, matched: true)
        ..request(key, matched: false)
        ..impression(key)
        ..click(key)
        ..paid(key, 12000, 'USD')
        ..skip(key, 'interval')
        ..skip(key, 'interval')
        ..skip(key, 'not_ready');

      final row = AdStats(prefs).rows.value[key]!;
      expect(row.requests, 3);
      expect(row.matched, 2);
      expect(row.matchRate, closeTo(2 / 3, 1e-9));
      expect(row.showRate, 0.5);
      expect(row.ctr, 1);
      expect(row.ecpm, closeTo(12, 1e-9));
      expect(row.skipped, {'interval': 2, 'not_ready': 1});
      expect(row.skippedTotal, 3);
    },
  );
}
