import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingua/design/l10n/l10n_extensions.dart';
import 'package:lingua/design/theme/app_colors.dart';
import 'package:lingua/features/course/providers/learner_notifier.dart';
import 'package:lingua/shared/base/speak_button.dart';

/// Số mục đã thuộc trong [keys].
int learnedCount(WidgetRef ref, Iterable<String> keys) {
  final learned = ref.watch(learnerProvider.select((l) => l.learned));
  return keys.where(learned.contains).length;
}

/// Nút ✓ bật/tắt "đã thuộc" cho 1 mục (từ, câu, âm).
class LearnedToggle extends ConsumerWidget {
  const LearnedToggle(this.learnedKey, {super.key});

  final String learnedKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final learned = ref.watch(
      learnerProvider.select((l) => l.learned.contains(learnedKey)),
    );
    final colors = context.colors;
    return IconButton(
      onPressed: () =>
          ref.read(learnerProvider.notifier).toggleLearned(learnedKey),
      icon: Icon(
        learned ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
        color: learned ? colors.success : colors.border,
      ),
    );
  }
}

/// Nhãn nhỏ bo tròn (loại từ, cấp…).
class Tag extends StatelessWidget {
  const Tag(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: context.colors.primarySoft,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.labelSmall?.copyWith(color: context.colors.primary),
    ),
  );
}

/// Khung kết quả 1 câu: "Chính xác! / Chưa đúng" + giải thích / câu đúng, 🔊 nghe câu.
class AnswerFeedback extends StatelessWidget {
  const AnswerFeedback({
    required this.ok,
    this.detail,
    this.speech,
    this.title,
    super.key,
  });

  final bool ok;
  final String? detail;
  final String? speech;

  /// Thay dòng "Chính xác! / Chưa đúng" (vd điểm phát âm).
  final String? title;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final color = ok ? colors.success : colors.error;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      decoration: BoxDecoration(
        color: ok ? colors.successSoft : colors.errorSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title ??
                      (ok
                          ? context.l10n.quiz_correct
                          : context.l10n.quiz_wrong),
                  style: theme.textTheme.titleMedium?.copyWith(color: color),
                ),
                if (detail != null) ...[
                  const SizedBox(height: 2),
                  Text(detail!, style: theme.textTheme.bodyMedium),
                ],
              ],
            ),
          ),
          if (speech != null) SpeakButton(speech!, language: 'en-US'),
        ],
      ),
    );
  }
}

/// Màn kết quả bài luyện tiếng Anh (ngữ pháp, nghe – chép, luyện nói, hội thoại).
/// [note] = dòng thêm (vd "Đã thuộc bài này ✓") + tô xanh (true) hay cam (false).
class PracticeResult extends StatelessWidget {
  const PracticeResult({
    required this.correct,
    required this.total,
    required this.onRetry,
    this.note,
    super.key,
  });

  final int correct;
  final int total;
  final VoidCallback onRetry;
  final (String, bool)? note;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = context.colors;
    final ratio = total == 0 ? 0 : correct / total;
    final (emoji, message) = ratio >= 0.9
        ? ('🏆', l10n.result_great)
        : ratio >= 0.6
        ? ('👏', l10n.result_good)
        : ('💪', l10n.result_keepGoing);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Text(
                emoji,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 64),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              Text(
                l10n.result_score(correct, total),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colors.textMuted,
                ),
              ),
              if (note case (final text, final good)) ...[
                const SizedBox(height: 16),
                Text(
                  text,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: good ? colors.success : colors.warning,
                  ),
                ),
              ],
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onRetry,
                      child: Text(l10n.result_retry),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => context.router.maybePop(),
                      child: Text(l10n.result_done),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Câu mẫu tô màu theo từng từ: xanh = đã khớp, đỏ gạch chân = thiếu / sai.
class WordMatchText extends StatelessWidget {
  const WordMatchText(this.words, {this.style, super.key});

  final List<({String word, bool hit})> words;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Text.rich(
      TextSpan(
        children: [
          for (final (i, w) in words.indexed)
            TextSpan(
              text: i == 0 ? w.word : ' ${w.word}',
              style: TextStyle(
                color: w.hit ? colors.success : colors.error,
                decoration: w.hit ? null : TextDecoration.underline,
                decorationColor: colors.error,
              ),
            ),
        ],
      ),
      style: style ?? Theme.of(context).textTheme.titleLarge,
    );
  }
}
