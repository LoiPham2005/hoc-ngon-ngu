import 'package:flutter/material.dart';
import 'package:lingua/design/l10n/l10n_extensions.dart';
import 'package:lingua/design/theme/app_colors.dart';
import 'package:lingua/features/practice/providers/quiz_session_notifier.dart';
import 'package:lingua/shared/base/app_ui.dart';

/// Kết quả bài luyện: vòng điểm, lời khen theo %, câu sai cần ôn, Làm lại / Xong.
class QuizResultView extends StatelessWidget {
  const QuizResultView({
    required this.session,
    required this.onRetry,
    required this.onDone,
    required this.onOpen,
    this.retryLabel,
    super.key,
  });

  final QuizSession session;

  /// `null` = ẩn nút làm lại (vd ôn tập đã hết mục tới hạn).
  final VoidCallback? onRetry;

  /// Chữ trên nút làm lại (mặc định "Làm lại").
  final String? retryLabel;
  final VoidCallback onDone;
  final void Function(QuizItem item) onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final theme = Theme.of(context);
    final total = session.questions.length;
    final correct = session.correctCount;
    final ratio = correct / total;
    final (emoji, message, color) = ratio >= 0.9
        ? ('🏆', l10n.result_great, colors.success)
        : ratio >= 0.6
        ? ('👏', l10n.result_good, colors.primary)
        : ('💪', l10n.result_keepGoing, colors.warning);
    final mistakes = session.mistakes;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
                children: [
                  Center(
                    child: SizedBox.square(
                      dimension: 160,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CircularProgressIndicator(
                            value: ratio,
                            strokeWidth: 12,
                            strokeCap: StrokeCap.round,
                            color: color,
                          ),
                          Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  emoji,
                                  style: const TextStyle(fontSize: 36),
                                ),
                                Text(
                                  '${(ratio * 100).round()}%',
                                  style: theme.textTheme.headlineMedium,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
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
                  const SizedBox(height: 28),
                  if (mistakes.isEmpty)
                    Text(
                      l10n.result_perfect,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium,
                    )
                  else ...[
                    SectionTitle(l10n.result_mistakes),
                    for (final item in mistakes)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Card(
                          clipBehavior: Clip.antiAlias,
                          child: ListTile(
                            onTap: () => onOpen(item),
                            // Chữ ngắn (Kana/Kanji) → ô chữ; từ / câu dài → dòng chữ.
                            leading: item.char.length <= 3
                                ? GlyphBadge(
                                    item.char,
                                    color: colors.error,
                                    size: 42,
                                  )
                                : Icon(
                                    Icons.close_rounded,
                                    color: colors.error,
                                  ),
                            title: Text(
                              item.char.length <= 3 ? item.answer : item.char,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: item.char.length <= 3
                                ? null
                                : Text(item.answer),
                            trailing: const Icon(Icons.chevron_right_rounded),
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Row(
                children: [
                  if (onRetry != null) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onRetry,
                        child: Text(retryLabel ?? l10n.result_retry),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: FilledButton(
                      onPressed: onDone,
                      child: Text(l10n.result_done),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
