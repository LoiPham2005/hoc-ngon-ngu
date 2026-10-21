import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingua/features/japanese/japanese_page.dart';
import 'package:lingua/features/japanese/kana_detail_page.dart';
import 'package:lingua/features/japanese/kana_quiz_page.dart';
import 'package:lingua/features/japanese/kanji_detail_page.dart';
import 'package:lingua/features/japanese/kanji_quiz_page.dart';
import 'package:lingua/features/japanese/models/kana_model.dart';
import 'package:lingua/features/japanese/models/kanji_model.dart';
import 'package:lingua/features/japanese/providers/kana_quiz_notifier.dart';
import 'package:lingua/features/japanese/providers/kanji_provider.dart';
import 'package:lingua/features/japanese/providers/kanji_quiz_notifier.dart';
import 'package:lingua/features/japanese/providers/strokes_provider.dart';

import '../../helpers/pump_app.dart';

/// Chờ dữ liệu đọc từ asset: I/O thật, giờ giả lập của test không tự chạy nó.
Future<void> _load(
  WidgetTester tester,
  Future<Object?> Function(ProviderContainer container) read,
) async {
  final container = ProviderScope.containerOf(
    tester.element(find.byType(MaterialApp)),
  );
  await tester.runAsync(() => read(container));
  await tester.pump();
}

/// Render các màn ở cỡ iPhone và máy nhỏ — lỗi tràn layout (overflow) sẽ làm test đỏ.
void main() {
  const sizes = {'iPhone': Size(393, 852), 'nhỏ': Size(360, 640)};
  const kana = Kana('あ', 'a', KanaScript.hiragana);
  const kanji = Kanji(
    char: '曜',
    level: JlptLevel.n4,
    hanViet: 'Diệu',
    meaning: 'ngày trong tuần',
    onyomi: ['ヨウ'],
    kunyomi: [],
  );

  for (final MapEntry(key: name, value: size) in sizes.entries) {
    testWidgets('bảng chữ cái — $name', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await pumpApp(tester, const JapanesePage());

      expect(find.text('あ'), findsOneWidget);
      await tester.tap(find.text('Katakana'));
      await tester.pumpAndSettle();
      expect(find.text('ア'), findsOneWidget);
    });

    testWidgets('chi tiết + tập viết — $name', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await pumpApp(tester, const KanaDetailPage(kana: kana), settle: false);
      await _load(tester, (c) => c.read(strokesProvider(kana.char).future));
      await tester.pump(const Duration(seconds: 3)); // hết hoạt ảnh 3 nét
      expect(find.text('Thứ tự nét (3)'), findsOneWidget);

      await tester.tap(find.text('Tập viết'));
      await tester.pumpAndSettle();
      await tester.drag(
        find.byType(GestureDetector).last,
        const Offset(40, 40),
      );
      await tester.pumpAndSettle();
    });

    testWidgets('luyện tập A/B/C/D — $name', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await pumpApp(tester, const KanaQuizPage());

      expect(find.text('Đúng 0/0'), findsOneWidget);
      // Chọn đáp án SAI — câu báo lỗi dài nhất, dễ tràn nhất.
      final quiz = ProviderScope.containerOf(
        tester.element(find.byType(KanaQuizPage)),
      ).read(kanaQuizProvider(QuizScope.hiragana));
      final wrong = quiz.options.firstWhere((k) => k != quiz.question);
      final letter = 'ABCD'[quiz.options.indexOf(wrong)];
      await tester.tap(find.text('$letter. ${wrong.romaji}'));
      await tester.pumpAndSettle();
      expect(find.text('Đúng 0/1'), findsOneWidget);
      expect(find.textContaining('Sai rồi'), findsOneWidget);
      await tester.tap(find.text('Câu tiếp theo'));
      await tester.pumpAndSettle();
      expect(find.text('Chữ này đọc là gì?'), findsOneWidget);
    });

    testWidgets('tab Kanji — $name', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await pumpApp(tester, const JapanesePage());
      await tester.tap(find.text('Kanji'));
      await tester.pump();
      await _load(tester, (c) => c.read(kanjiListProvider.future));
      await tester.pumpAndSettle();
      expect(find.text('日'), findsOneWidget);
      await tester.tap(find.text('N2'));
      await tester.pumpAndSettle();
      expect(find.text('367 chữ · xếp theo độ thông dụng'), findsOneWidget);
    });

    testWidgets('chi tiết Kanji 18 nét — $name', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await pumpApp(tester, const KanjiDetailPage(kanji: kanji), settle: false);
      await _load(tester, (c) => c.read(strokesProvider(kanji.char).future));
      await tester.pump(const Duration(seconds: 15)); // hết hoạt ảnh 18 nét
      expect(find.text('Thứ tự nét (18)'), findsOneWidget);
      expect(find.text('DIỆU'), findsOneWidget);
    });

    testWidgets('luyện Kanji (nghĩa, chọn sai) — $name', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await pumpApp(tester, const KanjiQuizPage(), settle: false);
      await _load(tester, (c) => c.read(kanjiListProvider.future));
      await tester.pumpAndSettle();
      await tester.tap(find.text('N2'));
      await tester.tap(find.text('Nghĩa'));
      await tester.pumpAndSettle();
      final quiz = ProviderScope.containerOf(
        tester.element(find.byType(KanjiQuizPage)),
      ).read(kanjiQuizProvider(JlptLevel.n2, KanjiQuizMode.meaning));
      final wrong = quiz.options.firstWhere((k) => k != quiz.question);
      final letter = 'ABCD'[quiz.options.indexOf(wrong)];
      await tester.tap(find.text('$letter. ${wrong.meaning}'));
      await tester.pumpAndSettle();
      expect(find.text('Đúng 0/1'), findsOneWidget);
    });
  }
}
