import 'package:lingua/features/course/models/course_model.dart';
import 'package:lingua/features/english/models/english_model.dart';
import 'package:lingua/features/english/providers/english_provider.dart';
import 'package:lingua/features/japanese/models/kana_model.dart';
import 'package:lingua/features/japanese/providers/kanji_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'module_chars_provider.g.dart';

/// Khoá "đã thuộc" của mọi mục trong 1 học phần, đúng thứ tự học (tính tiến độ, chữ trước/sau).
/// Kana/Kanji = chính chữ; Tiếng Anh = `en:w:<từ>` / `en:p:<id câu>` / `en:ph:<âm>` / `en:g:<id bài>` / `en:d:<id hội thoại>`.
@Riverpod(keepAlive: true)
Future<List<String>> moduleChars(Ref ref, Module module) async =>
    switch (module) {
      Module.hiragana => _kana(KanaScript.hiragana),
      Module.katakana => _kana(KanaScript.katakana),
      Module.enPronunciation => [for (final p in phonemes) p.key],
      Module.enVocabulary => [
        for (final t in await ref.watch(vocabTopicsProvider.future))
          for (final w in t.items) w.key,
      ],
      Module.enPhrases => [
        for (final t in await ref.watch(phraseTopicsProvider.future))
          for (final p in t.items) p.key,
      ],
      Module.enDialogues => [
        for (final d in await ref.watch(dialoguesProvider.future)) d.key,
      ],
      Module.enGrammar => [
        for (final g in await ref.watch(grammarLessonsProvider.future)) g.key,
      ],
      _ => [
        for (final k in await ref.watch(kanjiListProvider.future))
          if (k.level == module.kanjiLevel) k.char,
      ],
    };

List<String> _kana(KanaScript script) => [
  for (final k in KanaTable.all(script, withDakuten: true)) k.char,
];
