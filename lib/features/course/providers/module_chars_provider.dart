import 'package:lingua/features/course/models/course_model.dart';
import 'package:lingua/features/japanese/models/kana_model.dart';
import 'package:lingua/features/japanese/providers/kanji_provider.dart';
import 'package:lingua/features/lessons/models/lesson_model.dart';
import 'package:lingua/features/lessons/providers/lesson_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'module_chars_provider.g.dart';

/// Khoá "đã thuộc" của mọi mục trong 1 học phần, đúng thứ tự học (tính tiến độ, chữ trước/sau).
/// Kana/Kanji = chính chữ; bài học = `<khoá>:w:<từ>` / `:p:<id câu>` / `:g:<id bài>` / `:d:<id hội thoại>`;
/// âm IPA = `en:ph:<âm>`.
@Riverpod(keepAlive: true)
Future<List<String>> moduleChars(Ref ref, Module module) async {
  final course = module.course;
  return switch (module.lessonKind) {
    LessonKind.vocabulary => [
      for (final t in await ref.watch(vocabTopicsProvider(course).future))
        for (final w in t.items) w.key,
    ],
    LessonKind.phrases => [
      for (final t in await ref.watch(phraseTopicsProvider(course).future))
        for (final p in t.items) p.key,
    ],
    LessonKind.dialogues => [
      for (final d in await ref.watch(dialoguesProvider(course).future)) d.key,
    ],
    LessonKind.grammar => [
      for (final g in await ref.watch(grammarLessonsProvider(course).future))
        g.key,
    ],
    null => switch (module) {
      Module.hiragana => _kana(KanaScript.hiragana),
      Module.katakana => _kana(KanaScript.katakana),
      Module.enPronunciation => [for (final p in phonemes) p.key],
      _ => [
        for (final k in await ref.watch(kanjiListProvider.future))
          if (k.level == module.kanjiLevel) k.char,
      ],
    },
  };
}

List<String> _kana(KanaScript script) => [
  for (final k in KanaTable.all(script, withDakuten: true)) k.char,
];
