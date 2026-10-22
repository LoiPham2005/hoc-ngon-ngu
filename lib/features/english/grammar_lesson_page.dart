import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingua/design/l10n/l10n_extensions.dart';
import 'package:lingua/design/l10n/locale_notifier.dart';
import 'package:lingua/design/theme/app_colors.dart';
import 'package:lingua/features/english/models/english_model.dart';
import 'package:lingua/features/english/providers/english_provider.dart';
import 'package:lingua/features/english/widgets/english_widgets.dart';
import 'package:lingua/routes/app_router.dart';
import 'package:lingua/shared/base/app_ui.dart';
import 'package:lingua/shared/base/speak_button.dart';
import 'package:lingua/shared/states/async_view.dart';

/// 1 bài ngữ pháp: tóm tắt → công thức → ghi nhớ → ví dụ (🔊) → nút làm bài tập.
@RoutePage()
class GrammarLessonPage extends ConsumerWidget {
  const GrammarLessonPage({required this.lessonId, super.key});

  final String lessonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(localeProvider).languageCode;
    final state = ref.watch(grammarLessonsProvider);
    final lesson = state.value?.firstWhere((g) => g.id == lessonId);
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = context.colors;
    return Scaffold(
      appBar: AppBar(
        title: Text(lesson?.name(language) ?? ''),
        actions: [if (lesson != null) LearnedToggle(lesson.key)],
      ),
      body: AsyncView<List<GrammarLesson>>(
        state: state,
        onRetry: () => ref.invalidate(grammarLessonsProvider),
        builder: (context, _) {
          final g = lesson!;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              Row(
                children: [
                  Text(g.emoji, style: const TextStyle(fontSize: 32)),
                  const SizedBox(width: 10),
                  Tag(g.level),
                ],
              ),
              const SizedBox(height: 8),
              Text(g.summary, style: theme.textTheme.bodyLarge),
              const SizedBox(height: 20),
              SectionTitle(l10n.grammar_formulas),
              for (final f in g.formulas)
                Card(
                  color: colors.primarySoft,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(f.label, style: theme.textTheme.labelMedium),
                        const SizedBox(height: 2),
                        Text(
                          f.pattern,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              SectionTitle(l10n.grammar_points),
              for (final p in g.points)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('•  ', style: theme.textTheme.bodyLarge),
                      Expanded(
                        child: Text(p, style: theme.textTheme.bodyMedium),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              SectionTitle(l10n.grammar_examples),
              for (final e in g.examples)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(e.en, style: theme.textTheme.titleMedium),
                              Text(
                                e.vi,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SpeakButton(e.en, language: 'en-US'),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      bottomNavigationBar: lesson == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: FilledButton.icon(
                  onPressed: () => context.router.push(
                    GrammarPracticeRoute(lessonId: lesson.id),
                  ),
                  icon: const Icon(Icons.edit_note_rounded),
                  label: Text(l10n.grammar_start(lesson.exercises.length)),
                ),
              ),
            ),
    );
  }
}
