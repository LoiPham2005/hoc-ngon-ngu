/// Cấp JLPT — Kanji N5 → N2 (~980 chữ, đủ cho N2).
enum JlptLevel {
  n5('N5'),
  n4('N4'),
  n3('N3'),
  n2('N2');

  const JlptLevel(this.label);

  final String label;
}

class Kanji {
  const Kanji({
    required this.char,
    required this.level,
    required this.hanViet,
    required this.meaning,
    required this.onyomi,
    required this.kunyomi,
  });

  /// Từ `assets/japanese/kanji.json`: `{k, lv, hv, vi, on, kun}`.
  factory Kanji.fromJson(Map<String, dynamic> json) => Kanji(
    char: json['k'] as String,
    level: JlptLevel.values.byName(json['lv'] as String),
    hanViet: json['hv'] as String,
    meaning: json['vi'] as String,
    onyomi: (json['on'] as List).cast<String>(),
    kunyomi: (json['kun'] as List).cast<String>(),
  );

  final String char;
  final JlptLevel level;

  /// Âm Hán Việt, vd "Nhật"; 2 âm → "Lạc / Nhạc"; chữ Nhật tự tạo → "—".
  final String hanViet;

  /// Nghĩa tiếng Việt, vd "ngày, mặt trời".
  final String meaning;

  /// Âm On (katakana) / âm Kun (hiragana, phần đuôi trong ngoặc: ひと(つ)).
  final List<String> onyomi;
  final List<String> kunyomi;

  @override
  bool operator ==(Object other) => other is Kanji && other.char == char;

  @override
  int get hashCode => char.hashCode;
}
