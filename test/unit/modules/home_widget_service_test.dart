import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingua/core/di/global_providers.dart';
import 'package:lingua/design/l10n/locale_notifier.dart';
import 'package:lingua/features/course/models/course_model.dart';
import 'package:lingua/features/course/providers/learner_notifier.dart';
import 'package:lingua/gen/l10n/app_localizations.dart';
import 'package:lingua/modules/analytics/analytics_service.dart';
import 'package:lingua/modules/home_widget/home_widget_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _SilentAnalytics extends AnalyticsService {
  @override
  Future<void> logEvent(String name, [Map<String, Object?>? params]) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('maps raw learner data, labels and the 7-day history', () {
    final data = buildHomeWidgetData(
      learner: const Learner(
        course: Course.en,
        dailyGoal: 20,
        streak: 4,
        lastActiveDay: '2026-11-02',
        todayCount: 7,
        lastModule: Module.enPhrases,
        history: {
          '2026-10-27': DayStat(answered: 2, learned: 1),
          '2026-11-01': DayStat(answered: 5),
          '2026-11-02': DayStat(answered: 6, learned: 1),
          '2026-10-20': DayStat(answered: 99), // ngoài 7 ngày
        },
      ),
      now: DateTime(2026, 11, 2, 21, 30),
      dueCount: 3,
      l10n: lookupAppLocalizations(const Locale('en')),
    );

    expect(data, {
      'streak': 4,
      'lastActiveDay': '2026-11-02',
      'todayCount': 7,
      'dailyGoal': 20,
      'dueCount': 3,
      'courseFlag': '🇬🇧',
      'continueTitle': 'Everyday phrases',
      'last7': '3,0,0,0,0,5,7',
      'last7End': '2026-11-02',
      'labelStreak': 'day streak',
      'labelToday': 'Today',
      'labelDue': '3 items to review',
      'labelContinue': 'Continue',
      'labelWeekdays': 'M,T,W,T,F,S,S',
    });
  });

  test('fresh learner falls back to the first Japanese module', () {
    final data = buildHomeWidgetData(
      learner: const Learner(),
      now: DateTime(2026, 1, 1),
      dueCount: 0,
      l10n: lookupAppLocalizations(const Locale('vi')),
    );
    expect(data['lastActiveDay'], '');
    expect(data['courseFlag'], '🇯🇵');
    expect(data['continueTitle'], 'Hiragana');
    expect(data['last7'], '0,0,0,0,0,0,0');
    expect(data['labelDue'], 'Không có mục cần ôn');
    expect(data['labelStreak'], 'ngày liên tiếp');
  });

  test('push writes the current learner state in the app language', () async {
    SharedPreferences.setMockInitialValues({'app_locale': 'ja'});
    final written = <Map<String, Object>>[];
    final c = ProviderContainer(
      overrides: [
        sharedPrefsProvider.overrideWithValue(
          await SharedPreferences.getInstance(),
        ),
        analyticsServiceProvider.overrideWithValue(_SilentAnalytics()),
        homeWidgetServiceProvider.overrideWith(
          (ref) => HomeWidgetService(ref, writer: (d) async => written.add(d)),
        ),
      ],
    );
    addTearDown(c.dispose);
    expect(c.read(localeProvider).languageCode, 'ja');
    final learner = c.read(learnerProvider.notifier)
      ..now = () => DateTime(2026, 11, 3, 9);
    await learner.chooseCourse(Course.ja);
    await learner.recordAnswer(correct: false, key: 'あ');

    await c.read(homeWidgetServiceProvider).push();

    final data = written.single;
    expect(data['streak'], 1);
    expect(data['lastActiveDay'], '2026-11-03');
    expect(data['todayCount'], 1);
    expect(data['last7'], '0,0,0,0,0,0,1');
    expect(data['labelWeekdays'], '月,火,水,木,金,土,日');
    // Câu sai → ôn lại từ mai, hôm nay chưa tới hạn.
    expect(data['dueCount'], 0);
  });
}
