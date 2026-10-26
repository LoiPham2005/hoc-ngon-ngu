import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingua/core/services/sound_service.dart';
import 'package:lingua/design/l10n/l10n_extensions.dart';
import 'package:lingua/design/theme/app_colors.dart';
import 'package:lingua/features/course/models/course_model.dart';
import 'package:lingua/features/course/providers/learner_notifier.dart';
import 'package:lingua/features/course/providers/learning_events.dart';
import 'package:lingua/features/lessons/models/lesson_model.dart';
import 'package:lingua/features/lessons/providers/lesson_provider.dart';
import 'package:lingua/features/lessons/widgets/lesson_widgets.dart';
import 'package:lingua/modules/analytics/analytics_service.dart';
import 'package:lingua/shared/states/async_view.dart';

/// Tự gõ V2, V3 cho 10 động từ bất quy tắc (ưu tiên động từ chưa thuộc) — nhớ chắc hơn trắc nghiệm.
@RoutePage()
class IrregularTypingPage extends HookConsumerWidget {
  const IrregularTypingPage({super.key});

  static const length = 10;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(irregularVerbsProvider);
    final round = useState(0);
    final learned = ref.read(learnerProvider).learned;
    final verbs = useMemoized(() {
      final all = state.value;
      if (all == null) return const <IrregularVerb>[];
      final fresh = all.where((v) => !learned.contains(v.key)).toList()
        ..shuffle();
      final rest = all.where((v) => learned.contains(v.key)).toList()
        ..shuffle();
      return [...fresh, ...rest].take(length).toList();
    }, [state.value, round.value]);

    if (verbs.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.irregular_typing)),
        body: AsyncView<List<IrregularVerb>>(
          state: state,
          onRetry: () => ref.invalidate(irregularVerbsProvider),
          builder: (_, _) => const SizedBox.shrink(),
        ),
      );
    }
    return _TypingSession(
      key: ValueKey(round.value),
      verbs: verbs,
      onRetry: () => round.value++,
    );
  }
}

class _TypingSession extends HookConsumerWidget {
  const _TypingSession({required this.verbs, required this.onRetry, super.key});

  final List<IrregularVerb> verbs;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = context.colors;
    final index = useState(0);
    final correct = useState(0);
    final past = useTextEditingController();
    final participle = useTextEditingController();
    // null = chưa kiểm tra; (đúng V2, đúng V3) sau khi kiểm tra.
    final checked = useState<(bool, bool)?>(null);
    final total = verbs.length;

    if (index.value >= total) {
      return PracticeResult(
        correct: correct.value,
        total: total,
        onRetry: onRetry,
      );
    }
    final verb = verbs[index.value];

    void check() {
      final ok2 = IrregularVerb.matches(verb.past, past.text);
      final ok3 = IrregularVerb.matches(verb.participle, participle.text);
      checked.value = (ok2, ok3);
      if (ok2 && ok3) correct.value++;
      ref
          .read(learnerProvider.notifier)
          .recordAnswer(correct: ok2 && ok3, key: verb.key);
      ref.read(soundServiceProvider).answer(correct: ok2 && ok3);
    }

    void next() {
      past.clear();
      participle.clear();
      checked.value = null;
      index.value++;
      if (index.value >= total) {
        ref.read(soundServiceProvider).play(Sfx.complete);
        ref
            .read(analyticsServiceProvider)
            .practiceCompleted(
              'irregular_verbs',
              total: total,
              correct: correct.value,
            );
      }
    }

    InputDecoration field(String label, bool? ok) => InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
      suffixIcon: ok == null
          ? null
          : Icon(
              ok ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: ok ? colors.success : colors.error,
            ),
    );

    final result = checked.value;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.irregular_typing),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: index.value / total,
            color: Module.enIrregularVerbs.color,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          Text(
            l10n.quiz_progress(index.value + 1, total),
            style: theme.textTheme.bodySmall?.copyWith(color: colors.textMuted),
          ),
          const SizedBox(height: 4),
          Text(l10n.irregular_typeAsk, style: theme.textTheme.titleSmall),
          const SizedBox(height: 16),
          Text(verb.base, style: theme.textTheme.displaySmall),
          Text(verb.meaning, style: theme.textTheme.titleMedium),
          const SizedBox(height: 20),
          TextField(
            controller: past,
            enabled: result == null,
            autocorrect: false,
            textInputAction: TextInputAction.next,
            decoration: field(l10n.irregular_v2, result?.$1),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: participle,
            enabled: result == null,
            autocorrect: false,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => result == null ? check() : null,
            decoration: field(l10n.irregular_v3, result?.$2),
          ),
          const SizedBox(height: 20),
          if (result == null)
            ListenableBuilder(
              listenable: Listenable.merge([past, participle]),
              builder: (context, _) => FilledButton(
                onPressed:
                    past.text.trim().isEmpty || participle.text.trim().isEmpty
                    ? null
                    : check,
                child: Text(l10n.grammar_check),
              ),
            )
          else
            AnswerFeedback(
              ok: result.$1 && result.$2,
              detail: '${verb.base} · ${verb.past} · ${verb.participle}',
              speech: verb.speech,
            ),
        ],
      ),
      bottomNavigationBar: result == null
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
