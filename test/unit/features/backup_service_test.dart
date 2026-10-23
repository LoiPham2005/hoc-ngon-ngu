import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingua/core/di/global_providers.dart';
import 'package:lingua/features/course/models/course_model.dart';
import 'package:lingua/features/course/providers/learner_notifier.dart';
import 'package:lingua/features/profile/providers/backup_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> container(Map<String, Object> prefs) async {
    SharedPreferences.setMockInitialValues(prefs);
    final c = ProviderContainer(
      overrides: [
        sharedPrefsProvider.overrideWithValue(
          await SharedPreferences.getInstance(),
        ),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  test('backup then restore on another phone keeps progress', () async {
    final phone1 = await container({});
    final n = phone1.read(learnerProvider.notifier);
    await n.chooseCourse(Course.ja);
    await n.toggleLearned('あ');
    await n.recordAnswer(correct: true, key: '日');
    final file = phone1.read(backupProvider).encode();
    expect(jsonDecode(file)['app'], 'lingua');

    final phone2 = await container({});
    expect(phone2.read(learnerProvider).course, isNull);
    expect(await phone2.read(backupProvider).decode(file), isTrue);
    final restored = phone2.read(learnerProvider);
    expect(restored.course, Course.ja);
    expect(restored.learned, {'あ'});
    expect(restored.answered, 1);
    expect(restored.reviews.keys, [
      'あ',
    ]); // trả lời đúng không tự thêm vào lịch ôn
  });

  test(
    'rejects files that are not a Lingua backup, keeps current data',
    () async {
      final c = await container({
        'learner_v1': '{"course":"en","learned":["en:w:rice"]}',
      });
      final backup = c.read(backupProvider);
      for (final bad in [
        'hello',
        '{"app":"other","data":{}}',
        '{"app":"lingua","data":{"learner_v1":"not json"}}',
      ]) {
        expect(await backup.decode(bad), isFalse, reason: bad);
      }
      expect(c.read(learnerProvider).learned, {'en:w:rice'});
    },
  );

  test('file picker unavailable → failed result, no exception', () async {
    final c = await container({});
    // Môi trường test không có plugin native (giống app chưa build lại sau khi thêm plugin).
    expect(await c.read(backupProvider).export(), ExportResult.failed);
    expect(await c.read(backupProvider).restore(), RestoreResult.failed);
  });
}
