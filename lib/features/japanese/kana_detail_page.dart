import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingua/features/course/models/course_model.dart';
import 'package:lingua/features/japanese/models/kana_model.dart';
import 'package:lingua/features/japanese/widgets/detail_layout.dart';
import 'package:lingua/routes/app_router.dart';

/// Chi tiết 1 chữ Kana: cách đọc + thứ tự nét + tập viết.
@RoutePage()
class KanaDetailPage extends ConsumerWidget {
  const KanaDetailPage({required this.script, required this.char, super.key});

  final KanaScript script;
  final String char;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = KanaTable.all(script, withDakuten: true);
    final kana = all.firstWhere((k) => k.char == char);
    final other = kana.counterpart;
    final module = script == KanaScript.hiragana
        ? Module.hiragana
        : Module.katakana;
    final theme = Theme.of(context);

    return DetailLayout(
      title: module.title(context),
      char: char,
      color: module.color,
      chars: [for (final k in all) k.char],
      onOpen: (c) =>
          context.router.replace(KanaDetailRoute(script: script, char: c)),
      info: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(kana.romaji, style: theme.textTheme.headlineMedium),
          Text(script.label, style: theme.textTheme.bodySmall),
          const SizedBox(height: 8),
          ActionChip(
            label: Text('${other.script.label} ${other.char}'),
            onPressed: () => context.router.replace(
              KanaDetailRoute(script: other.script, char: other.char),
            ),
          ),
        ],
      ),
    );
  }
}
