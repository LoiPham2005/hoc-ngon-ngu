import 'package:lingua/features/course/models/course_model.dart';
import 'package:lingua/modules/analytics/analytics_service.dart';

/// Sự kiện mốc học tập (Firebase Analytics) — đủ để dựng phễu "chọn khoá → luyện tập → đạt
/// mục tiêu ngày" và xem người dùng rơi rụng ở bước nào (Explore → Funnel exploration).
/// Màn hình đã tự ghi (`AnalyticsRouteObserver`), ở đây chỉ ghi việc người dùng LÀM XONG.
extension LearningEvents on AnalyticsService {
  /// Chọn / đổi khoá học ([first] = lần đầu, tức xong onboarding).
  Future<void> courseSelected(Course course, {required bool first}) => logEvent(
    'course_selected',
    {'course': course.name, 'first': first ? 1 : 0},
  );

  /// Làm xong 1 lượt luyện tập / bài tập.
  /// [type]: quiz, review, lesson_exercise, minimal_pairs, sentence_practice, irregular_verbs.
  Future<void> practiceCompleted(
    String type, {
    required int total,
    required int correct,
    String? topic,
  }) => logEvent('practice_completed', {
    'type': type,
    'topic': topic,
    'total': total,
    'correct': correct,
    'accuracy': total == 0 ? 0 : (correct * 100 / total).round(),
  });

  /// Hôm nay vừa đạt mục tiêu số lượt học.
  Future<void> dailyGoalReached({required int goal, required int streak}) =>
      logEvent('daily_goal_reached', {'goal': goal, 'streak': streak});
}
