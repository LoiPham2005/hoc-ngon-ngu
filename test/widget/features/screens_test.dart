import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingua/features/course/models/course_model.dart';
import 'package:lingua/features/course/providers/learner_notifier.dart';
import 'package:lingua/features/english/english_topics_page.dart';
import 'package:lingua/features/english/grammar_lesson_page.dart';
import 'package:lingua/features/english/grammar_list_page.dart';
import 'package:lingua/features/english/grammar_practice_page.dart';
import 'package:lingua/features/english/models/english_model.dart';
import 'package:lingua/features/english/phrase_list_page.dart';
import 'package:lingua/features/english/pronunciation_page.dart';
import 'package:lingua/features/english/providers/english_provider.dart';
import 'package:lingua/features/english/vocab_list_page.dart';
import 'package:lingua/features/english/word_detail_page.dart';
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
import 'package:lingua/features/onboarding/onboarding_page.dart';
import 'package:lingua/features/practice/practice_page.dart';
import 'package:lingua/features/practice/providers/quiz_session_notifier.dart';
import 'package:lingua/features/practice/quiz_page.dart';
import 'package:lingua/features/profile/profile_page.dart';
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
        '"streak":1,"lastActiveDay":"2099-01-01","todayCount":3,"lastModule":"enVocabulary"}',
  };
  const sizes = {'iPhone': Size(393, 852), 'nhỏ': Size(360, 640)};
  const variants = [
    (ThemeMode.light, Locale('vi')),
    (ThemeMode.dark, Locale('en')),
  ];

  Future<void> Function(WidgetTester) english(
    Future<Object?> Function(ProviderContainer c) read,
  ) =>
      (t) => loadAsset(t, read);
  final vocab = english((c) => c.read(vocabTopicsProvider.future));
  final phrases = english((c) => c.read(phraseTopicsProvider.future));
  final grammar = english((c) => c.read(grammarLessonsProvider.future));

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
          const EnglishTopicsPage(module: Module.enVocabulary),
          vocab,
          enPrefs,
        ),
        'EN tình huống giao tiếp': (
          const EnglishTopicsPage(module: Module.enPhrases),
          phrases,
          enPrefs,
        ),
        'EN từ vựng đồ ăn': (
          const VocabListPage(topicId: 'food'),
          vocab,
          enPrefs,
        ),
        'EN chi tiết từ': (
          const WordDetailPage(topicId: 'food', word: 'rice'),
          vocab,
          enPrefs,
        ),
        'EN câu ở nhà hàng': (
          const PhraseListPage(topicId: 'restaurant'),
          phrases,
          enPrefs,
        ),
        'EN ngữ pháp': (const GrammarListPage(), grammar, enPrefs),
        'EN bài ngữ pháp': (
          const GrammarLessonPage(lessonId: 'present-perfect'),
          grammar,
          enPrefs,
        ),
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

  testWidgets(
    'bài ngữ pháp: làm đúng hết (trắc nghiệm + ghép câu) → đánh dấu đã thuộc',
    (tester) async {
      final lesson = GrammarLesson.fromJson(
        (jsonDecode(File('assets/english/grammar.json').readAsStringSync())
                as List)
            .cast<Map<String, dynamic>>()
            .first,
      );
      await pumpApp(
        tester,
        GrammarPracticePage(lessonId: lesson.id),
        prefs: enPrefs,
        settle: false,
      );
      await loadAsset(tester, (c) => c.read(grammarLessonsProvider.future));
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(GrammarPracticePage)),
      );
      await container.read(learnerProvider.notifier).toggleLearned(lesson.key);

      for (final e in lesson.exercises) {
        switch (e) {
          case ChoiceExercise():
            await tester.tap(find.text(e.options[e.answer]));
          case OrderExercise():
            // Từ đã đặt nằm trên dòng trả lời (trước) → từ còn trong kho là `.last`.
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
