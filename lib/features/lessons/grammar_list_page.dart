import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingua/design/l10n/l10n_extensions.dart';
import 'package:lingua/design/l10n/locale_notifier.dart';
import 'package:lingua/design/theme/app_colors.dart';
import 'package:lingua/features/course/models/course_model.dart';
import 'package:lingua/features/lessons/models/lesson_model.dart';
import 'package:lingua/features/lessons/providers/lesson_provider.dart';
import 'package:lingua/features/lessons/widgets/lesson_widgets.dart';
import 'package:lingua/modules/ads/ad_config.dart';
import 'package:lingua/modules/ads/widgets/native_ad_list.dart';
import 'package:lingua/routes/app_router.dart';
import 'package:lingua/shared/base/app_ui.dart';
import 'package:lingua/shared/states/async_view.dart';

/// Danh sách bài ngữ pháp theo thứ tự học, kèm cấp độ và dấu ✓ đã thuộc.
@RoutePage()
class GrammarListPage extends ConsumerWidget {
  const GrammarListPage({required this.course, super.key});

  final Course course;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(localeProvider).languageCode;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(Module.lesson(course, LessonKind.grammar)!.title(context)),
      ),
      body: AsyncView<List<GrammarLesson>>(
        state: ref.watch(grammarLessonsProvider(course)),
        onRetry: () => ref.invalidate(grammarLessonsProvider(course)),
        builder: (context, lessons) {
          final learned = learnedCount(ref, lessons.map((g) => g.key));
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              RoundedProgress(
                learned / lessons.length,
                color: Module.lesson(course, LessonKind.grammar)!.color,
              ),
              const SizedBox(height: 6),
              Text(
                context.l10n.learn_progress(learned, lessons.length),
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              ...withNativeAds([
                for (final (i, g) in lessons.indexed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      child: ListTile(
                        onTap: () => context.router.push(
                          GrammarLessonRoute(course: course, lessonId: g.id),
                        ),
                        contentPadding: const EdgeInsets.fromLTRB(14, 6, 4, 6),
                        leading: Text(
                          g.emoji,
                          style: const TextStyle(fontSize: 28),
                        ),
                        title: Text(
                          '${i + 1}. ${g.name(language)}',
                          style: theme.textTheme.titleMedium,
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              Tag(g.level),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  g.summary,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: context.colors.textMuted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        trailing: LearnedToggle(g.key),
                      ),
                    ),
                  ),
              ], NativePlacement.list),
            ],
          );
        },
      ),
    );
  }
}
