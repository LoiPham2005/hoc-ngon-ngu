import 'dart:math';

/// Trạng thái 1 câu trắc nghiệm A–D (dùng chung Kana / Kanji).
class QuizState<T> {
  const QuizState({
    required this.question,
    required this.options,
    this.picked,
    this.correct = 0,
    this.answered = 0,
  });

  final T question;

  /// 4 đáp án (có đúng 1 đáp án đúng, nhãn không trùng nhau).
  final List<T> options;

  /// Đáp án đã chọn; `null` = chưa trả lời câu này.
  final T? picked;
  final int correct;
  final int answered;

  bool get isAnswered => picked != null;
  bool get isCorrect => picked == question;

  QuizState<T> answer(T option) => isAnswered
      ? this
      : QuizState(
          question: question,
          options: options,
          picked: option,
          correct: correct + (option == question ? 1 : 0),
          answered: answered + 1,
        );
}

/// Câu mới (không trùng câu vừa hỏi) + 4 đáp án có [label] khác nhau, giữ điểm của [previous].
/// [distractors] lọc nguồn đáp án nhiễu (mặc định = cả [pool]).
QuizState<T> nextQuestion<T>(
  List<T> pool, {
  required String Function(T item) label,
  required Random random,
  QuizState<T>? previous,
  bool Function(T question, T item)? distractors,
}) {
  T question;
  do {
    question = pool[random.nextInt(pool.length)];
  } while (pool.length > 1 && question == previous?.question);

  final seen = {label(question)};
  final others = [
    for (final item
        in pool.where((i) => distractors?.call(question, i) ?? true).toList()
          ..shuffle(random))
      if (seen.add(label(item))) item,
  ].take(3);
  return QuizState(
    question: question,
    options: [question, ...others]..shuffle(random),
    correct: previous?.correct ?? 0,
    answered: previous?.answered ?? 0,
  );
}
