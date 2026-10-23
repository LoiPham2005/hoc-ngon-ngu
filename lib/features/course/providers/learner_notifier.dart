import 'dart:convert';
import 'dart:math';

import 'package:lingua/core/di/global_providers.dart';
import 'package:lingua/features/course/models/course_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'learner_notifier.g.dart';

/// Lịch ôn 1 mục (lặp lại ngắt quãng): [box] = số lần ôn đúng liên tiếp, [due] = ngày cần ôn (yyyy-MM-dd).
class Review {
  const Review(this.box, this.due);

  /// Khoảng cách ôn (ngày) theo [box]: đúng càng nhiều lần → càng lâu mới phải ôn lại.
  static const intervals = [1, 3, 7, 14, 30, 60, 120];

  final int box;
  final String due;

  /// Đã ôn đúng đủ nhiều lần → coi như nhớ lâu.
  bool get isMastered => box >= 4;

  List<Object> toJson() => [box, due];

  static Review fromJson(Object? json) {
    final [box, due] = json! as List;
    return Review(box as int, due as String);
  }
}

/// Mục có lịch ôn: chữ Kana/Kanji, từ, câu. Âm IPA, bài ngữ pháp, hội thoại không ôn bằng câu hỏi nên bỏ.
bool isReviewable(String key) =>
    !key.startsWith('en:ph:') &&
    !key.startsWith('en:g:') &&
    !key.startsWith('en:d:');

/// Khoá học của 1 mục: Tiếng Anh có tiền tố `en:`, còn lại là Tiếng Nhật.
Course courseOfKey(String key) => key.startsWith('en:') ? Course.en : Course.ja;

/// Hồ sơ người học — lưu trên máy (không cần tài khoản).
class Learner {
  const Learner({
    this.course,
    this.dailyGoal = 10,
    this.learned = const {},
    this.answered = 0,
    this.correct = 0,
    this.streak = 0,
    this.lastActiveDay,
    this.todayCount = 0,
    this.lastModule,
    this.reviews = const {},
  });

  factory Learner.fromJson(Map<String, dynamic> json) {
    final learned = {...(json['learned'] as List? ?? const []).cast<String>()};
    final reviews = json['reviews'] as Map<String, dynamic>?;
    return Learner._fromJson(
      json,
      learned,
      reviews == null
          // Bản cũ chưa có lịch ôn → mục đã thuộc cần ôn ngay ('' < mọi ngày).
          ? {
              for (final k in learned)
                if (isReviewable(k)) k: const Review(0, ''),
            }
          : reviews.map((k, v) => MapEntry(k, Review.fromJson(v))),
    );
  }

  factory Learner._fromJson(
    Map<String, dynamic> json,
    Set<String> learned,
    Map<String, Review> reviews,
  ) => Learner(
    course: Course.values.asNameMap()[json['course']],
    dailyGoal: json['dailyGoal'] as int? ?? 10,
    learned: learned,
    reviews: reviews,
    answered: json['answered'] as int? ?? 0,
    correct: json['correct'] as int? ?? 0,
    streak: json['streak'] as int? ?? 0,
    lastActiveDay: json['lastActiveDay'] as String?,
    todayCount: json['todayCount'] as int? ?? 0,
    lastModule: Module.values.asNameMap()[json['lastModule']],
  );

  /// `null` = chưa qua onboarding.
  final Course? course;

  /// Số lượt học mỗi ngày (1 câu trả lời / 1 chữ đánh dấu thuộc = 1 lượt).
  final int dailyGoal;

  /// Các chữ đã đánh dấu thuộc.
  final Set<String> learned;
  final int answered;
  final int correct;
  final int streak;

  /// Ngày có học gần nhất, dạng yyyy-MM-dd.
  final String? lastActiveDay;

  /// Số lượt học của [lastActiveDay].
  final int todayCount;
  final Module? lastModule;

  /// Lịch ôn theo khoá mục (cùng khoá với [learned]). Mục trả lời sai cũng được thêm vào.
  final Map<String, Review> reviews;

  double get accuracy => answered == 0 ? 0 : correct / answered;

  Map<String, dynamic> toJson() => {
    'course': course?.name,
    'dailyGoal': dailyGoal,
    'learned': learned.toList(),
    'answered': answered,
    'correct': correct,
    'streak': streak,
    'lastActiveDay': lastActiveDay,
    'todayCount': todayCount,
    'lastModule': lastModule?.name,
    'reviews': reviews.map((k, v) => MapEntry(k, v.toJson())),
  };

  Learner copyWith({
    Course? course,
    int? dailyGoal,
    Set<String>? learned,
    int? answered,
    int? correct,
    int? streak,
    String? lastActiveDay,
    int? todayCount,
    Module? lastModule,
    Map<String, Review>? reviews,
  }) => Learner(
    course: course ?? this.course,
    dailyGoal: dailyGoal ?? this.dailyGoal,
    learned: learned ?? this.learned,
    answered: answered ?? this.answered,
    correct: correct ?? this.correct,
    streak: streak ?? this.streak,
    lastActiveDay: lastActiveDay ?? this.lastActiveDay,
    todayCount: todayCount ?? this.todayCount,
    lastModule: lastModule ?? this.lastModule,
    reviews: reviews ?? this.reviews,
  );
}

