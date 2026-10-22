import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingua/design/l10n/l10n_extensions.dart';
import 'package:lingua/design/l10n/locale_notifier.dart';
import 'package:lingua/features/course/models/course_model.dart';
import 'package:lingua/features/english/models/english_model.dart';
import 'package:lingua/features/english/providers/english_provider.dart';
import 'package:lingua/features/english/widgets/english_widgets.dart';
import 'package:lingua/routes/app_router.dart';
import 'package:lingua/shared/base/app_ui.dart';
import 'package:lingua/shared/states/async_view.dart';

/// Danh sách chủ đề từ vựng ([module] = enVocabulary) hoặc tình huống giao tiếp (enPhrases).
@RoutePage()
class EnglishTopicsPage extends ConsumerWidget {
  const EnglishTopicsPage({required this.module, super.key});

  final Module module;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final words = module == Module.enVocabulary;
    final language = ref.watch(localeProvider).languageCode;
    final l10n = context.l10n;

    Widget list<T>(
      AsyncValue<List<Topic<T>>> state,
      String Function(T item) key,
      VoidCallback onRetry,
    ) => AsyncView<List<Topic<T>>>(
      state: state,
      onRetry: onRetry,
      builder: (context, topics) => ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: topics.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final t = topics[i];
          final total = t.items.length;
          final learned = learnedCount(ref, t.items.map(key));
          return Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => context.router.push(
                words
                    ? VocabListRoute(topicId: t.id)
                    : PhraseListRoute(topicId: t.id),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Text(t.emoji, style: const TextStyle(fontSize: 34)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.name(language),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            words
                                ? l10n.topics_words(total)
                                : l10n.topics_phrases(total),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 8),
                          RoundedProgress(
                            total == 0 ? 0 : learned / total,
                            color: module.color,
                            height: 6,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$learned/$total',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );

    return Scaffold(
      appBar: AppBar(title: Text(module.title(context))),
      body: words
          ? list<Word>(
              ref.watch(vocabTopicsProvider),
              (w) => w.key,
              () => ref.invalidate(vocabTopicsProvider),
            )
          : list<Phrase>(
              ref.watch(phraseTopicsProvider),
              (p) => p.key,
              () => ref.invalidate(phraseTopicsProvider),
            ),
    );
  }
}
