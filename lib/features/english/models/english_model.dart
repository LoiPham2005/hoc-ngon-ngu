// Dữ liệu khoá Tiếng Anh: chủ đề từ vựng / tình huống giao tiếp, từ, câu, âm IPA.
// Nội dung: `assets/english/{vocabulary,phrases,grammar}.json` (soạn riêng cho app).

/// 1 chủ đề (từ vựng) hoặc 1 tình huống (câu giao tiếp), chứa danh sách [items].
class Topic<T> {
  const Topic({
    required this.id,
    required this.emoji,
    required this.nameVi,
    required this.nameEn,
    required this.items,
  });

  final String id;
  final String emoji;
  final String nameVi;
  final String nameEn;
  final List<T> items;

  String name(String languageCode) => languageCode == 'vi' ? nameVi : nameEn;
}

class Word {
  const Word({
    required this.word,
    required this.pos,
    required this.ipa,
    required this.meaning,
    required this.example,
    required this.exampleVi,
    required this.topicId,
  });

  factory Word.fromJson(Map<String, dynamic> json, String topicId) => Word(
    word: json['w'] as String,
    pos: json['pos'] as String,
    ipa: json['ipa'] as String,
    meaning: json['vi'] as String,
    example: json['ex'] as String,
    exampleVi: json['ex_vi'] as String,
    topicId: topicId,
  );

  final String word;

  /// Loại từ viết tắt: n, v, adj, adv, num, prep, pron.
  final String pos;

  /// Phiên âm IPA giọng Mỹ, không có dấu `/`.
  final String ipa;
  final String meaning;
  final String example;
  final String exampleVi;
  final String topicId;

  /// Khoá lưu tiến độ "đã thuộc".
  String get key => 'en:w:$word';
}

class Phrase {
  const Phrase({
    required this.id,
    required this.text,
    required this.meaning,
    required this.topicId,
    this.note,
  });

  final String id;
  final String text;
  final String meaning;
  final String topicId;

  /// Ghi chú cách dùng (không bắt buộc).
  final String? note;

  String get key => 'en:p:$id';
}

/// 1 bài ngữ pháp: công thức, ghi nhớ, ví dụ và 10 bài tập (trắc nghiệm + ghép câu).
class GrammarLesson {
  const GrammarLesson({
    required this.id,
    required this.emoji,
    required this.nameVi,
    required this.nameEn,
    required this.level,
    required this.summary,
    required this.formulas,
    required this.points,
    required this.examples,
    required this.exercises,
  });

  factory GrammarLesson.fromJson(Map<String, dynamic> json) => GrammarLesson(
    id: json['id'] as String,
    emoji: json['emoji'] as String,
    nameVi: json['name_vi'] as String,
    nameEn: json['name_en'] as String,
    level: json['level'] as String,
    summary: json['summary'] as String,
    formulas: [
      for (final f in (json['formulas'] as List).cast<Map<String, dynamic>>())
        (label: f['label'] as String, pattern: f['pattern'] as String),
    ],
    points: (json['points'] as List).cast<String>(),
    examples: [
      for (final e in (json['examples'] as List).cast<Map<String, dynamic>>())
        (en: e['en'] as String, vi: e['vi'] as String),
    ],
    exercises: [
      for (final e in (json['exercises'] as List).cast<Map<String, dynamic>>())
        Exercise.fromJson(e),
    ],
  );

  final String id;
  final String emoji;
  final String nameVi;
  final String nameEn;

  /// Cấp CEFR: A1, A2, B1.
  final String level;
  final String summary;
  final List<({String label, String pattern})> formulas;
  final List<String> points;
  final List<({String en, String vi})> examples;
  final List<Exercise> exercises;

  String get key => 'en:g:$id';

  String name(String languageCode) => languageCode == 'vi' ? nameVi : nameEn;
}

sealed class Exercise {
  const Exercise();