String _day(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

@Riverpod(keepAlive: true)
class LearnerNotifier extends _$LearnerNotifier {
  static const _key = 'learner_v1';

  /// Đồng hồ — test thay để giả lập qua ngày.
  DateTime Function() now = DateTime.now;

  @override
  Learner build() {
    final raw = ref.read(sharedPrefsProvider).getString(_key);
    if (raw == null) return const Learner();
    try {
      return Learner.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on Object {
      return const Learner();
    }
  }

  String get _today => _day(now());

  /// Chuỗi ngày đang giữ được: học hôm nay hoặc hôm qua mới còn tính.
  int get currentStreak {
    final last = state.lastActiveDay;
    final yesterday = _day(now().subtract(const Duration(days: 1)));
    return last == _today || last == yesterday ? state.streak : 0;
  }

  String _inDays(int days) {
    final d = now();
    return _day(DateTime(d.year, d.month, d.day + days));
  }

  /// Mục cần ôn hôm nay của [course] (đã tới hạn hoặc quá hạn).
  List<String> dueKeys(Course course) => [
    for (final MapEntry(:key, :value) in state.reviews.entries)
      if (value.due.compareTo(_today) <= 0 && courseOfKey(key) == course) key,
  ];

  /// Lượt học hôm nay (sang ngày mới → 0).
  int get todayCount => state.lastActiveDay == _today ? state.todayCount : 0;

  Future<void> chooseCourse(Course course) =>
      _save(state.copyWith(course: course));

  Future<void> setDailyGoal(int goal) => _save(state.copyWith(dailyGoal: goal));

  Future<void> openModule(Module module) =>
      _save(state.copyWith(lastModule: module));

  /// Bật/tắt "đã thuộc". Thuộc → lên lịch ôn từ ngày mai; bỏ thuộc → bỏ lịch ôn.
  Future<void> toggleLearned(String char) {
    final learned = {...state.learned};
    final reviews = {...state.reviews};
    final added = learned.add(char);
    if (added) {
      if (isReviewable(char)) {
        reviews.putIfAbsent(
          char,
          () => Review(0, _inDays(Review.intervals[0])),
        );
      }
    } else {
      learned.remove(char);
      reviews.remove(char);
    }
    final next = state.copyWith(learned: learned, reviews: reviews);
    return _save(added ? _withActivity(next) : next);
  }

  /// Đánh dấu đã thuộc (không bỏ đánh dấu nếu đã có) — dùng khi làm bài đạt.
  Future<void> markLearned(String key) async {
    if (!state.learned.contains(key)) await toggleLearned(key);
  }

  /// Ghi 1 câu trả lời. Có [key] → cập nhật lịch ôn:
  /// sai → ôn lại từ ngày mai (kể cả mục chưa học); đúng lúc tới hạn → lên hộp, giãn lịch.
  /// Đúng khi chưa tới hạn thì giữ lịch (tránh "học dồn" làm lịch giãn quá sớm).
  Future<void> recordAnswer({required bool correct, String? key}) {
    final reviews = {...state.reviews};
    final card = reviews[key];
    if (key != null && isReviewable(key)) {
      if (!correct) {
        reviews[key] = Review(0, _inDays(Review.intervals[0]));
      } else if (card != null && card.due.compareTo(_today) <= 0) {
        final box = card.box + 1;
        reviews[key] = Review(
          box,
          _inDays(Review.intervals[min(box, Review.intervals.length - 1)]),
        );
      }
    }
    return _save(
      _withActivity(
        state.copyWith(
          answered: state.answered + 1,
          correct: state.correct + (correct ? 1 : 0),
          reviews: reviews,
        ),
      ),
    );
  }

  /// Xoá tiến độ, giữ khoá học + mục tiêu đã chọn.
  Future<void> resetProgress() =>
      _save(Learner(course: state.course, dailyGoal: state.dailyGoal));

  /// +1 lượt hôm nay; ngày đầu tiên học trong ngày → cập nhật chuỗi ngày.
  Learner _withActivity(Learner l) {
    final today = _today;
    if (l.lastActiveDay == today) {
      return l.copyWith(todayCount: l.todayCount + 1);
    }
    final yesterday = _day(now().subtract(const Duration(days: 1)));
    return l.copyWith(
      lastActiveDay: today,
      todayCount: 1,
      streak: l.lastActiveDay == yesterday ? l.streak + 1 : 1,
    );
  }

  Future<void> _save(Learner next) async {
    state = next;
    await ref
        .read(sharedPrefsProvider)
        .setString(_key, jsonEncode(next.toJson()));
  }
}
