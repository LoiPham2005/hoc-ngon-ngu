import 'dart:math';

import 'package:lingua/features/japanese/models/kanji_model.dart';
import 'package:lingua/features/japanese/providers/kanji_provider.dart';
import 'package:lingua/features/japanese/providers/quiz.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'kanji_quiz_notifier.g.dart';

/// Hỏi gì: âm Hán Việt hay nghĩa tiếng Việt.
enum KanjiQuizMode {
  hanViet('Âm Hán Việt'),
  meaning('Nghĩa');

  const KanjiQuizMode(this.label);

  final String label;

  String answerOf(Kanji k) => this == hanViet ? k.hanViet : k.meaning;
}

/// Hiện 1 Kanji ngẫu nhiên của cấp [level] → chọn đáp án đúng trong 4 (A–D).
/// Chỉ tạo sau khi `kanjiListProvider` đã tải xong (trang chờ bằng `AsyncView`).
@riverpod
class KanjiQuizNotifier extends _$KanjiQuizNotifier {
  final _random = Random();

  @override
  QuizState<Kanji> build(JlptLevel level, KanjiQuizMode mode) => _next(null);

  void answer(Kanji option) => state = state.answer(option);

  void next() => state = _next(state);

  QuizState<Kanji> _next(QuizState<Kanji>? previous) => nextQuestion(
    [
      for (final k in ref.read(kanjiListProvider).requireValue)
        if (k.level == level) k,
    ],
    label: mode.answerOf,
    random: _random,
    previous: previous,
  );
}
