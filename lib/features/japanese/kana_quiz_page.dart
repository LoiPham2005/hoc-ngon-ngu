import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingua/features/japanese/models/kana_model.dart';
import 'package:lingua/features/japanese/providers/kana_quiz_notifier.dart';
import 'package:lingua/features/japanese/widgets/quiz_board.dart';
import 'package:lingua/routes/app_router.dart';
import 'package:lingua/shared/base/app_scaffold.dart';

/// Luyện Kana: hiện 1 chữ ngẫu nhiên → chọn cách đọc đúng (A/B/C/D).
@RoutePage()
class KanaQuizPage extends HookConsumerWidget {
  const KanaQuizPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scope = useState(QuizScope.hiragana);
    final dakuten = useState(false);
    final provider = kanaQuizProvider(scope.value, withDakuten: dakuten.value);
    final quiz = ref.watch(provider);
    final notifier = ref.read(provider.notifier);

    return AppScaffold(
      appBar: AppBar(
        title: const Text('Luyện Kana'),
        actions: [QuizScore(quiz)],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Đổi bảng / âm đục = bắt đầu phiên mới (điểm về 0).
            SegmentedButton<QuizScope>(
              segments: [
                for (final s in QuizScope.values)
                  ButtonSegment(value: s, label: Text(s.label)),
              ],
              selected: {scope.value},
              onSelectionChanged: (s) => scope.value = s.first,
            ),
            const SizedBox(height: 8),
            Align(
              child: FilterChip(
                label: const Text('Gồm âm đục (が, ぱ…)'),
                selected: dakuten.value,
                onSelected: (v) => dakuten.value = v,
              ),
            ),
            Expanded(
              child: QuizBoard<Kana>(
                quiz: quiz,
                prompt: quiz.question.char,
                ask: 'Chữ này đọc là gì?',
                optionLabel: (k) => k.romaji,
                answerText: (q) => '${q.char} đọc là "${q.romaji}"',
                onAnswer: notifier.answer,
                onNext: notifier.next,
                onDetail: (q) => context.router.push(KanaDetailRoute(kana: q)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
