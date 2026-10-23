import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingua/design/l10n/l10n_extensions.dart';
import 'package:lingua/design/l10n/locale_notifier.dart';
import 'package:lingua/features/course/models/course_model.dart';
import 'package:lingua/features/lessons/models/lesson_model.dart';
import 'package:lingua/features/lessons/providers/lesson_provider.dart';
import 'package:lingua/features/lessons/widgets/exercise_quiz.dart';
import 'package:lingua/shared/states/async_view.dart';

/// Bài tập ngữ pháp: trắc nghiệm điền chỗ trống + ghép câu.
/// [lessonId] = null → trộn 10 câu từ mọi bài (không đánh dấu bài nào).
@RoutePage()
class GrammarPracticePage extends HookConsumerWidget {
  const GrammarPracticePage({required this.course, this.lessonId, super.key});

  final Course course;

  final String? lessonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(localeProvider).languageCode;
    final state = ref.watch(grammarLessonsProvider(course));
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
          onRetry: () => ref.invalidate(grammarLessonsProvider(course)),
          builder: (_, _) => const SizedBox.shrink(),
        ),
      );
    }
    return ExerciseQuiz(
      key: ValueKey(round.value),
      title: lesson?.name(language) ?? context.l10n.practice_grammar,
      exercises: exercises,
      learnedKey: lesson?.key,
      color: Module.lesson(course, LessonKind.grammar)!.color,
      onRetry: () => round.value++,
      language: course.speechLanguage,
    );
  }
}
