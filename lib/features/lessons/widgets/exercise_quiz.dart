import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingua/core/services/sound_service.dart';
import 'package:lingua/design/l10n/l10n_extensions.dart';
import 'package:lingua/design/theme/app_colors.dart';
import 'package:lingua/features/course/providers/learner_notifier.dart';
import 'package:lingua/features/course/providers/learning_events.dart';
import 'package:lingua/features/lessons/models/lesson_model.dart';
import 'package:lingua/features/lessons/widgets/lesson_widgets.dart';
import 'package:lingua/modules/analytics/analytics_service.dart';

/// Tỉ lệ đúng tối thiểu để tự đánh dấu "đã thuộc".
const passRatio = 0.7;

/// Làm lần lượt [exercises] (trắc nghiệm / ghép câu) rồi hiện kết quả.
/// Có [learnedKey] → đúng từ [passRatio] trở lên thì tự đánh dấu đã thuộc.
class ExerciseQuiz extends HookConsumerWidget {
  const ExerciseQuiz({
    required this.title,
    required this.exercises,
    required this.learnedKey,
    required this.color,
    required this.onRetry,
    required this.language,
    super.key,
  });

  final String title;
  final List<Exercise> exercises;
  final String? learnedKey;

  /// Màu thanh tiến độ (màu học phần).
  final Color color;
  final VoidCallback onRetry;

  /// Giọng đọc câu đúng (`Course.speechLanguage`).
  final String language;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.colors;
    final index = useState(0);
    final correct = useState(0);
    // Kết quả câu hiện tại: null = chưa trả lời.
    final result = useState<bool?>(null);
    final total = exercises.length;

    void answer({required bool ok}) {
      result.value = ok;
      if (ok) correct.value++;
      ref.read(learnerProvider.notifier).recordAnswer(correct: ok);
      ref.read(soundServiceProvider).answer(correct: ok);
    }

    void next() {
      result.value = null;
      index.value++;
      if (index.value >= total) {
        ref.read(soundServiceProvider).play(Sfx.complete);
        ref
            .read(analyticsServiceProvider)
            .practiceCompleted(
              'lesson_exercise',
              total: total,
              correct: correct.value,
            );
      }
      if (index.value == total &&
          learnedKey != null &&
          correct.value >= (total * passRatio).ceil()) {
        ref.read(learnerProvider.notifier).markLearned(learnedKey!);
      }
    }

    if (index.value >= total) {
      final passed = correct.value >= (total * passRatio).ceil();
      return PracticeResult(
        correct: correct.value,
        total: total,
        onRetry: onRetry,
        note: learnedKey == null
            ? null
            : (
                passed
                    ? l10n.grammar_passed
                    : l10n.grammar_passHint((total * passRatio).ceil(), total),
                passed,
              ),
      );
    }

    final exercise = exercises[index.value];
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: index.value / total,
            color: color,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          Text(
            l10n.quiz_progress(index.value + 1, total),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colors.textMuted),
          ),
          const SizedBox(height: 4),
          switch (exercise) {
            ChoiceExercise() => _ChoiceView(
              key: ValueKey(index.value),
              exercise: exercise,
              result: result.value,
              onAnswer: answer,
            ),
            OrderExercise() => _OrderView(
              key: ValueKey(index.value),
              exercise: exercise,
              result: result.value,
              onAnswer: answer,
              language: language,
            ),
          },
        ],
      ),
      bottomNavigationBar: result.value == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: FilledButton(
                  onPressed: next,
                  child: Text(
                    index.value == total - 1
                        ? l10n.quiz_seeResult
                        : l10n.quiz_continue,
                  ),
                ),
              ),
            ),
    );
  }
}

/// Điền chỗ trống: bấm 1 đáp án → tô xanh đáp án đúng, đỏ đáp án sai + giải thích.
class _ChoiceView extends HookWidget {
  const _ChoiceView({
    required this.exercise,
    required this.result,
    required this.onAnswer,
    super.key,
  });

