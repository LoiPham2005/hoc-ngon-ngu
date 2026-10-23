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

/// Ghép câu giao tiếp: 10 câu của 1 tình huống ([topicId] = null → trộn), xếp các từ đã xáo.
/// Tiếng Nhật ghép theo cụm kana (câu viết liền không có dấu cách).
@RoutePage()
class PhraseOrderPage extends HookConsumerWidget {
  const PhraseOrderPage({required this.course, this.topicId, super.key});

  final Course course;
  final String? topicId;

  /// Câu đủ dài để ghép (3–9 cụm) → bài ghép câu; câu quá ngắn / dài bị bỏ.
  static OrderExercise? exerciseOf(Phrase p) {
    final answer = (p.reading ?? p.text).trim().replaceAll(RegExp(r'\s+'), ' ');
    final exercise = OrderExercise(answer: answer, meaning: p.meaning);
    final n = exercise.words.length;
    return n >= 3 && n <= 9 ? exercise : null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(localeProvider).languageCode;
    final state = ref.watch(phraseTopicsProvider(course));
    final topics = state.value;
    final topic = topics?.where((t) => t.id == topicId).firstOrNull;
    final round = useState(0);
    final exercises = useMemoized(
      () => topics == null
          ? const <Exercise>[]
          : ([
              for (final t in topic == null ? topics : [topic])
                for (final p in t.items) ?exerciseOf(p),
            ]..shuffle()).take(10).toList(),
      [topics, round.value],
    );
    final title = context.l10n.practice_phraseOrder;
    if (topics == null) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: AsyncView<List<Topic<Phrase>>>(
          state: state,
          onRetry: () => ref.invalidate(phraseTopicsProvider(course)),
          builder: (_, _) => const SizedBox.shrink(),
        ),
      );
    }
    return ExerciseQuiz(
      key: ValueKey(round.value),
      title: topic == null ? title : '$title · ${topic.name(language)}',
      exercises: exercises,
      learnedKey: null,
      color: Module.lesson(course, LessonKind.phrases)!.color,
      onRetry: () => round.value++,
      language: course.speechLanguage,
    );
  }
}
