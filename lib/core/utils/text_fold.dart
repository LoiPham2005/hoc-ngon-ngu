/// Chuẩn hoá chữ để tìm kiếm: chữ thường, bỏ dấu tiếng Việt (ă â đ ê ô ơ ư + 5 thanh),
/// Katakana → Hiragana. "Ăn cơm" ≈ "an com", "タベル" ≈ "たべる".
String foldText(String text) {
  final buffer = StringBuffer();
  for (final c in text.toLowerCase().runes) {
    final ch = String.fromCharCode(c);
    buffer.write(
      c >= 0x30A1 && c <= 0x30F6
          ? String.fromCharCode(c - 0x60)
          : _vietnamese[ch] ?? ch,
    );
  }
  return buffer.toString();
}

const _groups = {
  'a': 'àáảãạăằắẳẵặâầấẩẫậ',
  'e': 'èéẻẽẹêềếểễệ',
  'i': 'ìíỉĩị',
  'o': 'òóỏõọôồốổỗộơờớởỡợ',
  'u': 'ùúủũụưừứửữự',
  'y': 'ỳýỷỹỵ',
  'd': 'đ',
};

final _vietnamese = {
  for (final MapEntry(key: base, value: chars) in _groups.entries)
    for (final c in chars.split('')) c: base,
};
