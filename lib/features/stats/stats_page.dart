import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingua/design/l10n/l10n_extensions.dart';
import 'package:lingua/design/theme/app_colors.dart';
import 'package:lingua/features/course/models/course_model.dart';
import 'package:lingua/features/course/providers/learner_notifier.dart';
import 'package:lingua/features/course/providers/module_chars_provider.dart';
import 'package:lingua/modules/ads/ad_config.dart';
import 'package:lingua/modules/ads/widgets/native_ad_widget.dart';
import 'package:lingua/shared/base/app_ui.dart';

/// Thống kê: hoạt động 7 / 30 ngày (biểu đồ cột), độ chính xác, lịch ôn, tiến độ từng học phần.
@RoutePage()
class StatsPage extends HookConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.colors;
    final learner = ref.watch(learnerProvider);
    final notifier = ref.read(learnerProvider.notifier);
    final course = learner.course ?? Course.ja;
    final range = useState(7);
    final days = notifier.lastDays(range.value);
    final answered = days.fold(0, (sum, d) => sum + d.$2.answered);
    final correct = days.fold(0, (sum, d) => sum + d.$2.correct);
    final learned = days.fold(0, (sum, d) => sum + d.$2.learned);
    final activeDays = days.where((d) => d.$2.total > 0).length;
    final reviews = [
      for (final MapEntry(:key, :value) in learner.reviews.entries)
        if (courseOfKey(key) == course) value,
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.stats_title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          SegmentedButton<int>(
            segments: [
              ButtonSegment(value: 7, label: Text(l10n.stats_days(7))),
              ButtonSegment(value: 30, label: Text(l10n.stats_days(30))),
            ],
            selected: {range.value},
            showSelectedIcon: false,
            onSelectionChanged: (s) => range.value = s.first,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: StatTile(
                  icon: Icons.local_fire_department_rounded,
                  value: '$activeDays/${range.value}',
                  label: l10n.stats_activeDays,
                  color: colors.streak,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatTile(
                  icon: Icons.task_alt_rounded,
                  value: '$answered',
                  label: l10n.stat_answered,
                  color: colors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatTile(
                  icon: Icons.track_changes_rounded,
                  value: answered == 0
                      ? '–'
                      : '${(correct * 100 / answered).round()}%',
                  label: l10n.stat_accuracy,
                  color: colors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SectionTitle(l10n.stats_activity),
          _ActivityChart(days),
          const SizedBox(height: 6),
          Text(
            l10n.stats_newLearned(learned),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colors.textMuted),
          ),
          const NativeAdWidget(
            placement: NativePlacement.list,
            padding: EdgeInsets.symmetric(vertical: 12),
          ),
          const SizedBox(height: 20),
          SectionTitle(l10n.review_title),
          Row(
            children: [
              Expanded(
                child: StatTile(
                  icon: Icons.schedule_rounded,
                  value: '${notifier.dueKeys(course).length}',
                  label: l10n.stats_due,
                  color: colors.error,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatTile(
                  icon: Icons.event_repeat_rounded,
                  value: '${reviews.length}',
                  label: l10n.stats_scheduled,
                  color: colors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatTile(
                  icon: Icons.psychology_rounded,
                  value: '${reviews.where((r) => r.isMastered).length}',
                  label: l10n.stats_mastered,
                  color: colors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SectionTitle(l10n.stats_modules),
          for (final m in course.modules) _ModuleProgress(m),
        ],
      ),
    );
  }
}

/// Biểu đồ cột lượt học mỗi ngày (cột hôm nay đậm màu), nhãn ngày đầu / cuối.
class _ActivityChart extends StatelessWidget {
  const _ActivityChart(this.days);

  final List<(DateTime, DayStat)> days;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final peak = days.fold(1, (m, d) => d.$2.total > m ? d.$2.total : m);
    String label(DateTime d) => '${d.day}/${d.month}';
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 10),
        child: Column(
          children: [
            SizedBox(
              height: 120,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final (i, (_, stat)) in days.indexed)
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: days.length > 10 ? 1 : 4,
                        ),
                        child: Tooltip(
                          message: '${stat.total}',
                          child: Container(
                            height: stat.total == 0
                                ? 3
                                : 3 + 117 * stat.total / peak,
                            decoration: BoxDecoration(
                              color: i == days.length - 1
                                  ? colors.primary
                                  : colors.primary.withValues(alpha: 0.45),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(label(days.first.$1), style: theme.textTheme.labelSmall),
                const Spacer(),
                Text(label(days.last.$1), style: theme.textTheme.labelSmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Tiến độ 1 học phần: đã thuộc / tổng.
class _ModuleProgress extends ConsumerWidget {
  const _ModuleProgress(this.module);

  final Module module;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final keys = ref.watch(moduleCharsProvider(module)).value ?? const [];
    final learned = ref.watch(
      learnerProvider.select((l) => keys.where(l.learned.contains).length),
    );
    final total = keys.length;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  module.title(context),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              Text(
                '$learned/$total',
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
          ),
          const SizedBox(height: 4),
          RoundedProgress(
            total == 0 ? 0 : learned / total,
            color: module.color,
            height: 6,
          ),
        ],
      ),
    );
  }
}
