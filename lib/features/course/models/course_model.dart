import 'package:flutter/widgets.dart';
import 'package:lingua/design/l10n/l10n_extensions.dart';
import 'package:lingua/design/theme/app_palette.dart';
import 'package:lingua/features/japanese/models/kanji_model.dart';

/// Ngôn ngữ có thể học. Thêm ngôn ngữ mới: thêm 1 giá trị + học phần ở [Module] + tên ở ARB `course_<id>`.
enum Course {
  ja('🇯🇵', available: true),
  en('🇬🇧'),
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

/// Học phần trong 1 khoá. [glyph] = chữ đại diện trên thẻ.
enum Module {
  hiragana(Course.ja, 'あ', AppPalette.hiragana),
  katakana(Course.ja, 'ア', AppPalette.katakana),
  kanjiN5(Course.ja, '日', AppPalette.kanjiN5, JlptLevel.n5),
  kanjiN4(Course.ja, '会', AppPalette.kanjiN4, JlptLevel.n4),
  kanjiN3(Course.ja, '働', AppPalette.kanjiN3, JlptLevel.n3),
  kanjiN2(Course.ja, '議', AppPalette.kanjiN2, JlptLevel.n2);

  const Module(this.course, this.glyph, this.color, [this.kanjiLevel]);

  final Course course;
  final String glyph;
  final Color color;

  /// Có giá trị = học phần Kanji của cấp này.
  final JlptLevel? kanjiLevel;

  bool get isKanji => kanjiLevel != null;

  String title(BuildContext context) {
    final l10n = context.l10n;
    return switch (this) {
      Module.hiragana => l10n.module_hiragana,
      Module.katakana => l10n.module_katakana,
      _ => l10n.module_kanji(kanjiLevel!.label),
    };
  }

  String description(BuildContext context, int total) {
    final l10n = context.l10n;
    return switch (this) {
      Module.hiragana => l10n.module_hiragana_desc,
      Module.katakana => l10n.module_katakana_desc,
      _ => l10n.module_kanji_desc(total),
    };
  }
}
