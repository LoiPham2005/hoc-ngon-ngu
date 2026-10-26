import 'package:flutter_test/flutter_test.dart';
import 'package:lingua/core/services/app_version_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('isNewer compares each number, not as text', () {
    expect(isNewer('1.10.0', '1.9.3'), isTrue);
    expect(isNewer('2.0', '1.9.9'), isTrue);
    expect(isNewer('1.2.0', '1.2'), isFalse);
    expect(isNewer('1.2.0', '1.2.0+5'), isFalse);
    expect(isNewer('1.0.0', '1.0.1'), isFalse);
  });

  test('App Store lookup: version + link, nothing when app not on store', () {
    expect(
      parseAppStoreLookup({
        'resultCount': 1,
        'results': [
          {
            'version': '1.3.0',
            'trackViewUrl': 'https://apps.apple.com/app/id1',
          },
        ],
      }),
      (version: '1.3.0', url: 'https://apps.apple.com/app/id1'),
    );
    expect(parseAppStoreLookup({'resultCount': 0, 'results': <Object>[]}), isNull);
    expect(parseAppStoreLookup(null), isNull);
  });

  test(
    '"Later" hides the same version for 3 days, a newer one asks again',
    () async {
      SharedPreferences.setMockInitialValues({});
      final service = AppVersionService(await SharedPreferences.getInstance());
      final day0 = DateTime(2026, 10, 1);
      await service.snooze('1.3.0', now: day0);
      expect(
        service.isSnoozed('1.3.0', now: day0.add(const Duration(days: 2))),
        isTrue,
      );
      expect(
        service.isSnoozed('1.3.0', now: day0.add(const Duration(days: 4))),
        isFalse,
      );
      expect(service.isSnoozed('1.4.0', now: day0), isFalse);
    },
  );
}
