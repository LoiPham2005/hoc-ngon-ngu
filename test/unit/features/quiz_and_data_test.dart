import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingua/core/di/global_providers.dart';
import 'package:lingua/features/course/models/course_model.dart';
import 'package:lingua/features/course/providers/learner_notifier.dart';
import 'package:lingua/features/japanese/models/kana_model.dart';
import 'package:lingua/features/japanese/models/kanji_model.dart';
import 'package:lingua/features/japanese/providers/kanji_provider.dart';
import 'package:lingua/features/practice/providers/quiz_session_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _kanji = [
  for (final e
      in jsonDecode(File('assets/japanese/kanji.json').readAsStringSync())
          as List)
    Kanji.fromJson(e as Map<String, dynamic>),
];

void main() {
  group('dữ liệu', () {
    test(
      'Kana: 71 chữ mỗi bảng (46 + 25 âm đục), Katakana = Hiragana + 0x60',
      () {
        for (final s in KanaScript.values) {
          expect(KanaTable.all(s, withDakuten: true), hasLength(71));
        }
        expect(const Kana('あ', 'a', KanaScript.hiragana).counterpart.char, 'ア');
      },
    );

    test('Kanji: 979 chữ N5–N2, đủ Hán Việt, nghĩa vi/en, nét viết', () {
      final strokes =
          jsonDecode(File('assets/japanese/strokes.json').readAsStringSync())
              as Map<String, dynamic>;
      expect(_kanji, hasLength(979));
      expect(
        {
          for (final l in JlptLevel.values)
            l: _kanji.where((k) => k.level == l).length,
        },
        {
          JlptLevel.n5: 79,
          JlptLevel.n4: 166,
          JlptLevel.n3: 367,
          JlptLevel.n2: 367,
        },
      );
      for (final k in _kanji) {
        expect(
          [k.hanViet, k.meaning, k.meaningEn],
          everyElement(isNotEmpty),
          reason: k.char,
        );
        expect(strokes[k.char], isNotEmpty, reason: k.char);
      }
      for (final s in KanaScript.values) {
        for (final k in KanaTable.all(s, withDakuten: true)) {
          expect(strokes[k.char], isNotEmpty, reason: k.char);
        }
      }
    });
  });

  group('bài luyện', () {
    late ProviderContainer c;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      c = ProviderContainer(
        overrides: [
          sharedPrefsProvider.overrideWithValue(prefs),
          kanjiListProvider.overrideWith((ref) async => _kanji),
        ],
      );
      addTearDown(c.dispose);
      await c.read(kanjiListProvider.future);
    });

    final topics = [
      for (final m in Module.values)
        if (m.isKanji)
          for (final mode in [QuizMode.hanViet, QuizMode.meaning])
            QuizTopic(m, mode)
        else
          for (final set in KanaSet.values)
            QuizTopic(m, QuizMode.reading, kanaSet: set),
      for (final set in KanaSet.values) QuizTopic.kanaMix(kanaSet: set),
    ];

    for (final topic in topics) {
      test(
        '${topic.module?.name ?? 'kanaMix'}/${topic.mode.name}: 10 câu không trùng, 4 đáp án hợp lệ',
        () {
          final provider = quizSessionProvider(topic);
          c.listen(provider, (_, _) {});
          for (var round = 0; round < 20; round++) {
            final s = c.read(provider);
            expect(s.questions, hasLength(10));
            expect(s.questions.map((q) => q.item).toSet(), hasLength(10));
            for (final q in s.questions) {
              expect(q.options, hasLength(4));
              expect(q.options, contains(q.item));
              expect(q.options.map((o) => o.answer).toSet(), hasLength(4));
              expect(q.options.every((o) => o.group == q.item.group), isTrue);
            }
            c.read(provider.notifier).restart();
          }
        },
      );
    }

    test('chọn phần Kana: câu hỏi + đáp án chỉ lấy trong phần đó', () {
      for (final set in KanaSet.values) {
        final allowed = {
          for (final k in KanaTable.of(KanaScript.hiragana, set)) k.char,
        };
        final provider = quizSessionProvider(
          QuizTopic(Module.hiragana, QuizMode.reading, kanaSet: set),
        );
        c.listen(provider, (_, _) {});
        for (var round = 0; round < 10; round++) {
          for (final q in c.read(provider).questions) {
            expect(
              allowed,
              containsAll(q.options.map((o) => o.char)),
              reason: set.name,
            );
          }
          c.read(provider.notifier).restart();
        }
      }
      expect(KanaTable.of(KanaScript.hiragana, KanaSet.basic), hasLength(46));
      expect(KanaTable.of(KanaScript.hiragana, KanaSet.dakuten), hasLength(25));
      expect(KanaTable.of(KanaScript.katakana, KanaSet.all), hasLength(71));
    });

    test(
      'làm hết bài: chấm điểm, câu sai, cộng thống kê người học, xem kết quả',
      () {
        const topic = QuizTopic(Module.hiragana, QuizMode.reading);
        final provider = quizSessionProvider(topic);
        c.listen(provider, (_, _) {});
        final n = c.read(provider.notifier);
        for (var i = 0; i < 10; i++) {
          final q = c.read(provider).current;
          // Câu chẵn đúng, câu lẻ sai.
          n.answer(
            i.isEven ? q.item : q.options.firstWhere((o) => o != q.item),
          );
          n.answer(q.item); // trả lời lại không tính
          expect(c.read(provider).isFinished, isFalse);
          n.next();
        }
        final s = c.read(provider);
        expect(s.isFinished, isTrue);
        expect(s.correctCount, 5);
        expect(s.mistakes, hasLength(5));
        final learner = c.read(learnerProvider);
        expect(learner.answered, 10);
        expect(learner.correct, 5);
      },
    );
  });
}
