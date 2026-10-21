import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingua/features/japanese/models/kanji_model.dart';
import 'package:lingua/features/japanese/providers/kanji_provider.dart';
import 'package:lingua/features/japanese/providers/kanji_quiz_notifier.dart';
import 'package:lingua/features/japanese/widgets/quiz_board.dart';
import 'package:lingua/routes/app_router.dart';
import 'package:lingua/shared/base/app_scaffold.dart';
import 'package:lingua/shared/states/async_view.dart';

/// Luyện Kanji: hiện 1 chữ ngẫu nhiên → chọn âm Hán Việt / nghĩa đúng (A/B/C/D).
@RoutePage()
class KanjiQuizPage extends HookConsumerWidget {
  const KanjiQuizPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final level = useState(JlptLevel.n5);
    final mode = useState(KanjiQuizMode.hanViet);
    final list = ref.watch(kanjiListProvider);
    final provider = kanjiQuizProvider(level.value, mode.value);
    // Quiz cần danh sách Kanji → chỉ tạo khi đã tải xong.
    final quiz = list.hasValue ? ref.watch(provider) : null;
    final answer = mode.value.answerOf;

    return AppScaffold(
      appBar: AppBar(
        title: const Text('Luyện Kanji'),
        actions: [if (quiz != null) QuizScore(quiz)],
      ),
      body: AsyncView<List<Kanji>>(
        state: list,
        onRetry: () => ref.invalidate(kanjiListProvider),
        builder: (context, _) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Đổi cấp / kiểu hỏi = bắt đầu phiên mới (điểm về 0).
              SegmentedButton<JlptLevel>(
                segments: [
                  for (final l in JlptLevel.values)
                    ButtonSegment(value: l, label: Text(l.label)),
                ],
                selected: {level.value},
                onSelectionChanged: (s) => level.value = s.first,
              ),
              const SizedBox(height: 8),
              SegmentedButton<KanjiQuizMode>(
                segments: [
                  for (final m in KanjiQuizMode.values)
                    ButtonSegment(value: m, label: Text(m.label)),
                ],
                selected: {mode.value},
                onSelectionChanged: (s) => mode.value = s.first,
              ),
              Expanded(
                child: QuizBoard<Kanji>(
                  quiz: quiz!,
                  prompt: quiz.question.char,
                  ask: mode.value == KanjiQuizMode.hanViet
                      ? 'Âm Hán Việt của chữ này?'
                      : 'Chữ này nghĩa là gì?',
                  optionLabel: answer,
                  answerText: (q) => '${q.char} là "${answer(q)}"',
                  onAnswer: ref.read(provider.notifier).answer,
                  onNext: ref.read(provider.notifier).next,
                  onDetail: (q) =>
                      context.router.push(KanjiDetailRoute(kanji: q)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
