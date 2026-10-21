import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingua/design/l10n/l10n_extensions.dart';
import 'package:lingua/design/l10n/locale_notifier.dart';
import 'package:lingua/design/theme/app_colors.dart';
import 'package:lingua/features/course/models/course_model.dart';
import 'package:lingua/features/japanese/models/kanji_model.dart';
import 'package:lingua/features/japanese/providers/kanji_provider.dart';
import 'package:lingua/features/japanese/widgets/detail_layout.dart';
import 'package:lingua/routes/app_router.dart';
import 'package:lingua/shared/states/async_view.dart';

/// Chi tiết 1 Kanji: Hán Việt (giao diện tiếng Việt), nghĩa, âm On/Kun + thứ tự nét + tập viết.
@RoutePage()
class KanjiDetailPage extends ConsumerWidget {
  const KanjiDetailPage({required this.level, required this.char, super.key});

  final JlptLevel level;
  final String char;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final module = Module.values.firstWhere((m) => m.kanjiLevel == level);
    final language = ref.watch(localeProvider).languageCode;
    final state = ref.watch(kanjiListProvider);
    final all = state.value;
    if (all == null) {
      return Scaffold(
        appBar: AppBar(title: Text(module.title(context))),
        body: AsyncView<List<Kanji>>(
          state: state,
          onRetry: () => ref.invalidate(kanjiListProvider),
          builder: (_, _) => const SizedBox.shrink(),
        ),
      );
    }
    final inLevel = [
      for (final k in all)
        if (k.level == level) k,
    ];
    final kanji = inLevel.firstWhere((k) => k.char == char);
    return DetailLayout(
      title: module.title(context),
      char: char,
      color: module.color,
      chars: [for (final k in inLevel) k.char],
      speech: kanji.speech,
      onOpen: (c) =>
          context.router.replace(KanjiDetailRoute(level: level, char: c)),
      info: _KanjiInfo(kanji, language: language),
    );
  }
}

class _KanjiInfo extends StatelessWidget {
  const _KanjiInfo(this.kanji, {required this.language});

  final Kanji kanji;
  final String language;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final l10n = context.l10n;
    Widget reading(String label, List<String> values) => Text.rich(
      TextSpan(
        children: [
          TextSpan(text: '$label  ', style: theme.textTheme.bodySmall),
          TextSpan(text: values.isEmpty ? '—' : values.join('、')),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (language == 'vi')
          Text(
            kanji.hanViet.toUpperCase(),
            style: theme.textTheme.headlineSmall?.copyWith(
              color: colors.primary,
            ),
          ),
        Text(
          kanji.meaningFor(language),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 6),
        reading(l10n.detail_onyomi, kanji.onyomi),
        reading(l10n.detail_kunyomi, kanji.kunyomi),
      ],
    );
  }
}
