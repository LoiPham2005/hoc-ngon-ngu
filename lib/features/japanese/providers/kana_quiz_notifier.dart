import 'dart:math';

import 'package:lingua/features/japanese/models/kana_model.dart';
import 'package:lingua/features/japanese/providers/quiz.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'kana_quiz_notifier.g.dart';

/// Chọn bảng để luyện.
enum QuizScope {
  hiragana('Hiragana'),
  katakana('Katakana'),
  both('Cả hai');

  const QuizScope(this.label);

  final String label;
}

/// Hiện 1 chữ ngẫu nhiên → chọn romaji đúng trong 4 đáp án. Đổi bảng/âm đục = phiên mới.
@riverpod
class KanaQuizNotifier extends _$KanaQuizNotifier {
  final _random = Random();

  @override
  QuizState<Kana> build(QuizScope scope, {bool withDakuten = false}) =>
      _next(null);

  void answer(Kana option) => state = state.answer(option);

  void next() => state = _next(state);

  QuizState<Kana> _next(QuizState<Kana>? previous) => nextQuestion(
    [
      for (final script in switch (scope) {
        QuizScope.hiragana => [KanaScript.hiragana],
        QuizScope.katakana => [KanaScript.katakana],
        QuizScope.both => KanaScript.values,
      })
        ...KanaTable.all(script, withDakuten: withDakuten),
    ],
    // じ/ぢ cùng "ji" → không bao giờ là 2 đáp án cùng lúc.
    label: (k) => k.romaji,
    // Đáp án nhiễu cùng bảng với câu hỏi.
    distractors: (q, k) => k.script == q.script,
    random: _random,
    previous: previous,
  );
}