  final ChoiceExercise exercise;
  final bool? result;
  final void Function({required bool ok}) onAnswer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final picked = useState<int?>(null);
    final answered = result != null;
    final sentence = exercise.prompt.replaceFirst(
      '___',
      answered ? exercise.options[exercise.answer] : '_____',
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(context.l10n.grammar_choiceAsk, style: theme.textTheme.titleSmall),
        const SizedBox(height: 16),
        Text(sentence, style: theme.textTheme.headlineSmall),
        if (exercise.hint case final hint?) ...[
          const SizedBox(height: 4),
          Text(
            hint,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.textMuted,
            ),
          ),
        ],
        const SizedBox(height: 24),
        for (final (i, option) in exercise.options.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                backgroundColor: !answered
                    ? null
                    : i == exercise.answer
                    ? colors.successSoft
                    : i == picked.value
                    ? colors.errorSoft
                    : null,
                side: BorderSide(
                  color: !answered
                      ? colors.border
                      : i == exercise.answer
                      ? colors.success
                      : i == picked.value
                      ? colors.error
                      : colors.border,
                ),
              ),
              onPressed: answered
                  ? null
                  : () {
                      picked.value = i;
                      onAnswer(ok: i == exercise.answer);
                    },
              child: Text(option, style: theme.textTheme.titleMedium),
            ),
          ),
        if (answered) ...[
          const SizedBox(height: 6),
          AnswerFeedback(ok: result!, detail: exercise.explain),
        ],
      ],
    );
  }
}

/// Ghép câu: bấm từ ở dưới để đưa lên dòng trả lời, bấm từ trên dòng để trả lại.
class _OrderView extends HookWidget {
  const _OrderView({
    required this.exercise,
    required this.result,
    required this.onAnswer,
    required this.language,
    super.key,
  });

  final OrderExercise exercise;
  final bool? result;
  final void Function({required bool ok}) onAnswer;
  final String language;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = context.colors;
    final words = exercise.words;
    // Thứ tự xáo trộn (vị trí trong [words]) và các vị trí đã đặt lên dòng.
    final pool = useMemoized(
      () => [for (var i = 0; i < words.length; i++) i]..shuffle(),
    );
    final placed = useState(<int>[]);
    final answered = result != null;
    final border = !answered
        ? colors.border
        : result!
        ? colors.success
        : colors.error;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.grammar_orderAsk, style: theme.textTheme.titleSmall),
        const SizedBox(height: 12),
        Card(
          color: colors.primarySoft,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Text(exercise.meaning, style: theme.textTheme.titleMedium),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            border: Border.all(color: border, width: answered ? 2 : 1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final i in placed.value)
                ActionChip(
                  label: Text(words[i]),
                  onPressed: answered
                      ? null
                      : () => placed.value = [...placed.value]..remove(i),
                ),
              if (placed.value.length == words.length)
                Text(exercise.ending, style: theme.textTheme.titleLarge),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.grammar_orderHint,
          style: theme.textTheme.bodySmall?.copyWith(color: colors.textMuted),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            for (final i in pool)
              if (!placed.value.contains(i))
                ActionChip(
                  label: Text(words[i], style: theme.textTheme.titleMedium),
                  onPressed: answered
                      ? null
                      : () => placed.value = [...placed.value, i],
                ),
          ],
        ),
        const SizedBox(height: 20),
        if (!answered)
          FilledButton(
            onPressed: placed.value.length == words.length
                ? () => onAnswer(
                    // So theo chữ, không theo vị trí: từ lặp lại đổi chỗ vẫn đúng.
                    ok:
                        [for (final i in placed.value) words[i]].join(' ') ==
                        words.join(' '),
                  )
                : null,
            child: Text(l10n.grammar_check),
          )
        else
          AnswerFeedback(
            ok: result!,
            detail: result!
                ? null
                : l10n.grammar_correctAnswer(exercise.display),
            speech: exercise.display,
            language: language,
          ),
      ],
    );
  }
}
