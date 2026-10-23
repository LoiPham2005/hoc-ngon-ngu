import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingua/features/course/models/course_model.dart';
import 'package:lingua/features/course/providers/learner_notifier.dart';
import 'package:lingua/features/home/home_page.dart';
import 'package:lingua/features/japanese/kana_detail_page.dart';
import 'package:lingua/features/japanese/kana_table_page.dart';
import 'package:lingua/features/japanese/kanji_detail_page.dart';
import 'package:lingua/features/japanese/kanji_list_page.dart';
import 'package:lingua/features/japanese/models/kana_model.dart';
import 'package:lingua/features/japanese/models/kanji_model.dart';
import 'package:lingua/features/japanese/providers/kanji_provider.dart';
import 'package:lingua/features/japanese/providers/strokes_provider.dart';
import 'package:lingua/features/learn/learn_page.dart';
import 'package:lingua/features/lessons/dialogue_list_page.dart';
import 'package:lingua/features/lessons/dialogue_page.dart';
import 'package:lingua/features/lessons/grammar_lesson_page.dart';
import 'package:lingua/features/lessons/grammar_list_page.dart';
import 'package:lingua/features/lessons/grammar_practice_page.dart';
import 'package:lingua/features/lessons/irregular_typing_page.dart';
import 'package:lingua/features/lessons/irregular_verbs_page.dart';
import 'package:lingua/features/lessons/minimal_pairs_page.dart';
import 'package:lingua/features/lessons/models/lesson_model.dart';
import 'package:lingua/features/lessons/phrase_list_page.dart';
import 'package:lingua/features/lessons/phrase_order_page.dart';
import 'package:lingua/features/lessons/pronunciation_page.dart';
import 'package:lingua/features/lessons/providers/lesson_provider.dart';
import 'package:lingua/features/lessons/sentence_practice_page.dart';
import 'package:lingua/features/lessons/topics_page.dart';
import 'package:lingua/features/lessons/vocab_list_page.dart';
import 'package:lingua/features/lessons/widgets/lesson_widgets.dart';
import 'package:lingua/features/lessons/word_detail_page.dart';
import 'package:lingua/features/onboarding/onboarding_page.dart';
import 'package:lingua/features/practice/practice_page.dart';
import 'package:lingua/features/practice/providers/quiz_session_notifier.dart';
import 'package:lingua/features/practice/quiz_page.dart';
import 'package:lingua/features/profile/profile_page.dart';
import 'package:lingua/features/profile/voice_settings_page.dart';
import 'package:lingua/features/search/providers/search_provider.dart';
import 'package:lingua/features/search/search_page.dart';
import 'package:lingua/features/stats/stats_page.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../helpers/pump_app.dart';

