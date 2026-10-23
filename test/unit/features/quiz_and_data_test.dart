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
import 'package:lingua/features/lessons/models/lesson_model.dart';
import 'package:lingua/features/lessons/phrase_order_page.dart';
import 'package:lingua/features/lessons/providers/lesson_provider.dart';
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

  // Số lượng nội dung mỗi khoá: (chủ đề từ, số từ, số hội thoại, tình huống giao tiếp, bài ngữ pháp).
  const content = {
    Course.en: (44, 1459, 24, 25, 36),
    Course.ja: (24, 690, 20, 15, 24),
  };

  for (final MapEntry(
        key: course,
        value: (topicCount, wordCount, dialogueCount, situations, lessonCount),
      )
      in content.entries) {
    group('${course.name} lesson data', () {
      late ProviderContainer c;

      setUp(() {
        c = ProviderContainer();
        addTearDown(c.dispose);
      });

      test(
        'vocabulary: $topicCount topics, $wordCount unique words, complete fields',
        () async {
          final topics = await c.read(vocabTopicsProvider(course).future);
          final words = [for (final t in topics) ...t.items];
          expect(topics, hasLength(topicCount));
          expect(words, hasLength(wordCount));
          expect(words.map((w) => w.key).toSet(), hasLength(wordCount));
          expect(topics.every((t) => t.items.length >= 10), isTrue);
          for (final w in words) {
            expect(
              [w.reading, w.meaning, w.example, w.exampleVi],
              everyElement(isNotEmpty),
              reason: w.word,
            );
            if (course == Course.en) {
              expect(w.reading, isNot(contains('/')), reason: w.word);
            } else {
              expect(
                w.reading,
                matches(r'^[\u3040-\u30ffー]+$'),
                reason: w.word,
              );
              expect(w.exampleReading, isNotEmpty, reason: w.word);
              expect(w.level, anyOf('N5', 'N4'), reason: w.word);
            }
          }
        },
      );

      test('phrases: $situations situations × 12', () async {
        final topics = await c.read(phraseTopicsProvider(course).future);
        expect(topics, hasLength(situations));
        expect(topics.every((t) => t.items.length == 12), isTrue);
        if (course == Course.ja) {
          for (final t in topics) {
            expect(t.items.every((p) => p.reading != null), isTrue);
          }
        }
      });

      test(
        'grammar: $lessonCount lessons, 6 choice + 4 valid sentence-building each',
        () async {
          final lessons = await c.read(grammarLessonsProvider(course).future);
          expect(lessons, hasLength(lessonCount));
          expect(lessons.map((g) => g.id).toSet(), hasLength(lessonCount));
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
                  expect(e.display, isNot(contains('  ')));
              }
            }
          }
        },
      );

      test('dialogues: $dialogueCount, A/B turns, 4 questions each', () async {
        final dialogues = await c.read(dialoguesProvider(course).future);
        expect(dialogues, hasLength(dialogueCount));
        expect(dialogues.map((d) => d.id).toSet(), hasLength(dialogueCount));
        for (final d in dialogues) {
          expect(d.lines.length, inInclusiveRange(8, 12), reason: d.id);
          for (final (i, l) in d.lines.indexed) {
            expect(l.speaker, i.isEven ? 'A' : 'B', reason: d.id);
            expect(d.speakers[l.speaker], isNotEmpty, reason: d.id);
            expect(l.sentence.text, isNotEmpty, reason: d.id);
          }
          expect(d.questions, hasLength(4), reason: d.id);
          for (final q in d.questions) {
            expect(q.options.toSet(), hasLength(4), reason: q.prompt);
            expect(q.answer, inInclusiveRange(0, 3));
            expect(q.hint, isNotEmpty);
          }
        }
      });
    });
  }

  group('english extra data', () {
    late ProviderContainer c;

    setUp(() {
      c = ProviderContainer();
      addTearDown(c.dispose);
    });

    test('irregular verbs: 100 unique, pattern matches the forms', () async {
      final verbs = await c.read(irregularVerbsProvider.future);
      expect(verbs, hasLength(100));
      expect(verbs.map((v) => v.base).toSet(), hasLength(100));
      for (final v in verbs) {
        final (a, b, c) = (
          v.base,
          v.past.split('/').first,
          v.participle.split('/').first,
        );
        final expected = a == b && b == c
            ? 'AAA'
            : b == c
            ? 'ABB'
            : a == c
            ? 'ABA'
            : 'ABC';
        expect(v.pattern, expected, reason: v.base);
        expect(IrregularVerb.matches(v.past, v.past.split('/').last), isTrue);
      }
      expect(IrregularVerb.matches('was/were', ' Were '), isTrue);
      expect(IrregularVerb.matches('went', 'goed'), isFalse);
    });

    test('minimal pairs: 16 sound groups × 8 real pairs', () async {
      final sets = await c.read(minimalPairsProvider.future);
      expect(sets, hasLength(16));
      for (final s in sets) {
        expect(s.pairs, hasLength(8), reason: s.id);
        for (final p in s.pairs) {
          expect(p.a, isNot(p.b));
          expect([p.aVi, p.bVi], everyElement(isNotEmpty));
        }
      }
    });

    test('phrase building: most phrases become 3–9 word exercises', () async {
      for (final course in [Course.en, Course.ja]) {
        final phrases = [
          for (final t in await c.read(phraseTopicsProvider(course).future))
            ...t.items,
        ];
        final exercises = [
          for (final p in phrases) ?PhraseOrderPage.exerciseOf(p),
        ];
        expect(exercises.length, greaterThan(phrases.length ~/ 2));
        for (final e in exercises) {
          expect(e.words.length, inInclusiveRange(3, 9));
          expect('${e.words.join(' ')}${e.ending}', e.answer);
        }
      }
    });
  });

  group('sentence check', () {
    test('Japanese: compares by character, kana or kanji input both work', () {
      List<bool> hits(String text, String? reading, String input) => [
        for (final w in matchSentence(text, reading, input)) w.hit,
      ];
      // Gõ kana (Katakana = Hiragana), bỏ dấu câu, dấu cách.
      expect(hits('水をください。', 'みずを ください。', 'ミズヲ ください'), everyElement(isTrue));
      // Nói / gõ đúng Kanji.
      expect(hits('水をください。', 'みずを ください。', '水をください'), everyElement(isTrue));
      expect(
        matchRatio(matchSentence('水をください。', 'みずを ください。', 'みず')),
        closeTo(2 / 7, 1e-9),
      );
      expect(
        const OrderExercise(answer: 'わたし は 学生 です。', meaning: '').display,
        'わたしは学生です。',
      );
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
      const QuizTopic(Module.jaVocabulary, QuizMode.meaning),
      const QuizTopic(Module.jaVocabulary, QuizMode.listening),
      const QuizTopic(Module.jaVocabulary, QuizMode.meaning, group: 'food'),
      const QuizTopic(Module.jaPhrases, QuizMode.meaning),
      const QuizTopic(Module.enIrregularVerbs, QuizMode.meaning),
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
              expect(q.options.every((o) => o.module == q.item.module), isTrue);
              // Nhóm động từ ABA chỉ có 3 từ → được lấy thêm đáp án nhiễu khác nhóm.
              if (q.item.group != 'ABA') {
                expect(q.options.every((o) => o.group == q.item.group), isTrue);
              }
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
