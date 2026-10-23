import 'package:auto_route/auto_route.dart';
import 'package:lingua/core/utils/fuzzy_search.dart';
import 'package:lingua/design/l10n/locale_notifier.dart';
import 'package:lingua/features/course/models/course_model.dart';
import 'package:lingua/features/japanese/models/kana_model.dart';
import 'package:lingua/features/japanese/providers/kanji_provider.dart';
import 'package:lingua/features/lessons/providers/lesson_provider.dart';
import 'package:lingua/routes/app_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'search_provider.g.dart';

/// Nhóm kết quả (thứ tự = thứ tự hiển thị).
enum SearchKind { kana, kanji, word, phrase }

/// 1 mục tra được: [title] (chữ / từ / câu), [reading] (cách đọc), [meaning], màn mở ra [route].
class SearchEntry {
  const SearchEntry({
    required this.kind,
    required this.title,
    required this.meaning,
    required this.route,
    this.reading,
  });

  final SearchKind kind;
  final String title;
  final String? reading;
  final String meaning;
  final PageRouteInfo route;
}

/// Chỉ mục tra cứu 1 khoá: tìm gần đúng (gõ sai vẫn ra) + gợi ý "Có phải bạn muốn tìm…".
class SearchIndex {
  SearchIndex(List<SearchEntry> entries)
    : _fuzzy = FuzzySearch(
        entries,
        fields: (e) => [e.title, ?e.reading, e.meaning],
      );

  final FuzzySearch<SearchEntry> _fuzzy;

  /// Tối đa [limit] kết quả, đúng nhất lên trước rồi gom theo nhóm [SearchKind].
  List<SearchEntry> find(String query, {int limit = 60}) {
    final ranked = _fuzzy.search(query, limit: limit).indexed.toList()
      ..sort((a, b) {
        final byKind = a.$2.kind.index.compareTo(b.$2.kind.index);
        return byKind != 0 ? byKind : a.$1.compareTo(b.$1);
      });
    return [for (final (_, e) in ranked) e];
  }

  String? suggest(String query) => _fuzzy.suggest(query);
}

/// Mọi mục tra được của [course]: Kana, Kanji (Hán Việt + nghĩa), từ vựng, câu giao tiếp.
/// Giữ lại sau khi đóng màn tra cứu → mở lại tìm ngay, không dựng lại chỉ mục.
@Riverpod(keepAlive: true)
Future<SearchIndex> searchIndex(Ref ref, Course course) async {
  final language = ref.watch(localeProvider).languageCode;
  final words = await ref.watch(vocabTopicsProvider(course).future);
  final phrases = await ref.watch(phraseTopicsProvider(course).future);
  return SearchIndex([
    if (course == Course.ja) ...[
      for (final script in KanaScript.values)
        for (final k in KanaTable.all(script, withDakuten: true))
          SearchEntry(
            kind: SearchKind.kana,
            title: k.char,
            meaning: k.romaji,
            route: KanaDetailRoute(script: script, char: k.char),
          ),
      for (final k in await ref.watch(kanjiListProvider.future))
        SearchEntry(
          kind: SearchKind.kanji,
          title: k.char,
          reading: [...k.onyomi, ...k.kunyomi].join('、'),
          meaning: language == 'vi'
              ? '${k.hanViet} · ${k.meaning}'
              : k.meaningFor(language),
          route: KanjiDetailRoute(level: k.level, char: k.char),
        ),
    ],
    for (final t in words)
      for (final w in t.items)
        SearchEntry(
          kind: SearchKind.word,
          title: w.word,
          reading: w.readingLabel,
          meaning: w.meaning,
          route: WordDetailRoute(course: course, topicId: t.id, word: w.word),
        ),
    for (final t in phrases)
      for (final p in t.items)
        SearchEntry(
          kind: SearchKind.phrase,
          title: p.text,
          reading: p.reading,
          meaning: p.meaning,
          route: PhraseListRoute(course: course, topicId: t.id),
        ),
  ]);
}