/// Mọi màn ở 2 cỡ máy × sáng/tối × vi/en — tràn layout (overflow) hay lỗi build sẽ làm test đỏ.
void main() {
  PackageInfo.setMockInitialValues(
    appName: 'Lingua',
    packageName: 'com.loipham.lingua',
    version: '1.0.0',
    buildNumber: '1',
    buildSignature: '',
  );
  // Đã học vài chữ để thấy trạng thái "đã thuộc".
  const prefs = {
    'learner_v1':
        '{"course":"ja","dailyGoal":10,"learned":["あ","か","日"],"answered":12,"correct":9,'
        '"streak":3,"lastActiveDay":"2099-01-01","todayCount":4,"lastModule":"kanjiN5"}',
  };
  const enPrefs = {
    'learner_v1':
        '{"course":"en","dailyGoal":10,"learned":["en:w:rice","en:g:to-be"],"answered":3,"correct":2,'
        '"streak":1,"lastActiveDay":"2099-01-01","todayCount":3,"lastModule":"enVocabulary",'
        '"reviews":{"en:w:rice":[0,"2000-01-01"],"en:p:hotel.0":[2,"2000-01-01"]}}',
  };
  const sizes = {'iPhone': Size(393, 852), 'nhỏ': Size(360, 640)};
  const variants = [
    (ThemeMode.light, Locale('vi')),
    (ThemeMode.dark, Locale('en')),
    (ThemeMode.light, Locale('ja')),
  ];

  Future<void> Function(WidgetTester) english(
    Future<Object?> Function(ProviderContainer c) read,
  ) =>
      (t) => loadAsset(t, read);
  final vocab = english((c) => c.read(vocabTopicsProvider(Course.en).future));
  final phrases = english(
    (c) => c.read(phraseTopicsProvider(Course.en).future),
  );
  final grammar = english(
    (c) => c.read(grammarLessonsProvider(Course.en).future),
  );
  final dialogues = english((c) => c.read(dialoguesProvider(Course.en).future));
  final jaVocab = english((c) => c.read(vocabTopicsProvider(Course.ja).future));
  final jaPhrases = english(
    (c) => c.read(phraseTopicsProvider(Course.ja).future),
  );
  final jaGrammar = english(
    (c) => c.read(grammarLessonsProvider(Course.ja).future),
  );
  final jaDialogues = english(
    (c) => c.read(dialoguesProvider(Course.ja).future),
  );
  final pairs = english((c) => c.read(minimalPairsProvider.future));
  Future<void> jaSearch(WidgetTester t) =>
      loadAsset(t, (c) => c.read(searchIndexProvider(Course.ja).future));

  final screens =
      <
        String,
        (Widget, Future<void> Function(WidgetTester)?, Map<String, Object>?)
      >{
        'EN trang chủ': (const HomePage(), null, enPrefs),
        'EN khoá học': (const LearnPage(), null, enPrefs),
        'EN luyện tập': (const PracticePage(), null, enPrefs),
        'EN phát âm IPA': (const PronunciationPage(), null, enPrefs),
        'EN chủ đề từ vựng': (
          const TopicsPage(module: Module.enVocabulary),
          vocab,
          enPrefs,
        ),
        'EN tình huống giao tiếp': (
          const TopicsPage(module: Module.enPhrases),
          phrases,
          enPrefs,
        ),
        'EN từ vựng đồ ăn': (
          const VocabListPage(course: Course.en, topicId: 'food'),
          vocab,
          enPrefs,
        ),
        'EN chi tiết từ': (
          const WordDetailPage(
            course: Course.en,
            topicId: 'food',
            word: 'rice',
          ),
          vocab,
          enPrefs,
        ),
        'EN câu ở nhà hàng': (
          const PhraseListPage(course: Course.en, topicId: 'restaurant'),
          phrases,
          enPrefs,
        ),
        'EN ngữ pháp': (
          const GrammarListPage(course: Course.en),
          grammar,
          enPrefs,
        ),
        'EN hội thoại': (
          const DialogueListPage(course: Course.en),
          dialogues,
          enPrefs,
        ),
        'EN 1 hội thoại': (
          const DialoguePage(
            course: Course.en,
            dialogueId: 'complaining-in-a-restaurant',
          ),
          dialogues,
          enPrefs,
        ),
        'EN nghe – chép': (
          const SentencePracticePage(
            course: Course.en,
            mode: SentenceMode.dictation,
          ),
          phrases,
          enPrefs,
        ),
        'EN luyện nói': (
          const SentencePracticePage(
            course: Course.en,
            mode: SentenceMode.speaking,
            topicId: 'restaurant',
          ),
          phrases,
          enPrefs,
        ),
        'EN hồ sơ': (const ProfilePage(), null, enPrefs),
        'EN bài ngữ pháp': (
          const GrammarLessonPage(
            course: Course.en,
            lessonId: 'present-perfect',
          ),
          grammar,
          enPrefs,
        ),
        'JA chủ đề từ vựng': (
          const TopicsPage(module: Module.jaVocabulary),
          jaVocab,
          null,
        ),
        'JA từ vựng đồ ăn': (
          const VocabListPage(course: Course.ja, topicId: 'food'),
          jaVocab,
          null,
        ),
        'JA chi tiết từ': (
          const WordDetailPage(course: Course.ja, topicId: 'food', word: '食べる'),
          jaVocab,
          null,
        ),
        'JA câu ở nhà hàng': (
          const PhraseListPage(course: Course.ja, topicId: 'restaurant'),
          jaPhrases,
          null,
        ),
        'JA ngữ pháp': (
          const GrammarListPage(course: Course.ja),
          jaGrammar,
          null,
        ),
        'JA bài thể て': (
          const GrammarLessonPage(course: Course.ja, lessonId: 'te-form'),
          jaGrammar,
          null,
        ),
        'JA hội thoại': (
          const DialogueListPage(course: Course.ja),
          jaDialogues,
          null,
        ),
        'JA 1 hội thoại': (
          const DialoguePage(course: Course.ja, dialogueId: 'at-a-cafe'),
          jaDialogues,
          null,
        ),
        'JA nghe – chép': (
          const SentencePracticePage(
            course: Course.ja,
            mode: SentenceMode.dictation,
          ),
          jaPhrases,
          null,
        ),
        'JA luyện nói': (
          const SentencePracticePage(
            course: Course.ja,
            mode: SentenceMode.speaking,
            topicId: 'restaurant',
          ),
          jaPhrases,
          null,
        ),
        'EN động từ bất quy tắc': (
          const IrregularVerbsPage(),
          english((c) => c.read(irregularVerbsProvider.future)),
          enPrefs,
        ),
        'EN tự gõ V2 V3': (
          const IrregularTypingPage(),
          english((c) => c.read(irregularVerbsProvider.future)),
          enPrefs,
        ),
        'EN cặp âm': (const MinimalPairsPage(), pairs, enPrefs),
        'EN 1 nhóm cặp âm': (
          const MinimalPairSetPage(setId: 'final-s'),
          pairs,
          enPrefs,
        ),
        'EN luyện nghe cặp âm': (const MinimalPairQuizPage(), pairs, enPrefs),
        'EN ghép câu giao tiếp': (
          const PhraseOrderPage(course: Course.en, topicId: 'restaurant'),
          phrases,
          enPrefs,
        ),
        'JA ghép câu giao tiếp': (
          const PhraseOrderPage(course: Course.ja),
          jaPhrases,
          null,
        ),
        'giọng đọc': (const VoiceSettingsPage(), null, null),
        'tra cứu': (const SearchPage(), jaSearch, null),
        'thống kê': (const StatsPage(), null, null),
        'EN thống kê': (const StatsPage(), null, enPrefs),
        'onboarding': (const OnboardingPage(), null, null),
        'trang chủ': (const HomePage(), null, null),
        'khoá học': (const LearnPage(), null, null),
        'luyện tập': (const PracticePage(), null, null),
        'hồ sơ': (const ProfilePage(), null, null),
        'bảng hiragana': (
          const KanaTablePage(script: KanaScript.hiragana),
          null,
          null,
        ),
        'danh sách kanji N5': (
          const KanjiListPage(level: JlptLevel.n5),
          (t) => loadAsset(t, (c) => c.read(kanjiListProvider.future)),
          null,
        ),
        'chi tiết kana': (
          const KanaDetailPage(script: KanaScript.katakana, char: 'ア'),
          (t) => loadAsset(t, (c) => c.read(strokesProvider('ア').future)),
          null,
        ),
        'chi tiết kanji 18 nét': (
          const KanjiDetailPage(level: JlptLevel.n4, char: '曜'),
          (t) async {
            await loadAsset(t, (c) => c.read(kanjiListProvider.future));
            await loadAsset(t, (c) => c.read(strokesProvider('曜').future));
          },
          null,
        ),
      };

  for (final MapEntry(key: sizeName, value: size) in sizes.entries) {
    for (final (mode, locale) in variants) {
      final suffix = '$sizeName · ${mode.name} · ${locale.languageCode}';
      for (final MapEntry(key: name, value: (page, load, pagePrefs))
          in screens.entries) {
        testWidgets('$name — $suffix', (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await pumpApp(
            tester,
            page,
            themeMode: mode,
            locale: locale,
            prefs: pagePrefs ?? prefs,
            settle: false,
          );
          await load?.call(tester);
          await tester.pump(
            const Duration(seconds: 20),
          ); // hết hoạt ảnh nét viết
          expect(tester.takeException(), isNull);
        });
      }

      testWidgets('làm bài kanji (sai 1 câu) tới màn kết quả — $suffix', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final topic = QuizTopic(
          Module.kanjiN3,
          locale.languageCode == 'vi' ? QuizMode.hanViet : QuizMode.meaning,
        );
        await pumpApp(
          tester,
          QuizPage(topic: topic),
          themeMode: mode,
          locale: locale,
          prefs: prefs,
          settle: false,
        );
        await loadAsset(tester, (c) => c.read(kanjiListProvider.future));
        await tester.pumpAndSettle();

        final container = ProviderScope.containerOf(
          tester.element(find.byType(QuizPage)),
        );
        for (var i = 0; i < 10; i++) {
          final q = container.read(quizSessionProvider(topic)).current;
          final pick = i == 0
              ? q.options.firstWhere((o) => o != q.item)
              : q.item;
          await tester.tap(find.text(pick.answer).first);
          await tester.pumpAndSettle();
          await tester.tap(
            find.byType(FilledButton).last,
          ); // Tiếp tục / Xem kết quả
          await tester.pumpAndSettle();
        }
        expect(find.text('90%'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  for (final course in [Course.en, Course.ja]) {
    testWidgets(
      '${course.name} grammar: all correct (choice + sentence building) → learned',
      (tester) async {
        final lesson = GrammarLesson.fromJson(
          (jsonDecode(
                    File(
                      'assets/${course.assetDir}/grammar.json',
                    ).readAsStringSync(),
                  )
                  as List)
              .cast<Map<String, dynamic>>()
              .first,
          course,
        );
        await pumpApp(
          tester,
          GrammarPracticePage(course: course, lessonId: lesson.id),
          prefs: enPrefs,
          settle: false,
        );
        await loadAsset(
          tester,
          (c) => c.read(grammarLessonsProvider(course).future),
        );
        await tester.pumpAndSettle();
        final container = ProviderScope.containerOf(
          tester.element(find.byType(GrammarPracticePage)),
        );

        for (final e in lesson.exercises) {
          switch (e) {
            case ChoiceExercise():
              await tester.tap(find.text(e.options[e.answer]));
            case OrderExercise():
              // Cụm đã đặt nằm trên dòng trả lời (trước) → cụm còn trong kho là `.last`.
              for (final w in e.words) {
                await tester.tap(find.widgetWithText(ActionChip, w).last);
                await tester.pump();
              }
              await tester.tap(find.text('Kiểm tra'));
          }
          await tester.pumpAndSettle();
          expect(find.text('Chính xác!'), findsOneWidget);
          await tester.tap(find.byType(FilledButton).last);
          await tester.pumpAndSettle();
        }
        expect(find.text('Đã thuộc bài này ✓'), findsOneWidget);
        expect(container.read(learnerProvider).learned, contains(lesson.key));
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('dialogue quiz: all correct → marked as understood', (
    tester,
  ) async {
    final dialogue = Dialogue.fromJson(
      (jsonDecode(File('assets/english/dialogues.json').readAsStringSync())
              as List)
          .cast<Map<String, dynamic>>()
          .first,
      Course.en,
    );
    await pumpApp(
      tester,
      DialogueQuizPage(course: Course.en, dialogueId: dialogue.id),
      prefs: enPrefs,
      settle: false,
    );
    await loadAsset(tester, (c) => c.read(dialoguesProvider(Course.en).future));
    await tester.pumpAndSettle();
    for (final q in dialogue.questions) {
      await tester.tap(find.text(q.options[q.answer]));
      await tester.pumpAndSettle();
      expect(find.text('Chính xác!'), findsOneWidget);
      await tester.tap(find.byType(FilledButton).last);
      await tester.pumpAndSettle();
    }
    expect(find.text('Đã thuộc bài này ✓'), findsOneWidget);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(DialogueQuizPage)),
    );
    expect(container.read(learnerProvider).learned, contains(dialogue.key));
  });

  testWidgets('dictation: wrong sentence shows word-by-word check', (
    tester,
  ) async {
    await pumpApp(
      tester,
      const SentencePracticePage(
        course: Course.en,
        mode: SentenceMode.dictation,
        topicId: 'greetings',
      ),
      prefs: enPrefs,
      settle: false,
    );
    await loadAsset(
      tester,
      (c) => c.read(phraseTopicsProvider(Course.en).future),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'banana');
    await tester.pump();
    await tester.tap(find.text('Kiểm tra'));
    await tester.pumpAndSettle();
    expect(find.text('Chưa đúng rồi'), findsOneWidget);
    expect(find.byType(WordMatchText), findsOneWidget);
    expect(find.text('Tiếp tục'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('home: review card opens today\'s due items', (tester) async {
    await pumpApp(tester, const HomePage(), prefs: enPrefs, settle: false);
    await tester.pump();
    expect(find.text('2 mục cần ôn — ôn ngay để nhớ lâu'), findsOneWidget);
    expect(find.text('Ôn ngay'), findsOneWidget);
  });

  testWidgets(
    'irregular verbs typing: correct forms → right, wrong → shows answer',
    (tester) async {
      final verbs = {
        for (final v
            in (jsonDecode(
                      File(
                        'assets/english/irregular_verbs.json',
                      ).readAsStringSync(),
                    )
                    as List)
                .cast<Map<String, dynamic>>())
          v['v1'] as String: IrregularVerb.fromJson(v),
      };
      await pumpApp(
        tester,
        const IrregularTypingPage(),
        prefs: enPrefs,
        settle: false,
      );
      await loadAsset(tester, (c) => c.read(irregularVerbsProvider.future));
      await tester.pumpAndSettle();

      // Động từ đang hỏi = chữ to (displaySmall) trên màn.
      IrregularVerb current() =>
          verbs[tester
              .widgetList<Text>(find.byType(Text))
              .map((t) => t.data)
              .firstWhere(verbs.containsKey)]!;

      var v = current();
      await tester.enterText(
        find.byType(TextField).at(0),
        v.past.split('/').first,
      );
      await tester.enterText(
        find.byType(TextField).at(1),
        v.participle.split('/').last,
      );
      await tester.pump();
      await tester.tap(find.text('Kiểm tra'));
      await tester.pumpAndSettle();
      expect(find.text('Chính xác!'), findsOneWidget);
      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();

      v = current();
      await tester.enterText(find.byType(TextField).at(0), 'xxx');
      await tester.enterText(find.byType(TextField).at(1), 'yyy');
      await tester.pump();
      await tester.tap(find.text('Kiểm tra'));
      await tester.pumpAndSettle();
      expect(find.text('Chưa đúng rồi'), findsOneWidget);
      expect(
        find.text('${v.base} · ${v.past} · ${v.participle}'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('minimal pair quiz: picking a word reveals the answer', (
    tester,
  ) async {
    await pumpApp(
      tester,
      const MinimalPairQuizPage(setId: 'l-r'),
      prefs: enPrefs,
      settle: false,
    );
    await loadAsset(tester, (c) => c.read(minimalPairsProvider.future));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(OutlinedButton).first);
    await tester.pumpAndSettle();
    expect(
      find.text('Chính xác!').evaluate().length +
          find.text('Chưa đúng rồi').evaluate().length,
      1,
    );
    expect(find.text('Tiếp tục'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
