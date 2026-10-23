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
import 'package:lingua/shared/base/speak_button.dart';
import 'package:lingua/shared/states/async_view.dart';

/// Từ vựng của 1 chủ đề: từ + phiên âm + nghĩa, 🔊 nghe, bấm → chi tiết.
@RoutePage()
class VocabListPage extends ConsumerWidget {
  const VocabListPage({required this.course, required this.topicId, super.key});

  final Course course;

  final String topicId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(localeProvider).languageCode;
    final state = ref.watch(vocabTopicsProvider(course));
    final topic = state.value?.firstWhere((t) => t.id == topicId);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          topic == null ? '' : '${topic.emoji} ${topic.name(language)}',
        ),
      ),
      body: AsyncView<List<Topic<Word>>>(
        state: state,
        onRetry: () => ref.invalidate(vocabTopicsProvider(course)),
        builder: (context, _) {
          final words = topic!.items;
          final learned = learnedCount(ref, words.map((w) => w.key));
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              RoundedProgress(
                learned / words.length,
                color: Module.lesson(course, LessonKind.vocabulary)!.color,
              ),
              const SizedBox(height: 6),
              Text(
                context.l10n.learn_progress(learned, words.length),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              for (final w in words)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    child: ListTile(
                      onTap: () => context.router.push(
                        WordDetailRoute(
                          course: course,
                          topicId: topicId,
                          word: w.word,
                        ),
                      ),
                      contentPadding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                      leading: LearnedToggle(w.key),
                      title: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: w.word,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            if (w.readingLabel case final reading?)
                              TextSpan(
                                text: '  $reading',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                          ],
                        ),
                      ),
                      subtitle: Text(w.meaning),
                      trailing: SpeakButton(
                        w.word,
                        language: w.course.speechLanguage,
                      ),
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
