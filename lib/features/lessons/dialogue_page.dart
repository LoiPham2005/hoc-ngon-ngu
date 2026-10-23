import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingua/core/services/speech_service.dart';
import 'package:lingua/design/l10n/l10n_extensions.dart';
import 'package:lingua/design/l10n/locale_notifier.dart';
import 'package:lingua/design/theme/app_colors.dart';
import 'package:lingua/features/course/models/course_model.dart';
import 'package:lingua/features/lessons/models/lesson_model.dart';
import 'package:lingua/features/lessons/providers/lesson_provider.dart';
import 'package:lingua/features/lessons/widgets/exercise_quiz.dart';
import 'package:lingua/features/lessons/widgets/lesson_widgets.dart';
import 'package:lingua/routes/app_router.dart';
import 'package:lingua/shared/states/async_view.dart';

/// Giọng người nói B cao hơn A để nghe ra 2 người.
const _pitch = {'A': 1.0, 'B': 1.3};

/// 1 đoạn hội thoại dạng tin nhắn: nghe cả bài (đọc nối từng lượt, tô sáng lượt đang đọc),
/// bấm 1 lượt để nghe riêng, bật/tắt bản dịch, rồi làm câu hỏi hiểu bài.
@RoutePage()
class DialoguePage extends HookConsumerWidget {
  const DialoguePage({
    required this.course,
    required this.dialogueId,
    super.key,
  });

  final Course course;

  final String dialogueId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(localeProvider).languageCode;
    final state = ref.watch(dialoguesProvider(course));
    final dialogue = state.value?.where((d) => d.id == dialogueId).firstOrNull;
    final l10n = context.l10n;
    final speech = ref.read(speechProvider);
    // Lượt đang đọc (null = không đọc); mỗi lần bấm nghe tăng [run] để huỷ lượt đọc cũ.
    final playing = useState<int?>(null);
    final run = useRef(0);
    final showTranslation = useState(true);
    final mounted = useIsMounted();

    useEffect(() => speech.stop, const []);

    Future<void> play(Dialogue d, {int from = 0, bool single = false}) async {
      final id = ++run.value;
      for (var i = from; i < d.lines.length; i++) {
        if (!mounted() || run.value != id) return;
        playing.value = i;
        final line = d.lines[i];
        final ok = await speech.speakAndWait(
          line.sentence.text,
          language: course.speechLanguage,
          pitch: _pitch[line.speaker] ?? 1,
        );
        if (!ok || single) break;
      }
      if (mounted() && run.value == id) playing.value = null;
    }

    Future<void> stop() async {
      run.value++;
      playing.value = null;
      await speech.stop();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(dialogue?.name(language) ?? ''),
        actions: [if (dialogue != null) LearnedToggle(dialogue.key)],
      ),
      body: AsyncView<List<Dialogue>>(
        state: state,
        onRetry: () => ref.invalidate(dialoguesProvider(course)),
        builder: (context, _) {
          final d = dialogue!;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              Row(
                children: [
                  Text(d.emoji, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 8),
                  Tag(d.level),
                  const Spacer(),
                  FilterChip(
                    label: Text(l10n.dialogue_translation),
                    selected: showTranslation.value,
                    onSelected: (v) => showTranslation.value = v,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (playing.value == null)
                FilledButton.icon(
                  onPressed: () => play(d),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(l10n.dialogue_playAll),
                )
              else
                FilledButton.tonalIcon(
                  onPressed: stop,
                  icon: const Icon(Icons.stop_rounded),
                  label: Text(l10n.dialogue_stop),
                ),
              const SizedBox(height: 16),
              for (final (i, line) in d.lines.indexed)
                _Bubble(
                  name: d.speakers[line.speaker] ?? line.speaker,
                  text: line.sentence.text,
                  // Bật "Bản dịch" → hiện cả cách đọc kana (Tiếng Nhật) + nghĩa.
                  reading: showTranslation.value ? line.sentence.reading : null,
                  vi: showTranslation.value ? line.sentence.vi : null,
                  right: line.speaker == 'B',
                  active: playing.value == i,
                  onTap: () => play(d, from: i, single: true),
                ),
            ],
          );
        },
      ),
      bottomNavigationBar: dialogue == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: FilledButton.icon(
                  onPressed: () {
                    stop();
                    context.router.push(
                      DialogueQuizRoute(
                        course: course,
                        dialogueId: dialogue.id,
                      ),
                    );
                  },
                  icon: const Icon(Icons.quiz_rounded),
                  label: Text(l10n.dialogue_quiz(dialogue.questions.length)),
                ),
              ),
            ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.name,
    required this.text,
    required this.reading,
    required this.vi,
    required this.right,
    required this.active,
    required this.onTap,
  });

  final String name;
  final String text;
  final String? reading;
  final String? vi;

  /// Người nói B → bóng bên phải.
  final bool right;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: Radius.circular(right ? 18 : 4),
      bottomRight: Radius.circular(right ? 4 : 18),
    );
    return Align(
      alignment: right ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.8,
          ),
          child: Column(
            crossAxisAlignment: right
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(name, style: theme.textTheme.labelSmall),
              ),
              const SizedBox(height: 2),
              Material(
                color: right ? colors.primarySoft : colors.surfaceAlt,
                shape: RoundedRectangleBorder(
                  borderRadius: radius,
                  side: BorderSide(
                    color: active ? colors.primary : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: InkWell(
                  onTap: onTap,
                  borderRadius: radius,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                    child: SentenceText(
                      text,
                      reading: reading,
                      meaning: vi,
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Câu hỏi hiểu bài của 1 hội thoại; đúng từ 70% → đánh dấu đã hiểu bài.
@RoutePage()
class DialogueQuizPage extends HookConsumerWidget {
  const DialogueQuizPage({
    required this.course,
    required this.dialogueId,
    super.key,
  });

  final Course course;

  final String dialogueId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(localeProvider).languageCode;
    final state = ref.watch(dialoguesProvider(course));
    final dialogue = state.value?.where((d) => d.id == dialogueId).firstOrNull;
    final round = useState(0);
    if (dialogue == null) {
      return Scaffold(
        appBar: AppBar(),
        body: AsyncView<List<Dialogue>>(
          state: state,
          onRetry: () => ref.invalidate(dialoguesProvider(course)),
          builder: (_, _) => const SizedBox.shrink(),
        ),
      );
    }
    return ExerciseQuiz(
      key: ValueKey(round.value),
      title: dialogue.name(language),
      exercises: dialogue.questions,
      learnedKey: dialogue.key,
      color: Module.lesson(course, LessonKind.dialogues)!.color,
      onRetry: () => round.value++,
      language: course.speechLanguage,
    );
  }
}
