import 'dart:convert';

import 'package:lingua/core/di/global_providers.dart';
import 'package:lingua/features/course/models/course_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'learner_notifier.g.dart';

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
  });

  factory Learner.fromJson(Map<String, dynamic> json) => Learner(
    course: Course.values.asNameMap()[json['course']],
    dailyGoal: json['dailyGoal'] as int? ?? 10,
    learned: {...(json['learned'] as List? ?? const []).cast<String>()},
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

  /// Lượt học hôm nay (sang ngày mới → 0).
  int get todayCount => state.lastActiveDay == _today ? state.todayCount : 0;

  Future<void> chooseCourse(Course course) =>
      _save(state.copyWith(course: course));

  Future<void> setDailyGoal(int goal) => _save(state.copyWith(dailyGoal: goal));

  Future<void> openModule(Module module) =>
      _save(state.copyWith(lastModule: module));

  Future<void> toggleLearned(String char) {
    final learned = {...state.learned};
    final added = learned.add(char);
    if (!added) learned.remove(char);
    final next = state.copyWith(learned: learned);
    return _save(added ? _withActivity(next) : next);
  }

  /// Đánh dấu đã thuộc (không bỏ đánh dấu nếu đã có) — dùng khi làm bài đạt.
  Future<void> markLearned(String key) async {
    if (!state.learned.contains(key)) await toggleLearned(key);
  }

  Future<void> recordAnswer({required bool correct}) => _save(
    _withActivity(
      state.copyWith(
        answered: state.answered + 1,
        correct: state.correct + (correct ? 1 : 0),
      ),
    ),
  );

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
