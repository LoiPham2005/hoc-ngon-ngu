import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingua/design/l10n/l10n_extensions.dart';
import 'package:lingua/design/l10n/locale_notifier.dart';
import 'package:lingua/design/theme/app_colors.dart';
import 'package:lingua/features/course/models/course_model.dart';
import 'package:lingua/features/english/models/english_model.dart';
import 'package:lingua/features/english/providers/english_provider.dart';
import 'package:lingua/features/english/widgets/english_widgets.dart';
import 'package:lingua/shared/base/app_ui.dart';
import 'package:lingua/shared/base/speak_button.dart';
import 'package:lingua/shared/states/async_view.dart';

/// Câu giao tiếp của 1 tình huống: câu tiếng Anh + nghĩa + ghi chú, 🔊 nghe, ✓ đã thuộc.
@RoutePage()
class PhraseListPage extends ConsumerWidget {
  const PhraseListPage({required this.topicId, super.key});

  final String topicId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(localeProvider).languageCode;
    final state = ref.watch(phraseTopicsProvider);
    final topic = state.value?.firstWhere((t) => t.id == topicId);
    final theme = Theme.of(context);
    final colors = context.colors;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          topic == null ? '' : '${topic.emoji} ${topic.name(language)}',
        ),
      ),
      body: AsyncView<List<Topic<Phrase>>>(
        state: state,
        onRetry: () => ref.invalidate(phraseTopicsProvider),
        builder: (context, _) {
          final phrases = topic!.items;
          final learned = learnedCount(ref, phrases.map((p) => p.key));
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              RoundedProgress(
                learned / phrases.length,
                color: Module.enPhrases.color,
              ),
              const SizedBox(height: 6),
              Text(
                context.l10n.learn_progress(learned, phrases.length),
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              for (final p in phrases)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(4, 8, 8, 8),
                      child: Row(
                        children: [
                          LearnedToggle(p.key),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.text,
                                  style: theme.textTheme.titleMedium,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  p.meaning,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colors.textMuted,
                                  ),
                                ),
                                if (p.note != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    '💡 ${p.note}',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          SpeakButton(p.text, language: 'en-US'),
                        ],
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
