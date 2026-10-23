import 'dart:math';

import 'package:lingua/design/l10n/locale_notifier.dart';
import 'package:lingua/features/course/models/course_model.dart';
import 'package:lingua/features/course/providers/learner_notifier.dart';
import 'package:lingua/features/english/providers/english_provider.dart';
import 'package:lingua/features/japanese/models/kana_model.dart';
import 'package:lingua/features/japanese/providers/kanji_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'quiz_session_notifier.g.dart';

/// Hỏi gì về chữ / từ / câu.
enum QuizMode {
  /// Kana: chữ → cách đọc.
  reading,

  /// Kanji: chữ → âm Hán Việt.
  hanViet,

  /// Chữ / từ / câu → nghĩa.
  meaning,

  /// Nghe đọc → chọn từ đúng (không hiện chữ).
  listening,
}

/// Chủ đề bài luyện: 1 học phần (hoặc Kana tổng hợp khi [module] = null).
class QuizTopic {
  const QuizTopic(
    this.module,
    this.mode, {
    this.kanaSet = KanaSet.all,
    this.group,
  }) : review = null;

  /// Hiragana + Katakana.
  const QuizTopic.kanaMix({this.kanaSet = KanaSet.all})
    : module = null,
      mode = QuizMode.reading,
      group = null,
      review = null;

  /// Ôn tập: các mục tới hạn ôn của [review] (lặp lại ngắt quãng).
  const QuizTopic.review(Course this.review)
    : module = null,
      mode = QuizMode.meaning,
      kanaSet = KanaSet.all,
      group = null;

  final Module? module;
  final QuizMode mode;

  /// Bài Kana: luyện âm cơ bản / âm đục / cả hai.
  final KanaSet kanaSet;

  /// Bài Tiếng Anh: chỉ 1 chủ đề / tình huống (`null` = tất cả).
  final String? group;

  /// Khác `null` = bài ôn tập của khoá học này.
  final Course? review;

  /// Bài "Ôn nhanh 10 câu" của học phần (Trang chủ, phím tắt icon app).
  static QuizTopic quickReview(Module module) => switch (module) {
    Module.hiragana || Module.katakana => QuizTopic(module, QuizMode.reading),
    Module.enPronunciation ||
    Module.enVocabulary ||
    Module.enGrammar ||
    Module.enDialogues => const QuizTopic(
      Module.enVocabulary,
      QuizMode.meaning,
    ),
    _ => QuizTopic(module, QuizMode.meaning),
  };

  @override
  bool operator ==(Object other) =>
      other is QuizTopic &&
      other.module == module &&
      other.mode == mode &&
      other.kanaSet == kanaSet &&
      other.group == group &&
      other.review == review;

  @override
  int get hashCode => Object.hash(module, mode, kanaSet, group, review);
}

/// 1 mục trong bài: [char] = chữ / từ / câu hỏi, [answer] = đáp án đúng.
/// [group] = nhóm đáp án nhiễu (cùng bảng chữ / cùng chủ đề) — đáp án sai luôn cùng nhóm.
class QuizItem {
  const QuizItem({
    required this.char,
    required this.key,
    required this.answer,
    required this.group,
    required this.module,
    required this.speech,
  });

  final String char;

  /// Khoá tiến độ / lịch ôn (giống khoá "đã thuộc").
  final String key;
  final String answer;
  final String group;

  /// Học phần chứa mục này (để mở màn chi tiết, chọn giọng đọc).
  final Module module;

  /// Nội dung đọc phát âm (Kana: chữ; Kanji: âm On/Kun; Tiếng Anh: từ / câu).
  final String speech;

  @override
  bool operator ==(Object other) =>
      other is QuizItem && other.char == char && other.module == module;

  @override
  int get hashCode => Object.hash(char, module);
}

class QuizQuestion {
  const QuizQuestion(this.item, this.options);

  final QuizItem item;

  /// 4 đáp án A–D, có [item], nhãn (`answer`) không trùng nhau.
  final List<QuizItem> options;
}

class QuizSession {
  const QuizSession({
    required this.questions,
    this.index = 0,
    this.picks = const [],
    this.isFinished = false,
  });

  final List<QuizQuestion> questions;
  final int index;

  /// Đáp án đã chọn của các câu đã trả lời (theo thứ tự).
  final List<QuizItem> picks;

  QuizQuestion get current => questions[index];
  bool get isAnswered => picks.length > index;
  QuizItem? get picked => isAnswered ? picks[index] : null;
  bool get isLast => index == questions.length - 1;

  /// Đã bấm "Xem kết quả" ở câu cuối.
  final bool isFinished;
  int get correctCount => [
    for (var i = 0; i < picks.length; i++) picks[i] == questions[i].item,
  ].where((ok) => ok).length;

  /// Các câu trả lời sai (để ôn lại ở màn kết quả).
  List<QuizItem> get mistakes => [
    for (var i = 0; i < picks.length; i++)
      if (picks[i] != questions[i].item) questions[i].item,
  ];
}

