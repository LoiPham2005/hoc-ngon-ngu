import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingua/design/l10n/l10n_extensions.dart';
import 'package:lingua/design/theme/app_colors.dart';
import 'package:lingua/features/course/models/course_model.dart';
import 'package:lingua/features/course/providers/learner_notifier.dart';
import 'package:lingua/features/search/providers/recent_searches_notifier.dart';
import 'package:lingua/features/search/providers/search_provider.dart';
import 'package:lingua/modules/ads/ad_config.dart';
import 'package:lingua/modules/ads/widgets/native_ad_widget.dart';
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
    final recent = ref.watch(recentSearchesProvider);

    void searchFor(String text) {
      controller.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
      query.value = text;
    }

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
      body: AsyncView<SearchIndex>(
        state: state,
        onRetry: () => ref.invalidate(searchIndexProvider(course)),
        builder: (context, index) {
          if (query.value.trim().isEmpty) {
            if (recent.isEmpty) {
              return _Hint(l10n.search_empty(course.title(context)));
            }
            return _Recent(recent, onTap: searchFor);
          }
          final results = index.find(query.value);
          final suggestion = index.suggest(query.value);
          final suggestionTile = suggestion == null
              ? null
              : _Suggestion(suggestion, onTap: () => searchFor(suggestion));
          if (results.isEmpty) {
            return suggestionTile == null
                ? _Hint(l10n.search_noResult)
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [suggestionTile],
                  );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            itemCount: results.length,
            itemBuilder: (context, i) {
              final e = results[i];
              final header = i == 0 || results[i - 1].kind != e.kind;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (i == 0 && suggestionTile != null) suggestionTile,
                  if (header) ...[
                    if (i > 0) const SizedBox(height: 8),
                    SectionTitle(_kindTitle(context, e.kind)),
                  ],
                  Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    clipBehavior: Clip.antiAlias,
                    child: ListTile(
                      onTap: () {
                        ref
                            .read(recentSearchesProvider.notifier)
                            .add(query.value);
                        context.router.push(e.route);
                      },
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
                  // Native sau kết quả thứ 3, rồi cứ 8 kết quả (như withNativeAds).
                  if (i == 2 || (i > 2 && (i - 2) % 8 == 0))
                    const NativeAdWidget(
                      placement: NativePlacement.list,
                      size: NativeAdSize.small,
                      padding: EdgeInsets.only(bottom: 8),
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

/// "Có phải bạn muốn tìm: …?" — bấm để tìm lại bằng từ gợi ý.
class _Suggestion extends StatelessWidget {
  const _Suggestion(this.text, {required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: colors.primarySoft,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: '${context.l10n.search_didYouMean} '),
                  TextSpan(
                    text: text,
                    style: TextStyle(
                      color: colors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const TextSpan(text: ' ?'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Từ đã tra gần đây — bấm để tra lại, có nút xoá lịch sử.
class _Recent extends ConsumerWidget {
  const _Recent(this.items, {required this.onTap});

  final List<String> items;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        SectionTitle(
          l10n.search_recent,
          trailing: TextButton(
            onPressed: ref.read(recentSearchesProvider.notifier).clear,
            child: Text(l10n.search_clearRecent),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final q in items)
              ActionChip(
                avatar: const Icon(Icons.history_rounded, size: 18),
                label: Text(q),
                onPressed: () => onTap(q),
              ),
          ],
        ),
      ],
    );
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
