import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:lingua/features/japanese/models/kanji_model.dart';
import 'package:lingua/features/japanese/widgets/writing_box.dart';
import 'package:lingua/shared/base/app_scaffold.dart';

/// Chi tiết 1 Kanji: âm Hán Việt, nghĩa, âm On/Kun + thứ tự nét + tập viết.
@RoutePage()
class KanjiDetailPage extends StatelessWidget {
  const KanjiDetailPage({required this.kanji, super.key});

  final Kanji kanji;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppScaffold(
      appBar: AppBar(title: Text('${kanji.char} · ${kanji.hanViet}')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  kanji.char,
                  style: const TextStyle(fontSize: 72, height: 1.1),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              kanji.hanViet.toUpperCase(),
                              style: theme.textTheme.headlineSmall,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Chip(
                            label: Text(kanji.level.label),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                      Text(kanji.meaning, style: theme.textTheme.bodyLarge),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _Reading('Âm On', kanji.onyomi),
            _Reading('Âm Kun', kanji.kunyomi),
            const SizedBox(height: 12),
            Expanded(child: WritingPanel(char: kanji.char)),
          ],
        ),
      ),
    );
  }
}

class _Reading extends StatelessWidget {
  const _Reading(this.label, this.values);

  final String label;
  final List<String> values;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label: ',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          TextSpan(
            text: values.isEmpty ? '—' : values.join('、'),
            style: theme.textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}
