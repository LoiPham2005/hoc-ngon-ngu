import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingua/features/japanese/models/kana_model.dart';

void main() {
  for (final script in KanaScript.values) {
    test('${script.label}: 46 âm cơ bản + 25 âm đục, không trùng', () {
      final basic = KanaTable.all(script);
      final all = KanaTable.all(script, withDakuten: true);
      expect(basic, hasLength(46));
      expect(all, hasLength(71));
      expect(all.map((k) => k.char).toSet(), hasLength(71));
      expect(KanaTable.basic(script).every((row) => row.length == 5), isTrue);
    });
  }

  test('Katakana = Hiragana + 0x60, counterpart đi 2 chiều', () {
    const a = Kana('あ', 'a', KanaScript.hiragana);
    expect(a.counterpart.char, 'ア');
    expect(a.counterpart.counterpart, a);
    expect(KanaTable.all(KanaScript.katakana).last.char, 'ン');
  });

  test('assets/japanese/strokes.json có nét cho mọi Kana', () {
    final strokes =
        jsonDecode(File('assets/japanese/strokes.json').readAsStringSync())
            as Map<String, dynamic>;
    for (final script in KanaScript.values) {
      for (final kana in KanaTable.all(script, withDakuten: true)) {
        expect(strokes[kana.char], isNotEmpty, reason: kana.char);
      }
    }
    expect(strokes['あ'], hasLength(3));
    expect(strokes['が'], hasLength(5)); // か (3 nét) + ゛ (2 nét)
  });
}
