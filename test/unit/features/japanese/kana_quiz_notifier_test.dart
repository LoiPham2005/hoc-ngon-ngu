import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingua/features/japanese/models/kana_model.dart';
import 'package:lingua/features/japanese/providers/kana_quiz_notifier.dart';

void main() {
  late ProviderContainer container;

  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  test('4 đáp án: có đáp án đúng, romaji không trùng, cùng bảng', () {
    final provider = kanaQuizProvider(QuizScope.both, withDakuten: true);
    container.listen(provider, (_, _) {});
    // Lặp nhiều câu để phủ trường hợp じ/ぢ, ず/づ cùng romaji.
    for (var i = 0; i < 300; i++) {
      final quiz = container.read(provider);
      expect(quiz.options, hasLength(4));
      expect(quiz.options, contains(quiz.question));
      expect(quiz.options.map((k) => k.romaji).toSet(), hasLength(4));
      expect(
        quiz.options.every((k) => k.script == quiz.question.script),
        isTrue,
      );
      container.read(provider.notifier).next();
    }
  });

  test('chỉ Katakana khi chọn Katakana', () {
    final provider = kanaQuizProvider(QuizScope.katakana);
    container.listen(provider, (_, _) {});
    for (var i = 0; i < 50; i++) {
      expect(container.read(provider).question.script, KanaScript.katakana);
      container.read(provider.notifier).next();
    }
  });

  test(
    'chấm điểm: đúng +1, sai +0, trả lời 2 lần chỉ tính 1, câu sau giữ điểm',
    () {
      final provider = kanaQuizProvider(QuizScope.hiragana);
      container.listen(provider, (_, _) {});
      final notifier = container.read(provider.notifier);

      final first = container.read(provider);
      notifier
        ..answer(first.question)
        ..answer(first.options.firstWhere((k) => k != first.question));
      expect(container.read(provider).correct, 1);
      expect(container.read(provider).answered, 1);
      expect(container.read(provider).isCorrect, isTrue);

      notifier.next();
      final second = container.read(provider);
      expect(second.isAnswered, isFalse);
      expect(second.question, isNot(first.question));
      notifier.answer(second.options.firstWhere((k) => k != second.question));
      expect(container.read(provider).correct, 1);
      expect(container.read(provider).answered, 2);
    },
  );
}
