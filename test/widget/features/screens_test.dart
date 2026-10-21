import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingua/features/course/models/course_model.dart';
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
  const sizes = {'iPhone': Size(393, 852), 'nhỏ': Size(360, 640)};
  const variants = [
    (ThemeMode.light, Locale('vi')),
    (ThemeMode.dark, Locale('en')),
  ];

  final screens = <String, (Widget, Future<void> Function(WidgetTester)?)>{
    'onboarding': (const OnboardingPage(), null),
    'trang chủ': (const HomePage(), null),
    'khoá học': (const LearnPage(), null),
    'luyện tập': (const PracticePage(), null),
    'hồ sơ': (const ProfilePage(), null),
    'bảng hiragana': (const KanaTablePage(script: KanaScript.hiragana), null),
    'danh sách kanji N5': (
      const KanjiListPage(level: JlptLevel.n5),
      (t) => loadAsset(t, (c) => c.read(kanjiListProvider.future)),
    ),
    'chi tiết kana': (
      const KanaDetailPage(script: KanaScript.katakana, char: 'ア'),
      (t) => loadAsset(t, (c) => c.read(strokesProvider('ア').future)),
    ),
    'chi tiết kanji 18 nét': (
      const KanjiDetailPage(level: JlptLevel.n4, char: '曜'),
      (t) async {
        await loadAsset(t, (c) => c.read(kanjiListProvider.future));
        await loadAsset(t, (c) => c.read(strokesProvider('曜').future));
      },
    ),
  };

  for (final MapEntry(key: sizeName, value: size) in sizes.entries) {
    for (final (mode, locale) in variants) {
      final suffix = '$sizeName · ${mode.name} · ${locale.languageCode}';
      for (final MapEntry(key: name, value: (page, load)) in screens.entries) {
        testWidgets('$name — $suffix', (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await pumpApp(
            tester,
            page,
            themeMode: mode,
            locale: locale,
            prefs: prefs,
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
}
