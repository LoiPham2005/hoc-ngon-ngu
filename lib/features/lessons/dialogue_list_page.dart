import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingua/design/l10n/l10n_extensions.dart';
import 'package:lingua/design/l10n/locale_notifier.dart';
import 'package:lingua/features/course/models/course_model.dart';
import 'package:lingua/features/lessons/models/lesson_model.dart';
import 'package:lingua/features/lessons/providers/lesson_provider.dart';
import 'package:lingua/features/lessons/widgets/lesson_widgets.dart';
import 'package:lingua/routes/app_router.dart';
import 'package:lingua/shared/base/app_ui.dart';
import 'package:lingua/shared/states/async_view.dart';

/// Danh sách hội thoại theo tình huống, kèm cấp độ và dấu ✓ đã hiểu bài.
@RoutePage()
class DialogueListPage extends ConsumerWidget {
  const DialogueListPage({required this.course, super.key});

  final Course course;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(localeProvider).languageCode;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          Module.lesson(course, LessonKind.dialogues)!.title(context),
        ),
      ),
      body: AsyncView<List<Dialogue>>(
        state: ref.watch(dialoguesProvider(course)),
        onRetry: () => ref.invalidate(dialoguesProvider(course)),
        builder: (context, dialogues) {
          final learned = learnedCount(ref, dialogues.map((d) => d.key));
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              RoundedProgress(
                learned / dialogues.length,
                color: Module.lesson(course, LessonKind.dialogues)!.color,
              ),
              const SizedBox(height: 6),
              Text(
                context.l10n.learn_progress(learned, dialogues.length),
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              for (final d in dialogues)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    child: ListTile(
                      onTap: () => context.router.push(
                        DialogueRoute(course: course, dialogueId: d.id),
                      ),
                      contentPadding: const EdgeInsets.fromLTRB(14, 6, 4, 6),
                      leading: Text(
                        d.emoji,
                        style: const TextStyle(fontSize: 28),
                      ),
                      title: Text(
                        d.name(language),
                        style: theme.textTheme.titleMedium,
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Tag(d.level),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                d.speakers.values.join(' · '),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                      trailing: LearnedToggle(d.key),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
