import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingua/design/l10n/l10n_extensions.dart';
import 'package:lingua/design/l10n/locale_notifier.dart';
import 'package:lingua/design/theme/app_colors.dart';
import 'package:lingua/features/course/models/course_model.dart';
import 'package:lingua/features/course/providers/learner_notifier.dart';
import 'package:lingua/features/english/models/english_model.dart';
import 'package:lingua/features/english/providers/english_provider.dart';
import 'package:lingua/shared/base/speak_button.dart';
import 'package:lingua/shared/states/async_view.dart';

/// Tỉ lệ đúng tối thiểu để tự đánh dấu "đã thuộc" bài.
const _passRatio = 0.7;

/// Bài tập ngữ pháp: trắc nghiệm điền chỗ trống + ghép câu.
/// [lessonId] = null → trộn 10 câu từ mọi bài (không đánh dấu bài nào).
@RoutePage()
class GrammarPracticePage extends HookConsumerWidget {
  const GrammarPracticePage({this.lessonId, super.key});

  final String? lessonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(localeProvider).languageCode;
    final state = ref.watch(grammarLessonsProvider);
    final lessons = state.value;
    final lesson = lessons?.where((g) => g.id == lessonId).firstOrNull;
    final round = useState(0);
    final exercises = useMemoized(
      () => lessons == null
          ? const <Exercise>[]
          : lesson != null
          ? lesson.exercises
          : ([
              for (final g in lessons) ...g.exercises,
            ]..shuffle()).take(10).toList(),
      [lessons, round.value],
    );
    if (lessons == null) {
      return Scaffold(
        appBar: AppBar(),
        body: AsyncView<List<GrammarLesson>>(
          state: state,
          onRetry: () => ref.invalidate(grammarLessonsProvider),
          builder: (_, _) => const SizedBox.shrink(),
        ),
      );
    }
    return _GrammarQuiz(
      key: ValueKey(round.value),
      title: lesson?.name(language) ?? context.l10n.practice_grammar,
      exercises: exercises,
      lessonKey: lesson?.key,
      onRetry: () => round.value++,
    );
  }
}

class _GrammarQuiz extends HookConsumerWidget {
  const _GrammarQuiz({
    required this.title,
    required this.exercises,
    required this.lessonKey,
    required this.onRetry,
    super.key,
  });

  final String title;
  final List<Exercise> exercises;
  final String? lessonKey;
  final VoidCallback onRetry;

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
    }

    void next() {
      result.value = null;
      index.value++;
      if (index.value == total &&
          lessonKey != null &&
          correct.value >= (total * _passRatio).ceil()) {
        ref.read(learnerProvider.notifier).markLearned(lessonKey!);
      }
    }

    if (index.value >= total) {
      return _GrammarResult(
        correct: correct.value,
        total: total,
        lessonKey: lessonKey,
        onRetry: onRetry,
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
            color: Module.enGrammar.color,
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
          _Feedback(ok: result!, detail: exercise.explain),
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
    super.key,
  });

  final OrderExercise exercise;
  final bool? result;
  final void Function({required bool ok}) onAnswer;

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
          _Feedback(
            ok: result!,
            detail: result!
                ? null
                : l10n.grammar_correctAnswer(exercise.answer),
            speech: exercise.answer,
          ),
      ],
    );
  }
}

/// Dòng "Chính xác! / Chưa đúng" + giải thích hoặc câu đúng, 🔊 nghe câu.
class _Feedback extends StatelessWidget {
  const _Feedback({required this.ok, this.detail, this.speech});

  final bool ok;
  final String? detail;
  final String? speech;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final color = ok ? colors.success : colors.error;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      decoration: BoxDecoration(
        color: ok ? colors.successSoft : colors.errorSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ok ? context.l10n.quiz_correct : context.l10n.quiz_wrong,
                  style: theme.textTheme.titleMedium?.copyWith(color: color),
                ),
                if (detail != null) ...[
                  const SizedBox(height: 2),
                  Text(detail!, style: theme.textTheme.bodyMedium),
                ],
              ],
            ),
          ),
          if (speech != null) SpeakButton(speech!, language: 'en-US'),
        ],
      ),
    );
  }
}

class _GrammarResult extends StatelessWidget {
  const _GrammarResult({
    required this.correct,
    required this.total,
    required this.lessonKey,
    required this.onRetry,
  });

  final int correct;
  final int total;
  final String? lessonKey;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = context.colors;
    final pass = (total * _passRatio).ceil();
    final ratio = correct / total;
    final (emoji, message) = ratio >= 0.9
        ? ('🏆', l10n.result_great)
        : correct >= pass
        ? ('👏', l10n.result_good)
        : ('💪', l10n.result_keepGoing);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Text(
                emoji,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 64),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              Text(
                l10n.result_score(correct, total),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colors.textMuted,
                ),
              ),
              if (lessonKey != null) ...[
                const SizedBox(height: 16),
                Text(
                  correct >= pass
                      ? l10n.grammar_passed
                      : l10n.grammar_passHint(pass, total),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: correct >= pass ? colors.success : colors.warning,
                  ),
                ),
              ],
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onRetry,
                      child: Text(l10n.result_retry),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => context.router.maybePop(),
                      child: Text(l10n.result_done),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
