import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingua/design/l10n/l10n_extensions.dart';
import 'package:lingua/design/theme/app_colors.dart';
import 'package:lingua/features/course/models/course_model.dart';
import 'package:lingua/features/course/providers/learner_notifier.dart';
import 'package:lingua/features/search/providers/search_provider.dart';
import 'package:lingua/shared/base/app_ui.dart';
import 'package:lingua/shared/states/async_view.dart';

/// Tra cứu trong khoá đang học: gõ tiếng Việt (có/không dấu), tiếng Anh, kana, Kanji, Hán Việt.
@RoutePage()
class SearchPage extends HookConsumerWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final course =
        ref.watch(learnerProvider.select((l) => l.course)) ?? Course.ja;
    final l10n = context.l10n;
    final controller = useTextEditingController();
    final query = useState('');
    // Gõ xong ~200ms mới tìm, tránh tìm lại theo từng phím.
    useEffect(() {
      Timer? timer;
      void onChanged() {
        timer?.cancel();
        timer = Timer(
          const Duration(milliseconds: 200),
          () => query.value = controller.text,
        );
      }

      controller.addListener(onChanged);
      return () {
        timer?.cancel();
        controller.removeListener(onChanged);
      };
    }, [controller]);
    final state = ref.watch(searchIndexProvider(course));

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: l10n.search_hint,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
          ),
        ),
        actions: [
          if (query.value.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: controller.clear,
            ),
        ],
      ),
      body: AsyncView<List<SearchEntry>>(
        state: state,
        onRetry: () => ref.invalidate(searchIndexProvider(course)),
        builder: (context, index) {
          if (query.value.trim().isEmpty) {
            return _Hint(l10n.search_empty(course.title(context)));
          }
          final results = search(index, query.value);
          if (results.isEmpty) return _Hint(l10n.search_noResult);
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            itemCount: results.length,
            itemBuilder: (context, i) {
              final e = results[i];
              final header = i == 0 || results[i - 1].kind != e.kind;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (header) ...[
                    if (i > 0) const SizedBox(height: 8),
                    SectionTitle(_kindTitle(context, e.kind)),
                  ],
                  Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    clipBehavior: Clip.antiAlias,
                    child: ListTile(
                      onTap: () => context.router.push(e.route),
                      title: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: e.title,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            if (e.reading case final reading?)
                              TextSpan(
                                text: '  $reading',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                          ],
                        ),
                      ),
                      subtitle: Text(e.meaning),
                      trailing: const Icon(Icons.chevron_right_rounded),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  String _kindTitle(BuildContext context, SearchKind kind) {
    final l10n = context.l10n;
    return switch (kind) {
      SearchKind.kana => l10n.learn_alphabet,
      SearchKind.kanji => l10n.learn_kanji,
      SearchKind.word => l10n.search_words,
      SearchKind.phrase => l10n.search_phrases,
    };
  }
}

class _Hint extends StatelessWidget {
  const _Hint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(color: context.colors.textMuted),
      ),
    ),
  );
}
