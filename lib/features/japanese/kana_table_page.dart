import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingua/design/l10n/l10n_extensions.dart';
import 'package:lingua/design/theme/app_colors.dart';
import 'package:lingua/features/course/models/course_model.dart';
import 'package:lingua/features/course/providers/learner_notifier.dart';
import 'package:lingua/features/course/widgets/module_card.dart';
import 'package:lingua/features/japanese/models/kana_model.dart';
import 'package:lingua/routes/app_router.dart';
import 'package:lingua/shared/base/app_ui.dart';

/// Bảng Hiragana / Katakana (cột a·i·u·e·o). Chữ đã thuộc có nền màu + dấu ✓.
@RoutePage()
class KanaTablePage extends ConsumerWidget {
  const KanaTablePage({required this.script, super.key});

  final KanaScript script;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final module = script == KanaScript.hiragana
        ? Module.hiragana
        : Module.katakana;
    final l10n = context.l10n;
    final p = moduleProgress(ref, module);
    return Scaffold(
      appBar: AppBar(title: Text(module.title(context))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
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
          SectionTitle(l10n.kana_basic),
          for (final row in KanaTable.basic(script)) _Row(row, module.color),
          const SizedBox(height: 16),
          SectionTitle(l10n.kana_dakuten),
          for (final row in KanaTable.dakuten(script)) _Row(row, module.color),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.row, this.color);

  final KanaRow row;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (final kana in row)
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: kana == null
                ? const SizedBox(height: 70)
                : _Cell(kana, color),
          ),
        ),
    ],
  );
}

class _Cell extends ConsumerWidget {
  const _Cell(this.kana, this.color);

  final Kana kana;
  final Color color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final learned = ref.watch(
      learnerProvider.select((l) => l.learned.contains(kana.char)),
    );
    return CharCell(
      glyph: kana.char,
      caption: kana.romaji,
      learned: learned,
      color: color,
      onTap: () => context.router.push(
        KanaDetailRoute(script: kana.script, char: kana.char),
      ),
    );
  }
}

/// Ô chữ trong bảng/lưới (dùng chung Kana + Kanji).
class CharCell extends StatelessWidget {
  const CharCell({
    required this.glyph,
    required this.caption,
    required this.learned,
    required this.color,
    required this.onTap,
    super.key,
  });

  final String glyph;
  final String caption;
  final bool learned;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    return Material(
      color: learned ? color.withValues(alpha: 0.14) : colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: learned ? color : colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 70,
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      glyph,
                      style: const TextStyle(fontSize: 26, height: 1.15),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Text(
                        caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall,
                      ),
                    ),
                  ],
                ),
              ),
              if (learned)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Icon(
                    Icons.check_circle_rounded,
                    size: 14,
                    color: color,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
