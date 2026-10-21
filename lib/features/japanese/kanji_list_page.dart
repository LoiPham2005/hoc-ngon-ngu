import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingua/design/l10n/l10n_extensions.dart';
import 'package:lingua/design/l10n/locale_notifier.dart';
import 'package:lingua/features/course/models/course_model.dart';
import 'package:lingua/features/course/providers/learner_notifier.dart';
import 'package:lingua/features/course/widgets/module_card.dart';
import 'package:lingua/features/japanese/kana_table_page.dart';
import 'package:lingua/features/japanese/models/kanji_model.dart';
import 'package:lingua/features/japanese/providers/kanji_provider.dart';
import 'package:lingua/routes/app_router.dart';
import 'package:lingua/shared/base/app_ui.dart';
import 'package:lingua/shared/states/async_view.dart';
import 'package:lingua/shared/states/empty_widget.dart';

/// Kanji của 1 cấp JLPT: tìm kiếm + lưới chữ (đã thuộc có ✓).
@RoutePage()
class KanjiListPage extends HookConsumerWidget {
  const KanjiListPage({required this.level, super.key});

  final JlptLevel level;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final module = Module.values.firstWhere((m) => m.kanjiLevel == level);
    final query = useState('');
    final language = ref.watch(localeProvider).languageCode;
    final l10n = context.l10n;
    final p = moduleProgress(ref, module);

    return Scaffold(
      appBar: AppBar(title: Text(module.title(context))),
      body: AsyncView<List<Kanji>>(
        state: ref.watch(kanjiListProvider),
        onRetry: () => ref.invalidate(kanjiListProvider),
        builder: (context, all) {
          final q = query.value.trim().toLowerCase();
          final items = [
            for (final k in all)
              if (k.level == level &&
                  (q.isEmpty ||
                      k.char == q ||
                      k.hanViet.toLowerCase().contains(q) ||
                      k.meaningFor(language).toLowerCase().contains(q)))
                k,
          ];
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RoundedProgress(
                      p.total == 0 ? 0 : p.learned / p.total,
                      color: module.color,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.learn_progress(p.learned, p.total),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      onChanged: (v) => query.value = v,
                      decoration: InputDecoration(
                        hintText: l10n.kanji_search,
                        prefixIcon: const Icon(Icons.search_rounded),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: items.isEmpty
                    ? EmptyWidget(
                        title: l10n.kanji_noResult,
                        icon: Icons.search_off_rounded,
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 78,
                              mainAxisExtent: 70,
                              crossAxisSpacing: 6,
                              mainAxisSpacing: 6,
                            ),
                        itemCount: items.length,
                        itemBuilder: (context, i) => _KanjiCell(
                          items[i],
                          module.color,
                          caption: language == 'vi'
                              ? items[i].hanViet
                              : items[i].meaningEn,
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

class _KanjiCell extends ConsumerWidget {
  const _KanjiCell(this.kanji, this.color, {required this.caption});

  final Kanji kanji;
  final Color color;
  final String caption;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final learned = ref.watch(
      learnerProvider.select((l) => l.learned.contains(kanji.char)),
    );
    return CharCell(
      glyph: kanji.char,
      caption: caption,
      learned: learned,
      color: color,
      onTap: () => context.router.push(
        KanjiDetailRoute(level: kanji.level, char: kanji.char),
      ),
    );
  }
}
