import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingua/design/l10n/l10n_extensions.dart';
import 'package:lingua/design/theme/app_colors.dart';
import 'package:lingua/features/course/models/course_model.dart';
import 'package:lingua/features/course/providers/learner_notifier.dart';
import 'package:lingua/features/lessons/models/lesson_model.dart';
import 'package:lingua/features/lessons/providers/lesson_provider.dart';
import 'package:lingua/features/lessons/widgets/lesson_widgets.dart';
import 'package:lingua/routes/app_router.dart';
import 'package:lingua/shared/base/speak_button.dart';
import 'package:lingua/shared/states/async_view.dart';

/// Chi tiết 1 từ: từ, phiên âm, loại từ, nghĩa, câu ví dụ (đều nghe được), đã thuộc, từ trước/sau.
@RoutePage()
class WordDetailPage extends ConsumerWidget {
  const WordDetailPage({
    required this.course,
    required this.topicId,
    required this.word,
    super.key,
  });

  final Course course;

  final String topicId;
  final String word;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(vocabTopicsProvider(course));
    return Scaffold(
      appBar: AppBar(
        title: Text(
          Module.lesson(course, LessonKind.vocabulary)!.title(context),
        ),
      ),
      body: AsyncView<List<Topic<Word>>>(
        state: state,
        onRetry: () => ref.invalidate(vocabTopicsProvider(course)),
        builder: (context, topics) {
          final words = topics.firstWhere((t) => t.id == topicId).items;
          final index = words.indexWhere((w) => w.word == word);
          final w = words[index];
          return SafeArea(
            child: _WordView(word: w, index: index, words: words),
          );
        },
      ),
    );
  }
}

class _WordView extends ConsumerWidget {
  const _WordView({
    required this.word,
    required this.index,
    required this.words,
  });

  final Word word;
  final int index;
  final List<Word> words;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.colors;
    final theme = Theme.of(context);
    final learned = ref.watch(
      learnerProvider.select((l) => l.learned.contains(word.key)),
    );
    void open(Word w) => context.router.replace(
      WordDetailRoute(course: w.course, topicId: w.topicId, word: w.word),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Wrap(
                        spacing: 6,
                        children: [
                          Tag(posLabel(context, word.pos)),
                          if (word.level case final level?) Tag(level),
                        ],
                      ),
                      const SizedBox(height: 10),
                      FittedBox(
                        child: Text(
                          word.word,
                          style: theme.textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (word.readingLabel case final reading?)
                        Text(
                          reading,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colors.textMuted,
                          ),
                        ),
                      const SizedBox(height: 12),
                      SpeakButton(
                        word.word,
                        language: word.course.speechLanguage,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        word.meaning,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: colors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.word_example,
                              style: theme.textTheme.labelSmall,
                            ),
                            const SizedBox(height: 4),
                            SentenceText(
                              word.example,
                              reading: word.exampleReading,
                              meaning: word.exampleVi,
                            ),
                          ],
                        ),
                      ),
                      SpeakButton(
                        word.example,
                        language: word.course.speechLanguage,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton.icon(
                onPressed: () =>
                    ref.read(learnerProvider.notifier).toggleLearned(word.key),
                style: learned
                    ? FilledButton.styleFrom(
                        backgroundColor: colors.successSoft,
                        foregroundColor: colors.success,
                      )
                    : null,
                icon: Icon(
                  learned ? Icons.check_circle_rounded : Icons.add_task_rounded,
                ),
                label: Text(
                  learned ? l10n.detail_learned : l10n.detail_markLearned,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton.filledTonal(
                    onPressed: index > 0 ? () => open(words[index - 1]) : null,
                    icon: const Icon(Icons.chevron_left_rounded),
                  ),
                  Expanded(
                    child: Text(
                      '${index + 1} / ${words.length}',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: index < words.length - 1
                        ? () => open(words[index + 1])
                        : null,
                    icon: const Icon(Icons.chevron_right_rounded),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// "n" → "danh từ" / "noun" theo ngôn ngữ app.
String posLabel(BuildContext context, String pos) {
  final l10n = context.l10n;
  return switch (pos) {
    'n' => l10n.pos_n,
    'v' => l10n.pos_v,
    'adj' => l10n.pos_adj,
    'adv' => l10n.pos_adv,
    'num' => l10n.pos_num,
    'prep' => l10n.pos_prep,
    'pron' => l10n.pos_pron,
    'na' => l10n.pos_na,
    'exp' => l10n.pos_exp,
    _ => pos,
  };
}