  factory Exercise.fromJson(Map<String, dynamic> json) =>
      switch (json['type']) {
        'choice' => ChoiceExercise(
          prompt: json['prompt'] as String,
          options: (json['options'] as List).cast<String>(),
          answer: json['answer'] as int,
          explain: json['explain'] as String,
        ),
        _ => OrderExercise(
          answer: json['answer'] as String,
          meaning: json['vi'] as String,
        ),
      };
}

/// Điền vào chỗ trống `___`: chọn 1 trong 4 [options], [answer] = vị trí đáp án đúng.
class ChoiceExercise extends Exercise {
  const ChoiceExercise({
    required this.prompt,
    required this.options,
    required this.answer,
    required this.explain,
  });

  final String prompt;
  final List<String> options;
  final int answer;
  final String explain;
}

/// Ghép câu: xếp các từ của [answer] theo đúng thứ tự, gợi ý bằng nghĩa [meaning].
class OrderExercise extends Exercise {
  const OrderExercise({required this.answer, required this.meaning});

  final String answer;
  final String meaning;

  /// Dấu câu cuối (. ? !) — tách riêng để không lộ từ cuối câu.
  String get ending => RegExp(r'[.?!]$').stringMatch(answer) ?? '';

  /// Các từ của câu, bỏ dấu câu cuối.
  List<String> get words =>
      answer.substring(0, answer.length - ending.length).split(' ');
}

enum PhonemeKind { vowel, diphthong, consonant }

/// 1 âm trong bảng IPA. [tip] = mẹo đọc cho người Việt.
class Phoneme {
  const Phoneme(this.symbol, this.kind, this.example, this.tip);

  final String symbol;
  final PhonemeKind kind;

  /// Từ ví dụ — bấm để nghe (đọc riêng 1 âm bằng giọng máy không chuẩn).
  final String example;
  final String tip;

  String get key => 'en:ph:$symbol';
}

