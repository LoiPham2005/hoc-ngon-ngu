import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingua/core/di/global_providers.dart';
import 'package:lingua/features/course/models/course_model.dart';
import 'package:lingua/features/course/providers/learner_notifier.dart';
import 'package:lingua/modules/analytics/analytics_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeAnalytics extends AnalyticsService {
  /// `[tên, params]` — so sánh sâu được bằng `expect`.
  final events = <List<Object?>>[];

  @override
  Future<void> logEvent(String name, [Map<String, Object?>? params]) async =>
      events.add([name, params]);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<(LearnerNotifier, _FakeAnalytics)> learner() async {
    SharedPreferences.setMockInitialValues({});
    final analytics = _FakeAnalytics();
    final c = ProviderContainer(
      overrides: [
        sharedPrefsProvider.overrideWithValue(
          await SharedPreferences.getInstance(),
        ),
        analyticsServiceProvider.overrideWithValue(analytics),
      ],
    );
    addTearDown(c.dispose);
    return (c.read(learnerProvider.notifier), analytics);
  }

  test('choosing a course logs it, first time flagged', () async {
    final (n, analytics) = await learner();
    await n.chooseCourse(Course.en);
    await n.chooseCourse(Course.en); // không đổi → không ghi
    await n.chooseCourse(Course.ja);
    expect(analytics.events, [
      [
        'course_selected',
        {'course': 'en', 'first': 1},
      ],
      [
        'course_selected',
        {'course': 'ja', 'first': 0},
      ],
    ]);
  });

  test('daily goal is logged once, when it is first reached', () async {
    final (n, analytics) = await learner();
    await n.setDailyGoal(3);
    for (var i = 0; i < 5; i++) {
      await n.recordAnswer(correct: true);
    }
    expect(
      analytics.events.where((e) => e.first == 'daily_goal_reached').toList(),
      [
        [
          'daily_goal_reached',
          {'goal': 3, 'streak': 1},
        ],
      ],
    );
  });
}
