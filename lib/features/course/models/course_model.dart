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

  /// Thư mục nội dung trong `assets/`.
  String get assetDir => switch (this) {
    Course.ja => 'japanese',
    Course.en => 'english',
    Course.ko => 'korean',
    Course.zh => 'chinese',
  };

  /// Giọng đọc (Text-to-Speech).
  String get speechLanguage => switch (this) {
    Course.ja => 'ja-JP',
    Course.en => 'en-US',
    Course.ko => 'ko-KR',
    Course.zh => 'zh-CN',
  };

  /// Ngôn ngữ nhận giọng nói (luyện nói).
  String get speechLocaleId => speechLanguage.replaceAll('-', '_');

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

/// Loại bài học dùng chung cho mọi khoá (màn + dữ liệu cùng định dạng).
enum LessonKind { vocabulary, phrases, dialogues, grammar }

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
  jaVocabulary(Course.ja, ModuleSection.vocabulary, '語', AppPalette.vocabulary),
  jaPhrases(Course.ja, ModuleSection.vocabulary, '💬', AppPalette.phrases),
  jaDialogues(Course.ja, ModuleSection.vocabulary, '🗣️', AppPalette.dialogues),
  jaGrammar(Course.ja, ModuleSection.grammar, '✍️', AppPalette.grammar),
  enPronunciation(
    Course.en,
    ModuleSection.pronunciation,
    'ə',
    AppPalette.pronunciation,
  ),
  enVocabulary(
    Course.en,
    ModuleSection.vocabulary,
    'Aa',
    AppPalette.vocabulary,
  ),
  enPhrases(Course.en, ModuleSection.vocabulary, '💬', AppPalette.phrases),
  enDialogues(Course.en, ModuleSection.vocabulary, '🗣️', AppPalette.dialogues),
  enGrammar(Course.en, ModuleSection.grammar, '✍️', AppPalette.grammar),
  enIrregularVerbs(
    Course.en,
    ModuleSection.grammar,
    'V3',
    AppPalette.irregularVerbs,
  );

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
  String get speechLanguage => course.speechLanguage;

  /// Loại bài học dùng chung (từ vựng, câu, hội thoại, ngữ pháp); khác → `null`.
  LessonKind? get lessonKind => switch (this) {
    Module.enVocabulary || Module.jaVocabulary => LessonKind.vocabulary,
    Module.enPhrases || Module.jaPhrases => LessonKind.phrases,
    Module.enDialogues || Module.jaDialogues => LessonKind.dialogues,
    Module.enGrammar || Module.jaGrammar => LessonKind.grammar,
    _ => null,
  };

  /// Học phần [kind] của [course] (`null` nếu khoá chưa có).
  static Module? lesson(Course course, LessonKind kind) => Module.values
      .where((m) => m.course == course && m.lessonKind == kind)
      .firstOrNull;

  String title(BuildContext context) {
    final l10n = context.l10n;
    return switch (this) {
      Module.hiragana => l10n.module_hiragana,
      Module.katakana => l10n.module_katakana,
      Module.enPronunciation => l10n.module_enPronunciation,
      Module.enVocabulary || Module.jaVocabulary => l10n.module_enVocabulary,
      Module.enPhrases || Module.jaPhrases => l10n.module_enPhrases,
      Module.enDialogues || Module.jaDialogues => l10n.module_enDialogues,
      Module.enGrammar || Module.jaGrammar => l10n.module_enGrammar,
      Module.enIrregularVerbs => l10n.module_enIrregularVerbs,
      _ => l10n.module_kanji(kanjiLevel!.label),
    };
  }

  String description(BuildContext context, int total) {
    final l10n = context.l10n;
    return switch (this) {
      Module.hiragana => l10n.module_hiragana_desc,
      Module.katakana => l10n.module_katakana_desc,
      Module.enPronunciation => l10n.module_enPronunciation_desc(total),
      Module.enVocabulary ||
      Module.jaVocabulary => l10n.module_enVocabulary_desc(total),
      Module.enPhrases || Module.jaPhrases => l10n.module_enPhrases_desc(total),
      Module.enDialogues ||
      Module.jaDialogues => l10n.module_enDialogues_desc(total),
      Module.enGrammar => l10n.module_enGrammar_desc(total),
      Module.jaGrammar => l10n.module_jaGrammar_desc(total),
      Module.enIrregularVerbs => l10n.module_enIrregularVerbs_desc(total),
      _ => l10n.module_kanji_desc(total),
    };
  }
}
