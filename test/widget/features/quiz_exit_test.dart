import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingua/features/course/models/course_model.dart';
import 'package:lingua/features/japanese/providers/kanji_provider.dart';
import 'package:lingua/features/practice/providers/quiz_session_notifier.dart';
import 'package:lingua/features/practice/quiz_page.dart';

import '../../helpers/pump_app.dart';

/// Đang làm dở → bấm ✕ → "Dừng" phải thoát được khỏi bài.
void main() {
  testWidgets('đã trả lời 1 câu → ✕ → Dừng → thoát bài', (tester) async {
    const topic = QuizTopic(Module.hiragana, QuizMode.reading);
    await pumpApp(
      tester,
      Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const QuizPage(topic: topic),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
      settle: false,
    );
    await loadAsset(tester, (c) => c.read(kanjiListProvider.future));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('A').first); // trả lời 1 câu
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Dừng bài luyện?'), findsOneWidget);

    await tester.tap(find.text('Dừng'));
    await tester.pumpAndSettle();
    expect(find.byType(QuizPage), findsNothing);
    expect(find.text('open'), findsOneWidget);
  });
}
