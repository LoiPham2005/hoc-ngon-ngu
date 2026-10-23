import 'package:auto_route/auto_route.dart';
import 'package:lingua/core/utils/text_fold.dart';
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
  SearchEntry({
    required this.kind,
    required this.title,
    required this.meaning,
    required this.route,
    this.reading,
  }) : _text = foldText('$title ${reading ?? ''}'),
       _meaning = foldText(meaning);

  final SearchKind kind;
  final String title;
  final String? reading;
  final String meaning;
  final PageRouteInfo route;

  final String _text;
  final String _meaning;

  /// Điểm khớp với [query] đã chuẩn hoá (`foldText`): 0 = không khớp, càng cao càng đúng.
  int score(String query) {
    if (_text == query || _meaning == query) return 4;
    if (_text.startsWith(query) || _meaning.startsWith(query)) return 3;
    if (RegExp('(^|[ ,;/(])${RegExp.escape(query)}').hasMatch(_meaning)) {
      return 2; // khớp đầu 1 nghĩa: "cơm, gạo" ← "gao"
    }
    return _text.contains(query) || _meaning.contains(query) ? 1 : 0;
  }
}

/// Mọi mục tra được của [course]: Kana, Kanji (Hán Việt + nghĩa), từ vựng, câu giao tiếp.
/// Giữ lại sau khi đóng màn tra cứu → mở lại tìm ngay, không dựng lại chỉ mục.
@Riverpod(keepAlive: true)
Future<List<SearchEntry>> searchIndex(Ref ref, Course course) async {
  final language = ref.watch(localeProvider).languageCode;
  final words = await ref.watch(vocabTopicsProvider(course).future);
  final phrases = await ref.watch(phraseTopicsProvider(course).future);
  return [
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
  ];
}

/// Tối đa [limit] kết quả khớp [query], khớp đúng hơn lên trước, giữ nhóm theo [SearchKind].
List<SearchEntry> search(
  List<SearchEntry> index,
  String query, {
  int limit = 60,
}) {
  final q = foldText(query.trim());
  if (q.isEmpty) return const [];
  final hits =
      [
        for (final (i, e) in index.indexed)
          if (e.score(q) case final s when s > 0) (e, s, i),
      ]..sort((a, b) {
        final byScore = b.$2.compareTo(a.$2);
        return byScore != 0 ? byScore : a.$3.compareTo(b.$3);
      });
  return [for (final (e, _, _) in hits.take(limit)) e]
    ..sort((a, b) => a.kind.index.compareTo(b.kind.index));
}
