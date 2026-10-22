import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingua/design/l10n/l10n_extensions.dart';
import 'package:lingua/features/course/models/course_model.dart';
import 'package:lingua/features/course/providers/learner_notifier.dart';
import 'package:lingua/features/course/providers/module_chars_provider.dart';
import 'package:lingua/features/japanese/models/kana_model.dart';
import 'package:lingua/routes/app_router.dart';
import 'package:lingua/shared/base/app_ui.dart';

/// Tiến độ học phần: đã thuộc / tổng (tổng = 0 khi dữ liệu chưa tải xong).
({int learned, int total}) moduleProgress(WidgetRef ref, Module module) {
  final chars = ref.watch(moduleCharsProvider(module)).value ?? const [];
  final learned = ref.watch(learnerProvider.select((l) => l.learned));
  return (learned: chars.where(learned.contains).length, total: chars.length);
}

/// Mở học phần (ghi nhớ để "Tiếp tục học" ở Trang chủ).
void openModule(BuildContext context, WidgetRef ref, Module module) {
  ref.read(learnerProvider.notifier).openModule(module);
  context.router.push(switch (module) {
    Module.hiragana => KanaTableRoute(script: KanaScript.hiragana),
    Module.katakana => KanaTableRoute(script: KanaScript.katakana),
    Module.enPronunciation => const PronunciationRoute(),
    Module.enVocabulary => EnglishTopicsRoute(module: Module.enVocabulary),
    Module.enPhrases => EnglishTopicsRoute(module: Module.enPhrases),
    Module.enGrammar => const GrammarListRoute(),
    _ => KanjiListRoute(level: module.kanjiLevel!),
  });
}

/// Thẻ học phần: chữ đại diện + tên + mô tả + thanh tiến độ.
class ModuleCard extends ConsumerWidget {
  const ModuleCard(this.module, {super.key});

  final Module module;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final p = moduleProgress(ref, module);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => openModule(context, ref, module),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              GlyphBadge(module.glyph, color: module.color),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      module.title(context),
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      module.description(context, p.total),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 10),
                    RoundedProgress(
                      p.total == 0 ? 0 : p.learned / p.total,
                      color: module.color,
                      height: 6,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      context.l10n.learn_progress(p.learned, p.total),
                      style: theme.textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}
