/// Bảng chữ cái tiếng Nhật: Hiragana + Katakana (âm cơ bản + âm đục).
/// Dữ liệu local — không qua API. Katakana = Hiragana + 0x60 (cùng thứ tự trong Unicode).
enum KanaScript {
  hiragana('Hiragana'),
  katakana('Katakana');

  const KanaScript(this.label);

  final String label;
}

class Kana {
  const Kana(this.char, this.romaji, this.script);

  final String char;
  final String romaji;
  final KanaScript script;

  /// Chữ tương ứng ở bảng còn lại (あ ↔ ア).
  Kana get counterpart => script == KanaScript.hiragana
      ? Kana(_shift(char, 0x60), romaji, KanaScript.katakana)
      : Kana(_shift(char, -0x60), romaji, KanaScript.hiragana);

  @override
  bool operator ==(Object other) => other is Kana && other.char == char;

  @override
  int get hashCode => char.hashCode;
}

String _shift(String char, int offset) =>
    String.fromCharCode(char.codeUnitAt(0) + offset);

/// Phần Kana để luyện: âm cơ bản (46), âm đục ゛゜ (25) hoặc cả hai (71).
enum KanaSet { basic, dakuten, all }

/// Bảng 5 cột (a · i · u · e · o); `null` = ô trống.
typedef KanaRow = List<Kana?>;

abstract final class KanaTable {
  /// 46 âm cơ bản (gojūon).
  static List<KanaRow> basic(KanaScript script) => _build(_basic, script);

  /// 25 âm đục (dakuten ゛/ handakuten ゜).
  static List<KanaRow> dakuten(KanaScript script) => _build(_dakuten, script);

  /// Các chữ của [set] (đúng thứ tự trong bảng).
  static List<Kana> of(KanaScript script, KanaSet set) => [
    for (final row in [
      if (set != KanaSet.dakuten) ...basic(script),
      if (set != KanaSet.basic) ...dakuten(script),
    ])
      ...row.nonNulls,
  ];

  static List<Kana> all(KanaScript script, {bool withDakuten = false}) => [
    for (final row in [...basic(script), if (withDakuten) ...dakuten(script)])
      ...row.nonNulls,
  ];

  static List<KanaRow> _build(
    List<List<(String, String)?>> rows,
    KanaScript script,
  ) => [
    for (final row in rows)
      [
        for (final cell in row)
          if (cell == null)
            null
          else
            Kana(
              script == KanaScript.hiragana ? cell.$1 : _shift(cell.$1, 0x60),
              cell.$2,
              script,
            ),
      ],
  ];

  static const _basic = <List<(String, String)?>>[
    [('あ', 'a'), ('い', 'i'), ('う', 'u'), ('え', 'e'), ('お', 'o')],
    [('か', 'ka'), ('き', 'ki'), ('く', 'ku'), ('け', 'ke'), ('こ', 'ko')],
    [('さ', 'sa'), ('し', 'shi'), ('す', 'su'), ('せ', 'se'), ('そ', 'so')],
    [('た', 'ta'), ('ち', 'chi'), ('つ', 'tsu'), ('て', 'te'), ('と', 'to')],
    [('な', 'na'), ('に', 'ni'), ('ぬ', 'nu'), ('ね', 'ne'), ('の', 'no')],
    [('は', 'ha'), ('ひ', 'hi'), ('ふ', 'fu'), ('へ', 'he'), ('ほ', 'ho')],
    [('ま', 'ma'), ('み', 'mi'), ('む', 'mu'), ('め', 'me'), ('も', 'mo')],
    [('や', 'ya'), null, ('ゆ', 'yu'), null, ('よ', 'yo')],
    [('ら', 'ra'), ('り', 'ri'), ('る', 'ru'), ('れ', 're'), ('ろ', 'ro')],
    [('わ', 'wa'), null, null, null, ('を', 'wo')],
    [('ん', 'n'), null, null, null, null],
  ];

  static const _dakuten = <List<(String, String)?>>[
    [('が', 'ga'), ('ぎ', 'gi'), ('ぐ', 'gu'), ('げ', 'ge'), ('ご', 'go')],
    [('ざ', 'za'), ('じ', 'ji'), ('ず', 'zu'), ('ぜ', 'ze'), ('ぞ', 'zo')],
    [('だ', 'da'), ('ぢ', 'ji'), ('づ', 'zu'), ('で', 'de'), ('ど', 'do')],
    [('ば', 'ba'), ('び', 'bi'), ('ぶ', 'bu'), ('べ', 'be'), ('ぼ', 'bo')],
    [('ぱ', 'pa'), ('ぴ', 'pi'), ('ぷ', 'pu'), ('ぺ', 'pe'), ('ぽ', 'po')],
  ];
}
