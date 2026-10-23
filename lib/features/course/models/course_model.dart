import 'package:flutter/widgets.dart';
import 'package:lingua/design/l10n/l10n_extensions.dart';
import 'package:lingua/design/theme/app_palette.dart';
import 'package:lingua/features/japanese/models/kanji_model.dart';

/// Ngôn ngữ có thể học. Thêm ngôn ngữ mới: thêm 1 giá trị + học phần ở [Module] + tên ở ARB `course_<id>`.
enum Course {
  ja('🇯🇵', available: true),
  en('🇬🇧', available: true),
  ko('🇰🇷'),
  zh('🇨🇳');

  const Course(this.flag, {this.available = false});

  final String flag;

  /// `false` = hiện "Sắp ra mắt", chưa chọn được.
  final bool available;

  List<Module> get modules => [
    for (final m in Module.values)
      if (m.course == this) m,
  ];

  String title(BuildContext context) {
    final l10n = context.l10n;
    return switch (this) {
      Course.ja => l10n.course_ja,
      Course.en => l10n.course_en,
      Course.ko => l10n.course_ko,
      Course.zh => l10n.course_zh,
    };
  }
}

/// Nhóm học phần ở màn Khoá học (thứ tự = thứ tự hiển thị).
enum ModuleSection {
  alphabet,
  kanji,
  pronunciation,
  vocabulary,
  grammar;

  String title(BuildContext context) {
    final l10n = context.l10n;
    return switch (this) {
      ModuleSection.alphabet => l10n.learn_alphabet,
      ModuleSection.kanji => l10n.learn_kanji,
      ModuleSection.pronunciation => l10n.learn_pronunciation,
      ModuleSection.vocabulary => l10n.learn_vocabulary,
      ModuleSection.grammar => l10n.learn_grammar,
    };
  }
}

/// Học phần trong 1 khoá. [glyph] = chữ đại diện trên thẻ.
enum Module {
  hiragana(Course.ja, ModuleSection.alphabet, 'あ', AppPalette.hiragana),
  katakana(Course.ja, ModuleSection.alphabet, 'ア', AppPalette.katakana),
  kanjiN5(
    Course.ja,
    ModuleSection.kanji,
    '日',
    AppPalette.kanjiN5,
    JlptLevel.n5,
  ),
  kanjiN4(
    Course.ja,
    ModuleSection.kanji,
    '会',
    AppPalette.kanjiN4,
    JlptLevel.n4,
  ),
  kanjiN3(
    Course.ja,
    ModuleSection.kanji,
    '働',
    AppPalette.kanjiN3,
    JlptLevel.n3,
  ),
  kanjiN2(
    Course.ja,
    ModuleSection.kanji,
    '議',
    AppPalette.kanjiN2,
    JlptLevel.n2,
  ),
  enPronunciation(
    Course.en,
    ModuleSection.pronunciation,
    'ə',
    AppPalette.enPronunciation,
  ),
  enVocabulary(
    Course.en,
    ModuleSection.vocabulary,
    'Aa',
    AppPalette.enVocabulary,
  ),
  enPhrases(Course.en, ModuleSection.vocabulary, '💬', AppPalette.enPhrases),
  enDialogues(
    Course.en,
    ModuleSection.vocabulary,
    '🗣️',
    AppPalette.enDialogues,
  ),
  enGrammar(Course.en, ModuleSection.grammar, '✍️', AppPalette.enGrammar);

  const Module(
    this.course,
    this.section,
    this.glyph,
    this.color, [
    this.kanjiLevel,
  ]);

  final Course course;
  final ModuleSection section;
  final String glyph;
  final Color color;

  /// Có giá trị = học phần Kanji của cấp này.
  final JlptLevel? kanjiLevel;

  bool get isKanji => kanjiLevel != null;

  bool get isKana => this == Module.hiragana || this == Module.katakana;

  /// Ngôn ngữ giọng đọc phát âm của học phần.
  String get speechLanguage => course == Course.en ? 'en-US' : 'ja-JP';

  String title(BuildContext context) {
    final l10n = context.l10n;
    return switch (this) {
      Module.hiragana => l10n.module_hiragana,
      Module.katakana => l10n.module_katakana,
      Module.enPronunciation => l10n.module_enPronunciation,
      Module.enVocabulary => l10n.module_enVocabulary,
      Module.enPhrases => l10n.module_enPhrases,
      Module.enDialogues => l10n.module_enDialogues,
      Module.enGrammar => l10n.module_enGrammar,
      _ => l10n.module_kanji(kanjiLevel!.label),
    };
  }

  String description(BuildContext context, int total) {
    final l10n = context.l10n;
    return switch (this) {
      Module.hiragana => l10n.module_hiragana_desc,
      Module.katakana => l10n.module_katakana_desc,
      Module.enPronunciation => l10n.module_enPronunciation_desc(total),
      Module.enVocabulary => l10n.module_enVocabulary_desc(total),
      Module.enPhrases => l10n.module_enPhrases_desc(total),
      Module.enDialogues => l10n.module_enDialogues_desc(total),
      Module.enGrammar => l10n.module_enGrammar_desc(total),
      _ => l10n.module_kanji_desc(total),
    };
  }
}
