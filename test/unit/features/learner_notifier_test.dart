import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingua/core/di/global_providers.dart';
import 'package:lingua/features/course/models/course_model.dart';
import 'package:lingua/features/course/providers/learner_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;

  ProviderContainer newContainer() {
    final c = ProviderContainer(
      overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
    );
    addTearDown(c.dispose);
    return c;
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  test(
    'chưa chọn khoá học = chưa onboarding; chọn xong lưu lại sau khi mở lại app',
    () async {
      final c = newContainer();
      expect(c.read(learnerProvider).course, isNull);
      await c.read(learnerProvider.notifier).chooseCourse(Course.ja);
      expect(newContainer().read(learnerProvider).course, Course.ja);
    },
  );

  test('đánh dấu thuộc / bỏ thuộc; chỉ khi thêm mới tính 1 lượt', () async {
    final c = newContainer();
    final n = c.read(learnerProvider.notifier);
    await n.toggleLearned('あ');
    expect(c.read(learnerProvider).learned, {'あ'});
    expect(n.todayCount, 1);
    await n.toggleLearned('あ');
    expect(c.read(learnerProvider).learned, isEmpty);
    expect(n.todayCount, 1);
  });

  test(
    'chuỗi ngày: liên tiếp +1, bỏ 1 ngày → về 1, sang ngày mới lượt hôm nay = 0',
    () async {
      final c = newContainer();
      final n = c.read(learnerProvider.notifier);
      var day = DateTime(2026, 10, 1, 9);
      n.now = () => day;

      await n.recordAnswer(correct: true);
      await n.recordAnswer(correct: false);
      expect(n.currentStreak, 1);
      expect(n.todayCount, 2);

      day = DateTime(2026, 10, 2, 20);
      expect(n.todayCount, 0); // chưa học hôm nay
      expect(n.currentStreak, 1); // hôm qua có học → chuỗi vẫn giữ
      await n.recordAnswer(correct: true);
      expect(n.currentStreak, 2);

      day = DateTime(2026, 10, 5, 8); // bỏ 2 ngày
      expect(n.currentStreak, 0);
      await n.recordAnswer(correct: true);
      expect(n.currentStreak, 1);

      final l = c.read(learnerProvider);
      expect(l.answered, 4);
      expect(l.correct, 3);
      expect(l.accuracy, 0.75);
    },
  );

  test('đặt lại tiến độ giữ khoá học + mục tiêu', () async {
    final c = newContainer();
    final n = c.read(learnerProvider.notifier);
    await n.chooseCourse(Course.ja);
    await n.setDailyGoal(20);
    await n.toggleLearned('日');
    await n.recordAnswer(correct: true);
    await n.resetProgress();
    final l = c.read(learnerProvider);
    expect(l.course, Course.ja);
    expect(l.dailyGoal, 20);
    expect(l.learned, isEmpty);
    expect(l.answered, 0);
  });

  group('spaced repetition', () {
    test('learning an item schedules its first review for tomorrow', () async {
      final c = newContainer();
      final n = c.read(learnerProvider.notifier);
      var day = DateTime(2026, 10, 1, 9);
      n.now = () => day;

      await n.toggleLearned('en:w:rice');
      await n.toggleLearned('en:ph:æ'); // IPA sounds are not reviewed
      expect(c.read(learnerProvider).reviews.keys, ['en:w:rice']);
      expect(n.dueKeys(Course.en), isEmpty);

      day = DateTime(2026, 10, 2, 9);
      expect(n.dueKeys(Course.en), ['en:w:rice']);
      expect(n.dueKeys(Course.ja), isEmpty);

      await n.toggleLearned('en:w:rice'); // unlearn → no more reviews
      expect(c.read(learnerProvider).reviews, isEmpty);
    });

    test(
      'correct answer when due moves the card up and spaces it out',
      () async {
        final c = newContainer();
        final n = c.read(learnerProvider.notifier);
        var day = DateTime(2026, 10, 1);
        n.now = () => day;
        await n.toggleLearned('日');

        // Correct before it is due → schedule unchanged.
        await n.recordAnswer(correct: true, key: '日');
        expect(c.read(learnerProvider).reviews['日']!.due, '2026-10-02');

        day = DateTime(2026, 10, 2);
        await n.recordAnswer(correct: true, key: '日');
        var card = c.read(learnerProvider).reviews['日']!;
        expect((card.box, card.due), (1, '2026-10-05'));

        day = DateTime(2026, 10, 5);
        await n.recordAnswer(correct: true, key: '日');
        card = c.read(learnerProvider).reviews['日']!;
        expect((card.box, card.due), (2, '2026-10-12'));

        // Wrong → back to the start, due tomorrow.
        await n.recordAnswer(correct: false, key: '日');
        card = c.read(learnerProvider).reviews['日']!;
        expect((card.box, card.due), (0, '2026-10-06'));
      },
    );

    test('a wrong answer adds a not-yet-learned item to the reviews', () async {
      final c = newContainer();
      final n = c.read(learnerProvider.notifier);
      n.now = () => DateTime(2026, 10, 1);
      await n.recordAnswer(correct: false, key: 'en:p:hotel.3');
      expect(
        c.read(learnerProvider).reviews['en:p:hotel.3']!.due,
        '2026-10-02',
      );
      expect(c.read(learnerProvider).learned, isEmpty);
    });

    test('old saved data: learned items become due right away', () async {
      SharedPreferences.setMockInitialValues({
        'learner_v1': '{"course":"ja","learned":["あ","en:g:to-be"]}',
      });
      prefs = await SharedPreferences.getInstance();
      final c = newContainer();
      expect(c.read(learnerProvider.notifier).dueKeys(Course.ja), ['あ']);
      expect(c.read(learnerProvider).reviews.keys, ['あ']);
    });
  });
}
