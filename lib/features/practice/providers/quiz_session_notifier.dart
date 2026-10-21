import 'dart:math';

import 'package:lingua/design/l10n/locale_notifier.dart';
import 'package:lingua/features/course/models/course_model.dart';
import 'package:lingua/features/course/providers/learner_notifier.dart';
import 'package:lingua/features/japanese/models/kana_model.dart';
import 'package:lingua/features/japanese/providers/kanji_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'quiz_session_notifier.g.dart';

/// Hỏi gì về chữ.
enum QuizMode { reading, hanViet, meaning }

/// Chủ đề bài luyện: 1 học phần, hoặc Kana tổng hợp ([module] = null).
class QuizTopic {
  const QuizTopic(this.module, this.mode);

  /// Hiragana + Katakana.
  const QuizTopic.kanaMix() : module = null, mode = QuizMode.reading;

  final Module? module;
  final QuizMode mode;

  @override
  bool operator ==(Object other) =>
      other is QuizTopic && other.module == module && other.mode == mode;

  @override
  int get hashCode => Object.hash(module, mode);
}

/// 1 chữ trong bài: [char] hỏi, [answer] đáp án đúng.
/// [group] = nhóm đáp án nhiễu (Hiragana chỉ lẫn với Hiragana…).
class QuizItem {
  const QuizItem({
    required this.char,
    required this.answer,
    required this.group,
  });

  final String char;
  final String answer;
  final String group;

  @override
  bool operator ==(Object other) => other is QuizItem && other.char == char;

  @override
  int get hashCode => char.hashCode;
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

/// 1 bài luyện [length] câu. Chỉ tạo sau khi dữ liệu Kanji đã tải (trang chờ `kanjiListProvider`).
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
    ref.read(learnerProvider.notifier).recordAnswer(correct: ok);
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
    final pool = _items();
    final chosen = (pool.toList()..shuffle(_random)).take(length).toList();
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
          in pool.where((o) => o.group == item.group).toList()
            ..shuffle(_random))
        if (seen.add(o.answer)) o,
    ].take(3);
    return [item, ...others]..shuffle(_random);
  }

  List<QuizItem> _items() {
    QuizItem kana(Kana k) =>
        QuizItem(char: k.char, answer: k.romaji, group: k.script.name);
    final module = topic.module;
    if (module == null || !module.isKanji) {
      final scripts = switch (module) {
        Module.hiragana => [KanaScript.hiragana],
        Module.katakana => [KanaScript.katakana],
        _ => KanaScript.values,
      };
      return [
        for (final s in scripts)
          for (final k in KanaTable.all(s, withDakuten: true)) kana(k),
      ];
    }
    final language = ref.read(localeProvider).languageCode;
    return [
      for (final k in ref.read(kanjiListProvider).requireValue)
        if (k.level == module.kanjiLevel)
          QuizItem(
            char: k.char,
            answer: topic.mode == QuizMode.hanViet
                ? k.hanViet
                : k.meaningFor(language),
            group: module.name,
          ),
    ];
  }
}
