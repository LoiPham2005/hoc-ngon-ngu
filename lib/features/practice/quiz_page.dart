import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingua/design/l10n/l10n_extensions.dart';
import 'package:lingua/design/theme/app_colors.dart';
import 'package:lingua/features/japanese/models/kana_model.dart';
import 'package:lingua/features/japanese/models/kanji_model.dart';
import 'package:lingua/features/japanese/providers/kanji_provider.dart';
import 'package:lingua/features/practice/providers/quiz_session_notifier.dart';
import 'package:lingua/features/practice/widgets/quiz_result_view.dart';
import 'package:lingua/routes/app_router.dart';
import 'package:lingua/shared/base/app_ui.dart';
import 'package:lingua/shared/base/speak_button.dart';
import 'package:lingua/shared/dialogs/app_confirmation_dialog.dart';
import 'package:lingua/shared/states/async_view.dart';

/// Làm 1 bài luyện 10 câu → màn kết quả.
@RoutePage()
class QuizPage extends ConsumerWidget {
  const QuizPage({required this.topic, super.key});

  final QuizTopic topic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Bài Kanji cần dữ liệu Kanji → chờ tải xong mới tạo bài.
    final data = ref.watch(kanjiListProvider);
    if (!data.hasValue) {
      return Scaffold(
        appBar: AppBar(),
        body: AsyncView<List<Kanji>>(
          state: data,
          onRetry: () => ref.invalidate(kanjiListProvider),
          builder: (_, _) => const SizedBox.shrink(),
        ),
      );
    }
    final provider = quizSessionProvider(topic);
    final session = ref.watch(provider);
    final notifier = ref.read(provider.notifier);

    if (session.isFinished) {
      return QuizResultView(
        session: session,
        onRetry: notifier.restart,
        onDone: () => context.router.maybePop(),
        onOpen: (item) => openQuizItem(context, item),
      );
    }

    return PopScope(
      canPop: session.picks.isEmpty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        // Đã xác nhận → pop thẳng (maybePop sẽ hỏi lại PopScope → bị chặn lần nữa).
        if (await _confirmExit(context) && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          titleSpacing: 0,
          title: Padding(
            padding: const EdgeInsets.only(right: 20),
            child: RoundedProgress(
              (session.index + (session.isAnswered ? 1 : 0)) /
                  session.questions.length,
              height: 10,
            ),
          ),
        ),
        body: SafeArea(
          child: _QuestionView(
            session: session,
            notifier: notifier,
            topic: topic,
          ),
        ),
      ),
    );
  }

  Future<bool> _confirmExit(BuildContext context) => AppConfirmationDialog.show(
    context,
    title: context.l10n.quiz_exitTitle,
    message: context.l10n.quiz_exitMessage,
    confirmText: context.l10n.quiz_exit,
    destructive: true,
  );
}

/// Mở màn chi tiết của chữ trong bài (từ câu vừa làm / danh sách câu sai).
void openQuizItem(BuildContext context, QuizItem item) {
  final script = KanaScript.values.asNameMap()[item.group];
  if (script != null) {
    context.router.push(KanaDetailRoute(script: script, char: item.char));
    return;
  }
  final level = JlptLevel.values.firstWhere(
    (l) => item.group.toLowerCase().endsWith(l.name),
  );
  context.router.push(KanjiDetailRoute(level: level, char: item.char));
}

class _QuestionView extends StatelessWidget {
  const _QuestionView({
    required this.session,
    required this.notifier,
    required this.topic,
  });

  final QuizSession session;
  final QuizSessionNotifier notifier;
  final QuizTopic topic;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final theme = Theme.of(context);
    final question = session.current;
    final ask = switch (topic.mode) {
      QuizMode.reading => l10n.quiz_askReading,
      QuizMode.hanViet => l10n.quiz_askHanViet,
      QuizMode.meaning => l10n.quiz_askMeaning,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
          child: Text(
            l10n.quiz_progress(session.index + 1, session.questions.length),
            style: theme.textTheme.labelLarge?.copyWith(
              color: colors.textMuted,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
          child: Text(ask, style: theme.textTheme.titleLarge),
        ),
        Expanded(
          child: Center(
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: colors.border),
              ),
              child: FittedBox(
                child: Text(
                  question.item.char,
                  style: const TextStyle(fontSize: 110, height: 1.15),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              for (final (i, option) in question.options.indexed)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _OptionButton(
                    letter: 'ABCD'[i],
                    label: option.answer,
                    state: !session.isAnswered
                        ? _OptionState.idle
                        : option == question.item
                        ? _OptionState.correct
                        : option == session.picked
                        ? _OptionState.wrong
                        : _OptionState.dimmed,
                    onTap: () => notifier.answer(option),
                  ),
                ),
            ],
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: session.isAnswered
              ? _Feedback(session: session, notifier: notifier)
              : const SizedBox(height: 10, width: double.infinity),
        ),
      ],
    );
  }
}

enum _OptionState { idle, correct, wrong, dimmed }

class _OptionButton extends StatelessWidget {
  const _OptionButton({
    required this.letter,
    required this.label,
    required this.state,
    required this.onTap,
  });

  final String letter;
  final String label;
  final _OptionState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (background, border, accent) = switch (state) {
      _OptionState.correct => (
        colors.successSoft,
        colors.success,
        colors.success,
      ),
      _OptionState.wrong => (colors.errorSoft, colors.error, colors.error),
      _ => (colors.surface, colors.border, colors.textMuted),
    };
    return Opacity(
      opacity: state == _OptionState.dimmed ? 0.5 : 1,
      child: Material(
        color: background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: border,
            width: state == _OptionState.idle ? 1.5 : 2,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: state == _OptionState.idle ? onTap : null,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 54),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: accent),
                    ),
                    child: Text(
                      letter,
                      style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  if (state == _OptionState.correct)
                    Icon(Icons.check_circle_rounded, color: colors.success)
                  else if (state == _OptionState.wrong)
                    Icon(Icons.cancel_rounded, color: colors.error),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Thanh dưới sau khi trả lời: đúng/sai + đáp án + nút tiếp.
class _Feedback extends StatelessWidget {
  const _Feedback({required this.session, required this.notifier});

  final QuizSession session;
  final QuizSessionNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final theme = Theme.of(context);
    final ok = session.picked == session.current.item;
    final color = ok ? colors.success : colors.error;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
      color: ok ? colors.successSoft : colors.errorSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                ok ? Icons.check_circle_rounded : Icons.error_rounded,
                color: color,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  ok ? l10n.quiz_correct : l10n.quiz_wrong,
                  style: theme.textTheme.titleMedium?.copyWith(color: color),
                ),
              ),
              TextButton(
                onPressed: () => openQuizItem(context, session.current.item),
                child: Text(l10n.quiz_viewDetail),
              ),
              // Chỉ cho nghe SAU khi trả lời — nghe trước là lộ đáp án.
              SpeakButton(session.current.item.speech),
            ],
          ),
          if (!ok)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                l10n.quiz_answerIs(
                  '${session.current.item.char} · ${session.current.item.answer}',
                ),
                style: theme.textTheme.bodyMedium,
              ),
            ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: notifier.next,
            style: FilledButton.styleFrom(backgroundColor: color),
            child: Text(
              session.isLast ? l10n.quiz_seeResult : l10n.quiz_continue,
            ),
          ),
        ],
      ),
    );
  }
}
