import 'dart:math';

import 'package:lingua/core/utils/text_fold.dart';

/// Tìm kiếm gần đúng ngay trên máy (offline), cho danh sách vài nghìn mục:
/// - Bỏ dấu tiếng Việt, không phân biệt hoa/thường, Katakana = Hiragana (`foldText`).
/// - Khớp đúng > khớp đầu chuỗi > khớp đầu 1 từ > chứa trong chuỗi > **gần đúng**
///   (gõ sai / thiếu / thừa / đảo 1–2 ký tự, theo khoảng cách Damerau–Levenshtein).
/// - Nhiều từ ("an com") → mọi từ đều phải khớp (ở bất kỳ trường nào).
///
/// ```dart
/// final index = FuzzySearch(users, fields: (u) => [u.name, u.email]);
/// index.search('ngyen');  // → "Nguyễn …"
/// index.suggest('ngyen'); // → "nguyễn" (Có phải bạn muốn tìm…)
/// ```
class FuzzySearch<T> {
  FuzzySearch(Iterable<T> items, {required List<String> Function(T) fields})
    : _entries = [
        for (final item in items)
          (item: item, fields: [for (final f in fields(item)) _Field(f)]),
      ];

  final List<({T item, List<_Field> fields})> _entries;

  /// Kết quả khớp [query], đúng nhất lên trước (cùng điểm → giữ thứ tự gốc).
  List<T> search(String query, {int limit = 50}) {
    final terms = _terms(query);
    if (terms.isEmpty) return const [];
    final scored = <(T, double, int)>[];
    for (final (i, e) in _entries.indexed) {
      final score = _score(e.fields, terms, foldText(query.trim()));
      if (score > 0) scored.add((e.item, score, i));
    }
    scored.sort((a, b) {
      final byScore = b.$2.compareTo(a.$2);
      return byScore != 0 ? byScore : a.$3.compareTo(b.$3);
    });
    return [for (final (item, _, _) in scored.take(limit)) item];
  }

  /// "Có phải bạn muốn tìm…": khi [query] KHÔNG khớp chính xác mục nào nhưng gần giống
  /// 1 từ có trong dữ liệu → trả từ đó (giữ dấu gốc). Khớp được / không giống gì → `null`.
  String? suggest(String query) {
    final terms = _terms(query);
    if (terms.isEmpty) return null;
    final parts = <String>[];
    var changed = false;
    for (final term in terms) {
      ({String text, int distance})? best;
      for (final e in _entries) {
        for (final f in e.fields) {
          // Đã khớp thật → không cần gợi ý.
          if (f.folded.contains(term)) return null;
          for (final t in f.tokens) {
            final d = _distance(term, t.folded, _allowed(term));
            if (d != null && (best == null || d < best.distance)) {
              best = (text: t.original, distance: d);
            }
          }
        }
      }
      if (best == null) return null;
      parts.add(best.text);
      changed |= best.distance > 0;
    }
    return changed ? parts.join(' ') : null;
  }

  static List<String> _terms(String query) => foldText(
    query.trim(),
  ).split(_separators).where((t) => t.isNotEmpty).toList();

  /// Điểm 1 mục: trung bình điểm các từ (từ nào không khớp → 0), cộng thưởng khớp cả cụm.
  static double _score(List<_Field> fields, List<String> terms, String phrase) {
    var total = 0.0;
    for (final term in terms) {
      var best = 0.0;
      for (final f in fields) {
        best = max(best, f.score(term));
        if (best >= 100) break;
      }
      if (best == 0) return 0;
      total += best;
    }
    var score = total / terms.length;
    if (terms.length > 1) {
      for (final f in fields) {
        if (f.folded.contains(phrase)) {
          score += 20;
          break;
        }
      }
    }
    return score;
  }

  /// Số ký tự được sai: chữ Nhật/Hán mỗi ký tự là 1 âm tiết → chặt hơn chữ Latin.
  static int _allowed(String term) {
    final n = term.runes.length;
    if (_cjk.hasMatch(term)) return n <= 2 ? 0 : (n <= 5 ? 1 : 2);
    return n <= 3 ? 0 : (n <= 7 ? 1 : 2);
  }

  /// Khoảng cách Damerau–Levenshtein (thêm / xoá / thay / đảo 2 ký tự liền nhau)
  /// giữa [a] và [b]; vượt [maxDistance] → `null` (dừng sớm cho nhanh).
  static int? _distance(String a, String b, int maxDistance) {
    if (maxDistance == 0) return a == b ? 0 : null;
    final s = a.runes.toList(), t = b.runes.toList();
    if ((s.length - t.length).abs() > maxDistance) return null;
    var prev2 = List.filled(t.length + 1, 0);
    var prev = List.generate(t.length + 1, (j) => j);
    for (var i = 1; i <= s.length; i++) {
      final cur = List.filled(t.length + 1, 0)..[0] = i;
      var rowMin = cur[0];
      for (var j = 1; j <= t.length; j++) {
        final cost = s[i - 1] == t[j - 1] ? 0 : 1;
        var v = min(min(prev[j] + 1, cur[j - 1] + 1), prev[j - 1] + cost);
        if (i > 1 && j > 1 && s[i - 1] == t[j - 2] && s[i - 2] == t[j - 1]) {
          v = min(v, prev2[j - 2] + 1);
        }
        cur[j] = v;
        rowMin = min(rowMin, v);
      }
      if (rowMin > maxDistance) return null;
      prev2 = prev;
      prev = cur;
    }
    return prev[t.length] <= maxDistance ? prev[t.length] : null;
  }
}

final _separators = RegExp(r'[\s,;/()·、。，．！？!?.:]+');
final _cjk = RegExp(r'[぀-ヿ㐀-鿿]');

/// 1 trường đã chuẩn hoá + tách từ (giữ chữ gốc để gợi ý có dấu).
class _Field {
  _Field(String original) : folded = foldText(original) {
    // foldText đổi đúng 1 ký tự → 1 ký tự nên vị trí 2 chuỗi trùng nhau.
    final sameLength = folded.length == original.length;
    tokens = [
      for (final m in _token.allMatches(folded))
        (
          folded: m[0]!,
          original: sameLength
              ? original.substring(m.start, m.end).toLowerCase()
              : m[0]!,
        ),
    ];
  }

  static final _token = RegExp(r'[^\s,;/()·、。，．！？!?.:]+');

  final String folded;
  late final List<({String folded, String original})> tokens;

  /// 100 khớp cả trường · 90 đầu trường · 80 đầu 1 từ · 60 chứa trong · 50/40 sai 1/2 ký tự.
  double score(String term) {
    if (folded == term) return 100;
    if (folded.startsWith(term)) return 90;
    if (tokens.any((t) => t.folded.startsWith(term))) return 80;
    if (folded.contains(term)) return 60;
    final allowed = FuzzySearch._allowed(term);
    if (allowed == 0) return 0;
    int? best;
    for (final t in tokens) {
      // So với cả từ và với phần đầu cùng độ dài (đang gõ dở: "frein" ~ "friend").
      final whole = FuzzySearch._distance(term, t.folded, allowed);
      final prefix = t.folded.length > term.length
          ? FuzzySearch._distance(
              term,
              t.folded.substring(0, term.length),
              allowed,
            )
          : null;
      for (final d in [whole, prefix]) {
        if (d != null && (best == null || d < best)) best = d;
      }
      if (best == 1) break;
    }
    return best == null ? 0 : 60 - 10.0 * best;
  }
}
