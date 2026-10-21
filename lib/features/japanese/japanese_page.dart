import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:lingua/features/japanese/models/kana_model.dart';
import 'package:lingua/features/japanese/widgets/kanji_tab.dart';
import 'package:lingua/routes/app_router.dart';
import 'package:lingua/shared/base/app_scaffold.dart';

/// Học tiếng Nhật: tab Hiragana / Katakana (bảng chữ cái) + tab Kanji (N5–N2).
/// Bấm chữ → xem cách viết; nút "Luyện tập" mở trắc nghiệm của tab đang xem.
@RoutePage()
class JapanesePage extends StatelessWidget {
  const JapanesePage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: KanaScript.values.length + 1,
      child: AppScaffold(
        appBar: AppBar(
          title: const Text('Học tiếng Nhật'),
          bottom: TabBar(
            tabs: [
              for (final s in KanaScript.values) Tab(text: s.label),
              const Tab(text: 'Kanji'),
            ],
          ),
        ),
        floatingActionButton: const _PracticeButton(),
        body: TabBarView(
          children: [
            for (final s in KanaScript.values) _KanaTableView(script: s),
            const KanjiTab(),
          ],
        ),
      ),
    );
  }
}

/// Tab Kana → luyện Kana, tab Kanji → luyện Kanji.
class _PracticeButton extends StatelessWidget {
  const _PracticeButton();

  @override
  Widget build(BuildContext context) {
    final tabs = DefaultTabController.of(context);
    return ListenableBuilder(
      listenable: tabs,
      builder: (context, _) => FloatingActionButton.extended(
        onPressed: () => context.router.push(
          tabs.index < KanaScript.values.length
              ? const KanaQuizRoute()
              : const KanjiQuizRoute(),
        ),
        icon: const Icon(Icons.quiz_outlined),
        label: const Text('Luyện tập'),
      ),
    );
  }
}

class _KanaTableView extends StatelessWidget {
  const _KanaTableView({required this.script});

  final KanaScript script;

  @override
  Widget build(BuildContext context) {
    final title = Theme.of(context).textTheme.titleMedium;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        12,
        16,
        12,
        96,
      ), // chừa chỗ cho nút Luyện tập
      children: [
        Text('Âm cơ bản', style: title),
        const SizedBox(height: 8),
        for (final row in KanaTable.basic(script)) _KanaRowView(row),
        const SizedBox(height: 24),
        Text('Âm đục ゛ ゜', style: title),
        const SizedBox(height: 8),
        for (final row in KanaTable.dakuten(script)) _KanaRowView(row),
      ],
    );
  }
}

class _KanaRowView extends StatelessWidget {
  const _KanaRowView(this.row);

  final KanaRow row;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final kana in row)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: kana == null
                  ? const SizedBox(height: 68)
                  : _KanaCell(kana),
            ),
          ),
      ],
    );
  }
}

class _KanaCell extends StatelessWidget {
  const _KanaCell(this.kana);

  final Kana kana;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.router.push(KanaDetailRoute(kana: kana)),
        child: SizedBox(
          height: 68,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(kana.char, style: const TextStyle(fontSize: 26)),
              Text(
                kana.romaji,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
