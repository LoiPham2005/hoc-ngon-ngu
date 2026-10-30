import 'dart:math';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingua/core/services/sound_service.dart';
import 'package:lingua/core/services/speech_service.dart';
import 'package:lingua/design/l10n/l10n_extensions.dart';
import 'package:lingua/design/l10n/locale_notifier.dart';
import 'package:lingua/design/theme/app_colors.dart';
import 'package:lingua/features/course/models/course_model.dart';
import 'package:lingua/features/course/providers/learner_notifier.dart';
import 'package:lingua/features/course/providers/learning_events.dart';
import 'package:lingua/features/lessons/models/lesson_model.dart';
import 'package:lingua/features/lessons/providers/lesson_provider.dart';
import 'package:lingua/features/lessons/widgets/exercise_quiz.dart';
import 'package:lingua/features/lessons/widgets/lesson_widgets.dart';
import 'package:lingua/modules/ads/ad_config.dart';
import 'package:lingua/modules/ads/widgets/native_ad_list.dart';
import 'package:lingua/modules/analytics/analytics_service.dart';
import 'package:lingua/routes/app_router.dart';
import 'package:lingua/shared/base/app_ui.dart';
import 'package:lingua/shared/base/speak_button.dart';
import 'package:lingua/shared/states/async_view.dart';

/// Các nhóm cặp âm người Việt hay nhầm (/iː/–/ɪ/, /l/–/r/, âm cuối…), ✓ = đã luyện đạt.
@RoutePage()
class MinimalPairsPage extends ConsumerWidget {
  const MinimalPairsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final language = ref.watch(localeProvider).languageCode;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.pairs_title)),
      body: AsyncView<List<MinimalPairSet>>(
        state: ref.watch(minimalPairsProvider),
        onRetry: () => ref.invalidate(minimalPairsProvider),
        builder: (context, sets) {
          final learned = learnedCount(ref, sets.map((s) => s.key));
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              Text(
                l10n.pairs_desc,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              RoundedProgress(
                learned / sets.length,
                color: Module.enPronunciation.color,
              ),
              const SizedBox(height: 12),
              ...withNativeAds([
                for (final s in sets)
                  Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    clipBehavior: Clip.antiAlias,
                    child: ListTile(
                      onTap: () =>
                          context.router.push(MinimalPairSetRoute(setId: s.id)),
                      leading: LearnedToggle(s.key),
                      title: Text(s.name(language)),
                      subtitle: Text('${s.pairs.first.a} – ${s.pairs.first.b}'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                    ),
                  ),
              ], NativePlacement.list),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            onPressed: () => context.router.push(MinimalPairQuizRoute()),
            icon: const Icon(Icons.hearing_rounded),
            label: Text(l10n.pairs_practice(_MinimalPairQuiz.length)),
          ),
        ),
      ),
    );
  }
}

/// 1 nhóm cặp âm: mẹo phát âm + các cặp từ (bấm để nghe từng từ) + nút luyện nghe.
@RoutePage()
class MinimalPairSetPage extends ConsumerWidget {
  const MinimalPairSetPage({required this.setId, super.key});

  final String setId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final language = ref.watch(localeProvider).languageCode;
    final state = ref.watch(minimalPairsProvider);
    final set = state.value?.where((s) => s.id == setId).firstOrNull;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(set?.name(language) ?? ''),
        actions: [if (set != null) LearnedToggle(set.key)],
      ),
      body: AsyncView<List<MinimalPairSet>>(
        state: state,
        onRetry: () => ref.invalidate(minimalPairsProvider),
        builder: (context, _) {
          final s = set!;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              Card(
                color: context.colors.primarySoft,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text('💡 ${s.tip}', style: theme.textTheme.bodyMedium),
                ),
              ),
              const SizedBox(height: 12),
              ...withNativeAds([
                for (final p in s.pairs)
                  Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(child: _Word(p.a, p.aVi)),
                          Text('↔', style: theme.textTheme.titleMedium),
                          Expanded(child: _Word(p.b, p.bVi)),
                        ],
                      ),
                    ),
                  ),
              ], NativePlacement.list),
            ],
          );
        },
      ),
      bottomNavigationBar: set == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: FilledButton.icon(
                  onPressed: () =>
                      context.router.push(MinimalPairQuizRoute(setId: setId)),
                  icon: const Icon(Icons.hearing_rounded),
                  label: Text(l10n.pairs_practice(_MinimalPairQuiz.length)),
                ),
              ),
            ),
    );
  }
}

class _Word extends StatelessWidget {
  const _Word(this.word, this.meaning);

  final String word;
  final String meaning;

  @override
  Widget build(BuildContext context) => ListTile(
    dense: true,
    title: Text(word, style: Theme.of(context).textTheme.titleMedium),
    subtitle: Text(meaning),
    trailing: SpeakButton(word, language: 'en-US'),
  );
}