/// 44 âm tiếng Anh (bảng IPA chuẩn dạy ở Việt Nam).
const phonemes = <Phoneme>[
  // ── 12 nguyên âm đơn ─────────────────────────────────────────
  Phoneme('iː', PhonemeKind.vowel, 'see', '"i" kéo dài, môi bành sang hai bên'),
  Phoneme('ɪ', PhonemeKind.vowel, 'sit', '"i" ngắn, dứt khoát'),
  Phoneme('ʊ', PhonemeKind.vowel, 'book', '"u" ngắn, môi hơi tròn'),
  Phoneme('uː', PhonemeKind.vowel, 'food', '"u" kéo dài, môi tròn'),
  Phoneme('e', PhonemeKind.vowel, 'bed', '"e" ngắn, giữa "e" và "ê"'),
  Phoneme(
    'ə',
    PhonemeKind.vowel,
    'about',
    '"ơ" rất nhẹ, không nhấn — âm hay gặp nhất',
  ),
  Phoneme('ɜː', PhonemeKind.vowel, 'bird', '"ơ" kéo dài, lưỡi hơi cong lên'),
  Phoneme('ɔː', PhonemeKind.vowel, 'door', '"o" kéo dài, môi tròn'),
  Phoneme(
    'æ',
    PhonemeKind.vowel,
    'cat',
    'Giữa "a" và "e": mở miệng rộng, kéo khoé môi',
  ),
  Phoneme('ʌ', PhonemeKind.vowel, 'cup', '"ă" ngắn'),
  Phoneme('ɑː', PhonemeKind.vowel, 'car', '"a" kéo dài, miệng mở rộng'),
  Phoneme('ɒ', PhonemeKind.vowel, 'hot', '"o" ngắn (giọng Mỹ đọc gần "a")'),
  // ── 8 nguyên âm đôi ──────────────────────────────────────────
  Phoneme('ɪə', PhonemeKind.diphthong, 'ear', '"i" lướt sang "ơ": "ia"'),
  Phoneme('eə', PhonemeKind.diphthong, 'hair', '"e" lướt sang "ơ": "eơ"'),
  Phoneme('ʊə', PhonemeKind.diphthong, 'tour', '"u" lướt sang "ơ": "ua"'),
  Phoneme('eɪ', PhonemeKind.diphthong, 'day', '"ê" lướt sang "i": "ây"'),
  Phoneme('aɪ', PhonemeKind.diphthong, 'my', '"a" lướt sang "i": "ai"'),
  Phoneme('ɔɪ', PhonemeKind.diphthong, 'boy', '"o" lướt sang "i": "oi"'),
  Phoneme(
    'əʊ',
    PhonemeKind.diphthong,
    'go',
    '"ơ" lướt sang "u": "âu" (Mỹ: "ôu")',
  ),
  Phoneme('aʊ', PhonemeKind.diphthong, 'now', '"a" lướt sang "u": "ao"'),
  // ── 24 phụ âm ────────────────────────────────────────────────
  Phoneme(
    'p',
    PhonemeKind.consonant,
    'pen',
    'Bật hơi mạnh (khác "p" tiếng Việt)',
  ),
  Phoneme('b', PhonemeKind.consonant, 'bag', 'Như "b", hai môi mím rồi bật'),
  Phoneme(
    't',
    PhonemeKind.consonant,
    'tea',
    'Bật hơi, đầu lưỡi chạm lợi trên (giống "th" nhẹ)',
  ),
  Phoneme('d', PhonemeKind.consonant, 'dog', 'Như "đ", đầu lưỡi chạm lợi trên'),
  Phoneme('k', PhonemeKind.consonant, 'key', 'Bật hơi mạnh, như "kh" nhẹ'),
  Phoneme('ɡ', PhonemeKind.consonant, 'go', 'Như "g" trong "gà"'),
  Phoneme(
    'f',
    PhonemeKind.consonant,
    'fish',
    'Như "ph": răng trên chạm môi dưới',
  ),
  Phoneme(
    'v',
    PhonemeKind.consonant,
    'van',
    'Như "v": răng trên chạm môi dưới, rung cổ',
  ),
  Phoneme(
    'θ',
    PhonemeKind.consonant,
    'think',
    'Đầu lưỡi giữa hai răng, thổi hơi (không phải "th" Việt)',
  ),
  Phoneme('ð', PhonemeKind.consonant, 'this', 'Giống /θ/ nhưng rung dây thanh'),
  Phoneme('s', PhonemeKind.consonant, 'sun', '"x" nhẹ, đừng bỏ khi ở cuối từ'),
  Phoneme(
    'z',
    PhonemeKind.consonant,
    'zoo',
    'Như /s/ nhưng rung, giống "d" miền Bắc',
  ),
  Phoneme('ʃ', PhonemeKind.consonant, 'she', '"s" nặng, chu môi ra trước'),
  Phoneme('ʒ', PhonemeKind.consonant, 'vision', 'Như /ʃ/ nhưng rung dây thanh'),
  Phoneme('h', PhonemeKind.consonant, 'hat', 'Như "h", chỉ là hơi thở ra'),
  Phoneme('tʃ', PhonemeKind.consonant, 'chair', '"ch" bật hơi, chu môi'),
  Phoneme('dʒ', PhonemeKind.consonant, 'job', 'Như /tʃ/ nhưng rung, gần "gi"'),
  Phoneme('m', PhonemeKind.consonant, 'man', 'Như "m"'),
  Phoneme('n', PhonemeKind.consonant, 'no', 'Như "n"'),
  Phoneme('ŋ', PhonemeKind.consonant, 'sing', 'Như "ng" ở cuối từ'),
  Phoneme(
    'l',
    PhonemeKind.consonant,
    'leg',
    'Như "l"; ở cuối từ uốn lưỡi lên (feel)',
  ),
  Phoneme(
    'r',
    PhonemeKind.consonant,
    'red',
    'Cong lưỡi, không chạm vòm, không rung lưỡi',
  ),
  Phoneme('w', PhonemeKind.consonant, 'wet', '"u" lướt nhanh, môi tròn: "qu"'),
  Phoneme(
    'j',
    PhonemeKind.consonant,
    'yes',
    '"i" lướt nhanh, như "d" miền Nam',
  ),
];
