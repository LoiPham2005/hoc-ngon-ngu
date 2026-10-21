import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:lingua/features/japanese/models/kana_model.dart';
import 'package:lingua/features/japanese/widgets/writing_box.dart';
import 'package:lingua/routes/app_router.dart';
import 'package:lingua/shared/base/app_scaffold.dart';

/// Chi tiết 1 chữ Kana: thứ tự nét (hoạt ảnh) + ô tập viết.
@RoutePage()
class KanaDetailPage extends StatelessWidget {
  const KanaDetailPage({required this.kana, super.key});

  final Kana kana;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final other = kana.counterpart;
    return AppScaffold(
      appBar: AppBar(title: Text('${kana.char} · ${kana.romaji}')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  kana.char,
                  style: const TextStyle(fontSize: 64, height: 1.1),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(kana.romaji, style: theme.textTheme.headlineSmall),
                      Text(
                        kana.script.label,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                ActionChip(
                  label: Text('${other.script.label}: ${other.char}'),
                  onPressed: () =>
                      context.router.replace(KanaDetailRoute(kana: other)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(child: WritingPanel(char: kana.char)),
          ],
        ),
      ),
    );
  }
}
