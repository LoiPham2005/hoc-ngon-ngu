import 'package:lingua/core/di/global_providers.dart';
import 'package:lingua/design/l10n/locale_notifier.dart';
import 'package:lingua/features/course/providers/learner_notifier.dart';
import 'package:lingua/features/practice/providers/quiz_session_notifier.dart';
import 'package:lingua/gen/l10n/app_localizations.dart';
import 'package:lingua/routes/app_router.dart';
import 'package:quick_actions/quick_actions.dart';

/// App shortcut (nhấn giữ icon app): "Ôn tập hôm nay" (mục tới hạn) + "Ôn nhanh 10 câu" của học phần đang học.
/// Icon = tên drawable Android / imageset iOS.
abstract class AppQuickActions {
  static const _plugin = QuickActions();
  static const _review = 'quick_review';
  static const _due = 'due_review';

  /// Gọi 1 lần sau khi router sẵn sàng (frame đầu tiên).
  static Future<void> init() async {
    await _plugin.initialize((type) {
      final learner = globalContainer.read(learnerProvider);
      if (learner.course == null) return; // chưa qua onboarding
      final course = learner.course!;
      if (type == _due) {
        appRouter.push(QuizRoute(topic: QuizTopic.review(course)));
        return;
      }
      if (type != _review) return;
      final module = learner.lastModule?.course == course
          ? learner.lastModule!
          : course.modules.first;
      appRouter.push(QuizRoute(topic: QuizTopic.quickReview(module)));
    });
    await update();
  }

  /// Gọi lại khi đổi ngôn ngữ app để tên shortcut đổi theo.
  static Future<void> update() {
    final l10n = lookupAppLocalizations(globalContainer.read(localeProvider));
    return _plugin.setShortcutItems([
      ShortcutItem(
        type: _due,
        localizedTitle: l10n.review_title,
        icon: 'ic_shortcut_scan',
      ),
      ShortcutItem(
        type: _review,
        localizedTitle: l10n.home_quickReview,
        icon: 'ic_shortcut_scan',
      ),
    ]);
  }
}
