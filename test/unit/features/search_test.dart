import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingua/core/di/global_providers.dart';
import 'package:lingua/core/utils/text_fold.dart';
import 'package:lingua/features/course/models/course_model.dart';
import 'package:lingua/features/search/providers/search_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('foldText: lowercase, no Vietnamese accents, katakana = hiragana', () {
    expect(foldText('Ăn cơm ĐI'), 'an com di');
    expect(foldText('Người Việt'), 'nguoi viet');
    expect(foldText('タベル'), 'たべる');
  });

  for (final (course, query, expected) in [
    (Course.en, 'com', 'rice'), // "cơm, gạo" — không dấu vẫn ra
    (Course.en, 'rice', 'rice'),
    (Course.ja, 'たべる', '食べる'), // gõ cách đọc
    (Course.ja, 'nhat', '日'), // Hán Việt "Nhật"
    (Course.ja, 'ka', 'か'), // romaji của Kana
    (Course.en, 'rcie', 'rice'), // gõ đảo chữ
    (Course.en, 'gaoo', 'rice'), // gõ thừa chữ, không dấu
    (Course.ja, 'たべり', '食べる'), // sai 1 chữ kana
  ]) {
    test('${course.name}: "$query" finds $expected near the top', () async {
      SharedPreferences.setMockInitialValues({'app_locale': 'vi'});
      final c = ProviderContainer(
        overrides: [
          sharedPrefsProvider.overrideWithValue(
            await SharedPreferences.getInstance(),
          ),
        ],
      );
      addTearDown(c.dispose);
      final index = await c.read(searchIndexProvider(course).future);
      final titles = index.find(query).map((e) => e.title).toList();
      expect(titles.take(15), contains(expected), reason: '$titles');
    });
  }

  test('empty query → no results', () {
    expect(SearchIndex(const []).find('  '), isEmpty);
  });
}
