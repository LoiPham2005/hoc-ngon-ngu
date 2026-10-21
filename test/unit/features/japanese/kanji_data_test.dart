import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingua/features/japanese/models/kanji_model.dart';
import 'package:lingua/features/japanese/providers/kanji_provider.dart';
import 'package:lingua/features/japanese/providers/kanji_quiz_notifier.dart';

List<Kanji> _load() => [
  for (final e
      in jsonDecode(File('assets/japanese/kanji.json').readAsStringSync())
          as List)
    Kanji.fromJson(e as Map<String, dynamic>),
];

void main() {
  final kanji = _load();

  test('979 Kanji N5–N2, không trùng, đủ Hán Việt + nghĩa + nét viết', () {
    final strokes =
        jsonDecode(File('assets/japanese/strokes.json').readAsStringSync())
            as Map<String, dynamic>;
    expect(kanji, hasLength(979));
    expect(kanji.map((k) => k.char).toSet(), hasLength(979));
    expect(
      {
        for (final l in JlptLevel.values)
          l: kanji.where((k) => k.level == l).length,
      },
      {
        JlptLevel.n5: 79,
        JlptLevel.n4: 166,
        JlptLevel.n3: 367,
        JlptLevel.n2: 367,
      },
    );
    for (final k in kanji) {
      expect(k.hanViet, isNotEmpty, reason: k.char);
      expect(k.meaning, isNotEmpty, reason: k.char);
      expect(strokes[k.char], isNotEmpty, reason: k.char);
    }
  });

  test('dữ liệu mẫu đúng', () {
    final day = kanji.firstWhere((k) => k.char == '日');
    expect(day.hanViet, 'Nhật');
    expect(day.level, JlptLevel.n5);
    expect(day.onyomi, contains('ニチ')); // âm On viết katakana
    final study = kanji.firstWhere((k) => k.char == '学');
    expect(study.kunyomi, contains('まな(ぶ)')); // phần đuôi trong ngoặc
  });

  test('quiz: 4 đáp án đúng cấp, nhãn không trùng, có đáp án đúng', () async {
    final container = ProviderContainer(
      overrides: [kanjiListProvider.overrideWith((ref) async => kanji)],
    );
    addTearDown(container.dispose);
    await container.read(kanjiListProvider.future);

    for (final mode in KanjiQuizMode.values) {
      final provider = kanjiQuizProvider(JlptLevel.n3, mode);
      container.listen(provider, (_, _) {});
      for (var i = 0; i < 200; i++) {
        final quiz = container.read(provider);
        expect(quiz.options, hasLength(4));
        expect(quiz.options, contains(quiz.question));
        expect(quiz.options.every((k) => k.level == JlptLevel.n3), isTrue);
        expect(quiz.options.map(mode.answerOf).toSet(), hasLength(4));
        container.read(provider.notifier).next();
      }
    }
  });
}