/// Luyện nghe: máy đọc 1 trong 2 từ của cặp → chọn từ vừa nghe.
/// [setId] = null → trộn mọi nhóm; có [setId] và đạt ≥ 70% → đánh dấu nhóm đã luyện.
@RoutePage()
class MinimalPairQuizPage extends HookConsumerWidget {
  const MinimalPairQuizPage({this.setId, super.key});

  final String? setId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(minimalPairsProvider);
    final round = useState(0);
    final sets = state.value;
    if (sets == null) {
      return Scaffold(
        appBar: AppBar(),
        body: AsyncView<List<MinimalPairSet>>(
          state: state,
          onRetry: () => ref.invalidate(minimalPairsProvider),
          builder: (_, _) => const SizedBox.shrink(),
        ),
      );
    }
    final set = sets.where((s) => s.id == setId).firstOrNull;
    return _MinimalPairQuiz(
      key: ValueKey(round.value),
      title:
          set?.name(ref.watch(localeProvider).languageCode) ??
          context.l10n.practice_pairs,
      pairs: [
        for (final s in set == null ? sets : [set]) ...s.pairs,
      ],
      learnedKey: set?.key,
      onRetry: () => round.value++,
    );
  }
}

class _MinimalPairQuiz extends HookConsumerWidget {
  const _MinimalPairQuiz({
    required this.title,
    required this.pairs,
    required this.learnedKey,
    required this.onRetry,
    super.key,
  });

  static const length = 10;

  final String title;
  final List<({String a, String b, String aVi, String bVi})> pairs;
  final String? learnedKey;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.colors;
    final theme = Theme.of(context);
    final speech = ref.read(speechProvider);
    // Mỗi câu: 1 cặp + đọc từ a (true) hay b (false); 2 đáp án hiện theo thứ tự cố định a | b.
    final questions = useMemoized(() {
      final random = Random();
      final shuffled = [...pairs]..shuffle(random);
      return [
        for (var i = 0; i < length; i++)
          (pair: shuffled[i % shuffled.length], playA: random.nextBool()),
      ];
    });
    final index = useState(0);
    final correct = useState(0);
    final picked = useState<bool?>(null); // true = chọn từ a
    final total = questions.length;
    final pass = (total * passRatio).ceil();

    final q = index.value < total ? questions[index.value] : null;
    final target = q == null ? null : (q.playA ? q.pair.a : q.pair.b);
    useEffect(() {
      if (target != null) speech.speak(target, language: 'en-US');
      return null;
    }, [index.value]);

    if (q == null) {
      final passed = correct.value >= pass;
      if (passed && learnedKey != null) {
        ref.read(learnerProvider.notifier).markLearned(learnedKey!);
      }
      return PracticeResult(
        correct: correct.value,
        total: total,
        onRetry: onRetry,
        note: learnedKey == null
            ? null
            : (
                passed
                    ? l10n.grammar_passed
                    : l10n.grammar_passHint(pass, total),
                passed,
              ),
      );
    }

    void answer({required bool a}) {
      if (picked.value != null) return;
      picked.value = a;
      final ok = a == q.playA;
      if (ok) correct.value++;
      ref.read(learnerProvider.notifier).recordAnswer(correct: ok);
      ref.read(soundServiceProvider).answer(correct: ok);
    }

    Widget option(String word, String meaning, {required bool a}) {
      final answered = picked.value != null;
      final isTarget = a == q.playA;
      final (bg, border) = !answered
          ? (null, colors.border)
          : isTarget
          ? (colors.successSoft, colors.success)
          : picked.value == a
          ? (colors.errorSoft, colors.error)
          : (null, colors.border);
      return Expanded(
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(96),
            backgroundColor: bg,
            side: BorderSide(color: border, width: answered ? 2 : 1),
          ),
          onPressed: answered
              ? () => speech.speak(word, language: 'en-US')
              : () => answer(a: a),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(word, style: theme.textTheme.headlineSmall),
              if (answered) Text(meaning, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: index.value / total,
            color: Module.enPronunciation.color,
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
          Text(l10n.quiz_askListening, style: theme.textTheme.titleLarge),
          const SizedBox(height: 24),
          Center(
            child: SizedBox.square(
              dimension: 120,
              child: IconButton.filledTonal(
                onPressed: () => speech.speak(target!, language: 'en-US'),
                icon: const Icon(Icons.volume_up_rounded, size: 56),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.pairs_replay,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              option(q.pair.a, q.pair.aVi, a: true),
              const SizedBox(width: 12),
              option(q.pair.b, q.pair.bVi, a: false),
            ],
          ),
          if (picked.value != null) ...[
            const SizedBox(height: 16),
            AnswerFeedback(ok: picked.value == q.playA, detail: target),
          ],
        ],
      ),
      bottomNavigationBar: picked.value == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: FilledButton(
                  onPressed: () {
                    picked.value = null;
                    index.value++;
                    if (index.value >= total) {
                      ref.read(soundServiceProvider).play(Sfx.complete);
                      ref
                          .read(analyticsServiceProvider)
                          .practiceCompleted(
                            'minimal_pairs',
                            total: total,
                            correct: correct.value,
                          );
                    }
                  },
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