/// Mọi mục có thể hỏi của [topic] (tải dữ liệu cần thiết: Kanji / từ vựng / câu).
/// Bài ôn tập: mọi mục của khoá học — phiên bài chỉ lấy câu hỏi từ các mục tới hạn ôn.
@riverpod
Future<List<QuizItem>> quizPool(Ref ref, QuizTopic topic) async {
  final language = ref.watch(localeProvider).languageCode;

  List<QuizItem> kana(List<KanaScript> scripts, KanaSet set) => [
    for (final s in scripts)
      for (final k in KanaTable.of(s, set))
        QuizItem(
          char: k.char,
          key: k.char,
          answer: k.romaji,
          group: k.script.name,
          module: s == KanaScript.hiragana ? Module.hiragana : Module.katakana,
          speech: k.char,
        ),
  ];

  Future<List<QuizItem>> kanji(Module m, QuizMode mode) async => [
    for (final k in await ref.watch(kanjiListProvider.future))
      if (k.level == m.kanjiLevel)
        QuizItem(
          char: k.char,
          key: k.char,
          answer: mode == QuizMode.hanViet ? k.hanViet : k.meaningFor(language),
          group: m.name,
          module: m,
          speech: k.speech,
        ),
  ];

  Future<List<QuizItem>> words(QuizMode mode, String? group) async => [
    for (final t in await ref.watch(vocabTopicsProvider.future))
      if (group == null || group == t.id)
        for (final w in t.items)
          QuizItem(
            char: w.word,
            key: w.key,
            answer: mode == QuizMode.listening ? w.word : w.meaning,
            group: t.id,
            module: Module.enVocabulary,
            speech: w.word,
          ),
  ];

  Future<List<QuizItem>> phrases(String? group) async => [
    for (final t in await ref.watch(phraseTopicsProvider.future))
      if (group == null || group == t.id)
        for (final p in t.items)
          QuizItem(
            char: p.text,
            key: p.key,
            answer: p.meaning,
            group: t.id,
            module: Module.enPhrases,
            speech: p.text,
          ),
  ];

  if (topic.review case final course?) {
    return switch (course) {
      Course.en => [
        ...await words(QuizMode.meaning, null),
        ...await phrases(null),
      ],
      _ => [
        ...kana(KanaScript.values, KanaSet.all),
        for (final m in course.modules.where((m) => m.isKanji))
          ...await kanji(
            m,
            language == 'vi' ? QuizMode.hanViet : QuizMode.meaning,
          ),
      ],
    };
  }

  return switch (topic.module) {
    null => kana(KanaScript.values, topic.kanaSet),
    Module.hiragana => kana([KanaScript.hiragana], topic.kanaSet),
    Module.katakana => kana([KanaScript.katakana], topic.kanaSet),
    Module.enPronunciation ||
    Module.enVocabulary => await words(topic.mode, topic.group),
    Module.enPhrases => await phrases(topic.group),
    final Module m => await kanji(m, topic.mode),
  };
}

/// 1 bài luyện [length] câu. Chỉ tạo sau khi [quizPoolProvider] đã tải xong (trang chờ bằng AsyncView).
@riverpod
class QuizSessionNotifier extends _$QuizSessionNotifier {
  static const length = 10;
  final _random = Random();

  @override
  QuizSession build(QuizTopic topic) => _newSession();

  void answer(QuizItem option) {
    if (state.isAnswered) return;
    final ok = option == state.current.item;
    state = QuizSession(
      questions: state.questions,
      index: state.index,
      picks: [...state.picks, option],
    );
    ref
        .read(learnerProvider.notifier)
        .recordAnswer(correct: ok, key: state.current.item.key);
  }

  /// Câu tiếp theo; ở câu cuối → kết thúc bài (màn kết quả).
  void next() {
    if (!state.isAnswered) return;
    state = QuizSession(
      questions: state.questions,
      index: state.isLast ? state.index : state.index + 1,
      picks: state.picks,
      isFinished: state.isLast,
    );
  }

  void restart() => state = _newSession();

  QuizSession _newSession() {
    final pool = ref.read(quizPoolProvider(topic)).requireValue;
    // Ôn tập: chỉ hỏi mục tới hạn (có thể ít hơn [length], hoặc 0 khi đã ôn hết).
    final candidates = switch (topic.review) {
      final course? => () {
        final due = ref.read(learnerProvider.notifier).dueKeys(course).toSet();
        return pool.where((i) => due.contains(i.key)).toList();
      }(),
      null => pool.toList(),
    };
    final chosen = (candidates..shuffle(_random)).take(length).toList();
    return QuizSession(
      questions: [
        for (final item in chosen) QuizQuestion(item, _options(item, pool)),
      ],
    );
  }

  List<QuizItem> _options(QuizItem item, List<QuizItem> pool) {
    final seen = {item.answer};
    final others = [
      for (final o
          in pool
              .where((o) => o.group == item.group && o.module == item.module)
              .toList()
            ..shuffle(_random))
        if (seen.add(o.answer)) o,
    ].take(3);
    return [item, ...others]..shuffle(_random);
  }
}
