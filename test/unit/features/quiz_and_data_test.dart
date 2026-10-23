import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingua/core/di/global_providers.dart';
import 'package:lingua/features/course/models/course_model.dart';
import 'package:lingua/features/course/providers/learner_notifier.dart';
import 'package:lingua/features/english/models/english_model.dart';
import 'package:lingua/features/english/providers/english_provider.dart';
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
  TestWidgetsFlutterBinding.ensureInitialized();

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

  group('dữ liệu tiếng Anh', () {
    late ProviderContainer c;

    setUp(() {
      c = ProviderContainer();
      addTearDown(c.dispose);
    });

    test(
      'từ vựng: 44 chủ đề, 1349 từ không trùng, đủ IPA / nghĩa / ví dụ',
      () async {
        final topics = await c.read(vocabTopicsProvider.future);
        final words = [for (final t in topics) ...t.items];
        expect(topics, hasLength(44));
        expect(words, hasLength(1349));
        expect(words.map((w) => w.key).toSet(), hasLength(1349));
        expect(topics.every((t) => t.items.length >= 10), isTrue);
        for (final w in words) {
          expect(
            [w.ipa, w.meaning, w.example, w.exampleVi],
            everyElement(isNotEmpty),
            reason: w.word,
          );
          expect(w.ipa, isNot(contains('/')), reason: w.word);
        }
      },
    );

    test('câu giao tiếp: 15 tình huống × 12 câu', () async {
      final topics = await c.read(phraseTopicsProvider.future);
      expect(topics, hasLength(15));
      expect(topics.every((t) => t.items.length == 12), isTrue);
    });

    test(
      'ngữ pháp: 24 bài, mỗi bài 6 trắc nghiệm + 4 ghép câu hợp lệ',
      () async {
        final lessons = await c.read(grammarLessonsProvider.future);
        expect(lessons, hasLength(24));
        expect(lessons.map((g) => g.id).toSet(), hasLength(24));
        for (final g in lessons) {
          expect(g.formulas, isNotEmpty, reason: g.id);
          expect(g.examples, isNotEmpty, reason: g.id);
          expect(g.exercises.whereType<ChoiceExercise>(), hasLength(6));
          expect(g.exercises.whereType<OrderExercise>(), hasLength(4));
          for (final e in g.exercises) {
            switch (e) {
              case ChoiceExercise():
                expect(
                  '___'.allMatches(e.prompt),
                  hasLength(1),
                  reason: e.prompt,
                );
                expect(e.options.toSet(), hasLength(4), reason: e.prompt);
                expect(e.answer, inInclusiveRange(0, 3));
              case OrderExercise():
                expect(e.ending, isNotEmpty, reason: e.answer);
                expect('${e.words.join(' ')}${e.ending}', e.answer);
                expect(e.words.length, greaterThan(2), reason: e.answer);
            }
          }
        }
      },
    );
  });

  group('english dialogues & sentence check', () {
    test('dialogues: 24, A/B turns, 4 answerable questions each', () async {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final dialogues = await c.read(dialoguesProvider.future);
      expect(dialogues, hasLength(24));
      expect(dialogues.map((d) => d.id).toSet(), hasLength(24));
      for (final d in dialogues) {
        expect(d.lines.length, inInclusiveRange(8, 12), reason: d.id);
        for (final (i, l) in d.lines.indexed) {
          expect(l.speaker, i.isEven ? 'A' : 'B', reason: d.id);
          expect(d.speakers[l.speaker], isNotEmpty, reason: d.id);
        }
        expect(d.questions, hasLength(4), reason: d.id);
        for (final q in d.questions) {
          expect(q.options.toSet(), hasLength(4), reason: q.prompt);
          expect(q.answer, inInclusiveRange(0, 3));
          expect(q.hint, isNotEmpty);
        }
      }
    });

    test('matchWords: ignores case/punctuation, marks missing words', () {
      List<bool> hits(String a, String b) => [
        for (final w in matchWords(a, b)) w.hit,
      ];
      expect(hits('Hi! How are you?', 'hi how are you'), [
        true,
        true,
        true,
        true,
      ]);
      expect(hits("I'm fine, thanks.", 'Im fine thanks'), [false, true, true]);
      expect(hits('I’m fine.', "i'm fine"), [true, true]);
      expect(hits('Can I have the bill, please?', 'can I have bill please'), [
        true,
        true,
        true,
        false,
        true,
        true,
      ]);
      expect(hits('Where is it?', ''), [false, false, false]);
      // Extra words do not count against the expected ones.
      expect(hits('See you.', 'see see you you later'), [true, true]);
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
        else if (m.isKana)
          for (final set in KanaSet.values)
            QuizTopic(m, QuizMode.reading, kanaSet: set),
      for (final set in KanaSet.values) QuizTopic.kanaMix(kanaSet: set),
      const QuizTopic(Module.enVocabulary, QuizMode.meaning),
      const QuizTopic(Module.enVocabulary, QuizMode.listening),
      const QuizTopic(Module.enVocabulary, QuizMode.meaning, group: 'food'),
      const QuizTopic(Module.enPhrases, QuizMode.meaning),
      const QuizTopic(Module.enPhrases, QuizMode.meaning, group: 'hotel'),
    ];

    for (final topic in topics) {
      test(
        '${topic.module?.name ?? 'kanaMix'}/${topic.mode.name}/${topic.group ?? '*'}: 10 câu không trùng, 4 đáp án hợp lệ',
        () async {
          await c.read(quizPoolProvider(topic).future);
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
              if (topic.group != null) expect(q.item.group, topic.group);
            }
            c.read(provider.notifier).restart();
          }
        },
      );
    }

    test('chọn phần Kana: câu hỏi + đáp án chỉ lấy trong phần đó', () async {
      for (final set in KanaSet.values) {
        final allowed = {
          for (final k in KanaTable.of(KanaScript.hiragana, set)) k.char,
        };
        final topic = QuizTopic(
          Module.hiragana,
          QuizMode.reading,
          kanaSet: set,
        );
        await c.read(quizPoolProvider(topic).future);
        final provider = quizSessionProvider(topic);
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
      () async {
        const topic = QuizTopic(Module.hiragana, QuizMode.reading);
        await c.read(quizPoolProvider(topic).future);
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

    test(
      'review quiz only asks due items, empty when nothing is due',
      () async {
        final n = c.read(learnerProvider.notifier);
        var day = DateTime(2026, 10, 1);
        n.now = () => day;
        for (final k in ['あ', 'カ', '日', '会']) {
          await n.toggleLearned(k);
        }
        const topic = QuizTopic.review(Course.ja);
        await c.read(quizPoolProvider(topic).future);
        final provider = quizSessionProvider(topic);
        c.listen(provider, (_, _) {});
        expect(c.read(provider).questions, isEmpty); // due tomorrow

        day = DateTime(2026, 10, 2);
        c.read(provider.notifier).restart();
        final s = c.read(provider);
        expect(s.questions.map((q) => q.item.key).toSet(), {
          'あ',
          'カ',
          '日',
          '会',
        });
        for (final q in s.questions) {
          expect(q.options, hasLength(4));
          expect(q.options.every((o) => o.module == q.item.module), isTrue);
        }
        // Answering everything right clears today's reviews.
        for (var i = 0; i < 4; i++) {
          c.read(provider.notifier)
            ..answer(c.read(provider).current.item)
            ..next();
        }
        expect(n.dueKeys(Course.ja), isEmpty);
      },
    );
  });
}
