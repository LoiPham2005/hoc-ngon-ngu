import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingua/features/japanese/models/kanji_model.dart';
import 'package:lingua/features/japanese/providers/kanji_provider.dart';
import 'package:lingua/routes/app_router.dart';
import 'package:lingua/shared/states/async_view.dart';

/// Tab Kanji: chọn cấp N5–N2 → lưới chữ (Kanji + âm Hán Việt), bấm → chi tiết.
class KanjiTab extends HookConsumerWidget {
  const KanjiTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final level = useState(JlptLevel.n5);
    return AsyncView<List<Kanji>>(
      state: ref.watch(kanjiListProvider),
      onRetry: () => ref.invalidate(kanjiListProvider),
      builder: (context, all) {
        final items = [
          for (final k in all)
            if (k.level == level.value) k,
        ];
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
              child: SegmentedButton<JlptLevel>(
                segments: [
                  for (final l in JlptLevel.values)
                    ButtonSegment(value: l, label: Text(l.label)),
                ],
                selected: {level.value},
                onSelectionChanged: (s) => level.value = s.first,
              ),
            ),
            Text(
              '${items.length} chữ · xếp theo độ thông dụng',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Expanded(
              child: GridView.builder(
                // Chừa chỗ cho nút "Luyện tập".
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 76,
                  mainAxisExtent: 76,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                ),
                itemCount: items.length,
                itemBuilder: (context, i) => _KanjiCell(items[i]),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _KanjiCell extends StatelessWidget {
  const _KanjiCell(this.kanji);

  final Kanji kanji;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.router.push(KanjiDetailRoute(kanji: kanji)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(kanji.char, style: const TextStyle(fontSize: 28, height: 1.1)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                kanji.hanViet,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
