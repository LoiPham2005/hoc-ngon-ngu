import 'package:flutter/material.dart';
import 'package:lingua/design/theme/styles/app_color_tokens.dart';
import 'package:lingua/features/japanese/providers/quiz.dart';
import 'package:lingua/shared/base/app_button.dart';

/// Phần thân trắc nghiệm A–D dùng chung Kana / Kanji: chữ hỏi → báo đúng/sai → 4 đáp án → câu tiếp.
/// Đặt trong `Expanded`.
class QuizBoard<T> extends StatelessWidget {
  const QuizBoard({
    required this.quiz,
    required this.prompt,
    required this.ask,
    required this.optionLabel,
    required this.answerText,
    required this.onAnswer,
    required this.onNext,
    required this.onDetail,
    super.key,
  });

  final QuizState<T> quiz;

  /// Chữ hiện to ở giữa (vd 'あ', '日').
  final String prompt;

  /// Câu hỏi khi chưa trả lời, vd 'Chữ này đọc là gì?'.
  final String ask;
  final String Function(T item) optionLabel;

  /// Đáp án đúng trong câu báo sai, vd 'あ đọc là "a"'.
  final String Function(T question) answerText;
  final void Function(T option) onAnswer;
  final VoidCallback onNext;
  final void Function(T question) onDetail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rows = [quiz.options.take(2).toList(), quiz.options.skip(2).toList()];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Center(
            child: FittedBox(
              child: Text(
                prompt,
                style: const TextStyle(fontSize: 120, height: 1),
              ),
            ),
          ),
        ),
        Container(
          constraints: const BoxConstraints(minHeight: 48),
          alignment: Alignment.center,
          child: !quiz.isAnswered
              ? Text(ask, style: theme.textTheme.titleMedium)
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        quiz.isCorrect
                            ? 'Chính xác! 🎉'
                            : 'Sai rồi — ${answerText(quiz.question)}',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: quiz.isCorrect
                              ? context.success
                              : context.error,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => onDetail(quiz.question),
                      child: const Text('Xem cách viết'),
                    ),
                  ],
                ),
        ),
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                for (final option in row) ...[
                  if (option != row.first) const SizedBox(width: 12),
                  Expanded(
                    child: _OptionButton(
                      label:
                          '${'ABCD'[quiz.options.indexOf(option)]}. ${optionLabel(option)}',
                      result: !quiz.isAnswered
                          ? null
                          : option == quiz.question
                          ? true
                          : option == quiz.picked
                          ? false
                          : null,
                      enabled: !quiz.isAnswered,
                      onTap: () => onAnswer(option),
                    ),
                  ),
                ],
              ],
            ),
          ),
        AppButton(
          label: 'Câu tiếp theo',
          icon: Icons.arrow_forward,
          onPressed: quiz.isAnswered ? onNext : null,
        ),
      ],
    );
  }
}

/// Điểm hiện ở AppBar: "Đúng 7/10".
class QuizScore extends StatelessWidget {
  const QuizScore(this.quiz, {super.key});

  final QuizState<Object?> quiz;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Text(
        'Đúng ${quiz.correct}/${quiz.answered}',
        style: Theme.of(context).textTheme.titleSmall,
      ),
    ),
  );
}

class _OptionButton extends StatelessWidget {
  const _OptionButton({
    required this.label,
    required this.result,
    required this.enabled,
    required this.onTap,
  });

  final String label;

  /// `true` = đáp án đúng, `false` = chọn sai, `null` = bình thường.
  final bool? result;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = switch (result) {
      true => context.success,
      false => context.error,
      null => null,
    };
    return OutlinedButton(
      onPressed: enabled ? onTap : () {},
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        backgroundColor: color?.withValues(alpha: 0.15),
        foregroundColor: color,
        side: color == null ? null : BorderSide(color: color, width: 2),
        textStyle: Theme.of(context).textTheme.titleSmall,
      ),
      // Nghĩa Kanji có thể dài → tối đa 2 dòng.
      child: Text(
        label,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
      ),
    );
  }
}
