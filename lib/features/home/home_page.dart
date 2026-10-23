import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingua/design/l10n/l10n_extensions.dart';
import 'package:lingua/design/theme/app_colors.dart';
import 'package:lingua/features/course/models/course_model.dart';
import 'package:lingua/features/course/providers/learner_notifier.dart';
import 'package:lingua/features/course/widgets/module_card.dart';
import 'package:lingua/features/practice/providers/quiz_session_notifier.dart';
import 'package:lingua/routes/app_router.dart';
import 'package:lingua/shared/base/app_ui.dart';

/// Trang chủ: lời chào, chuỗi ngày học + mục tiêu hôm nay, học tiếp, ôn nhanh, thống kê.
@RoutePage()
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final learner = ref.watch(learnerProvider);
    final notifier = ref.read(learnerProvider.notifier);
    final course = learner.course ?? Course.ja;
    final module = learner.lastModule?.course == course
        ? learner.lastModule!
        : course.modules.first;
    final l10n = context.l10n;
    final colors = context.colors;
    final hour = DateTime.now().hour;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    hour < 12
                        ? l10n.home_greetingMorning
                        : hour < 18
                        ? l10n.home_greetingAfternoon
                        : l10n.home_greetingEvening,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                Chip(
                  avatar: Text(course.flag),
                  label: Text(course.title(context)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _StreakCard(
              streak: notifier.currentStreak,
              today: notifier.todayCount,
              goal: learner.dailyGoal,
            ),
            const SizedBox(height: 12),
            _ReviewCard(
              due: notifier.dueKeys(course).length,
              scheduled: learner.reviews.keys
                  .where((k) => courseOfKey(k) == course)
                  .length,
              onStart: () => context.router.push(
                QuizRoute(topic: QuizTopic.review(course)),
              ),
            ),
            const SizedBox(height: 24),
            SectionTitle(l10n.home_continue),
            ModuleCard(module),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => context.router.push(
                QuizRoute(topic: QuizTopic.quickReview(module)),
              ),
              icon: const Icon(Icons.bolt_rounded),
              label: Text(l10n.home_quickReview),
            ),
            const SizedBox(height: 24),
            SectionTitle(l10n.home_stats),
            Row(
              children: [
                Expanded(
                  child: StatTile(
                    icon: Icons.verified_rounded,
                    value: '${learner.learned.length}',
                    label: l10n.stat_learned,
                    color: colors.success,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: StatTile(
                    icon: Icons.task_alt_rounded,
                    value: '${learner.answered}',
                    label: l10n.stat_answered,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: StatTile(
                    icon: Icons.track_changes_rounded,
                    value: '${(learner.accuracy * 100).round()}%',
                    label: l10n.stat_accuracy,
                    color: colors.warning,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Ôn tập hôm nay (lặp lại ngắt quãng): số mục tới hạn + nút ôn.
class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.due,
    required this.scheduled,
    required this.onStart,
  });

  final int due;
  final int scheduled;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        child: Row(
          children: [
            Text(due > 0 ? '🧠' : '✅', style: const TextStyle(fontSize: 30)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.review_title, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    due > 0
                        ? l10n.review_due(due)
                        : scheduled > 0
                        ? l10n.review_none(scheduled)
                        : l10n.review_empty,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (due > 0) ...[
              const SizedBox(width: 8),
              FilledButton(onPressed: onStart, child: Text(l10n.review_start)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Thẻ gradient màu chủ đạo: 🔥 chuỗi ngày + vòng tiến độ mục tiêu hôm nay.
class _StreakCard extends StatelessWidget {
  const _StreakCard({
    required this.streak,
    required this.today,
    required this.goal,
  });

  final int streak;
  final int today;
  final int goal;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final theme = Theme.of(context);
    final onCard = colors.onPrimary;
    final reached = today >= goal;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.primary, darken(colors.primary, 0.18)],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 28)),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        l10n.home_streak(streak),
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: onCard,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  streak == 0 ? l10n.home_streakStart : l10n.home_streakHint,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: onCard.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  reached ? l10n.home_goalReached : l10n.home_todayGoal,
                  style: theme.textTheme.titleSmall?.copyWith(color: onCard),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox.square(
            dimension: 84,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: goal == 0 ? 0 : (today / goal).clamp(0, 1),
                  strokeWidth: 8,
                  strokeCap: StrokeCap.round,
                  color: onCard,
                  backgroundColor: onCard.withValues(alpha: 0.25),
                ),
                Center(
                  child: Text(
                    l10n.home_todayProgress(today, goal),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelLarge?.copyWith(color: onCard),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
