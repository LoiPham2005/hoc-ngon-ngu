import 'package:lingua/features/course/models/course_model.dart';
import 'package:lingua/features/japanese/models/kana_model.dart';
import 'package:lingua/features/japanese/providers/kanji_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'module_chars_provider.g.dart';

/// Danh sách chữ của 1 học phần, đúng thứ tự học (dùng tính tiến độ, chữ trước/sau).
@Riverpod(keepAlive: true)
Future<List<String>> moduleChars(Ref ref, Module module) async =>
    switch (module) {
      Module.hiragana => _kana(KanaScript.hiragana),
      Module.katakana => _kana(KanaScript.katakana),
      _ => [
        for (final k in await ref.watch(kanjiListProvider.future))
          if (k.level == module.kanjiLevel) k.char,
      ],
    };

List<String> _kana(KanaScript script) => [
  for (final k in KanaTable.all(script, withDakuten: true)) k.char,
];
