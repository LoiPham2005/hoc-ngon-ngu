import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingua/design/l10n/l10n_extensions.dart';
import 'package:lingua/design/theme/app_colors.dart';
import 'package:lingua/features/course/models/course_model.dart';
import 'package:lingua/features/course/providers/learner_notifier.dart';
import 'package:lingua/modules/ads/ad_config.dart';
import 'package:lingua/modules/ads/widgets/native_ad_widget.dart';
import 'package:lingua/routes/app_router.dart';
import 'package:lingua/shared/base/app_ui.dart';

/// Chọn ngôn ngữ muốn học. Lần đầu mở app → xong thì vào app;
/// mở từ Hồ sơ ([changing] = true) → xong thì quay lại.
@RoutePage()
class OnboardingPage extends HookConsumerWidget {
  const OnboardingPage({this.changing = false, super.key});

  final bool changing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = useState(ref.read(learnerProvider).course ?? Course.ja);
    final l10n = context.l10n;
    final colors = context.colors;
    final theme = Theme.of(context);

    Future<void> start() async {
      await ref.read(learnerProvider.notifier).chooseCourse(selected.value);
      if (!context.mounted) return;
      if (changing) {
        await context.router.maybePop();
      } else {
        await context.router.replaceAll([const MainRoute()]);
      }
    }

    return Scaffold(
      appBar: changing ? AppBar() : null,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!changing) ...[
                Row(
                  children: [
                    for (final (glyph, i) in [
                      ('あ', 0),
                      ('A', 1),
                      ('한', 2),
                      ('中', 3),
                    ])
                      Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: Transform.rotate(
                          angle: (i.isEven ? -1 : 1) * 0.08,
                          child: GlyphBadge(
                            glyph,
                            color: i == 0 ? colors.primary : colors.textMuted,
                            size: 56,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 28),
                Text(
                  l10n.onboarding_title,
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.onboarding_subtitle,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colors.textMuted,
                  ),
                ),
                const SizedBox(height: 28),
              ],
              Text(l10n.onboarding_pick, style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: Course.values.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final course = Course.values[i];
                    return _CourseOption(
                      course: course,
                      selected: course == selected.value,
                      onTap: course.available
                          ? () => selected.value = course
                          : null,
                    );
                  },
                ),
              ),
              const NativeAdWidget(
                placement: NativePlacement.onboarding,
                size: NativeAdSize.small,
                padding: EdgeInsets.only(top: 12),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: start,
                child: Text(l10n.onboarding_start),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CourseOption extends StatelessWidget {
  const _CourseOption({
    required this.course,
    required this.selected,
    this.onTap,
  });

  final Course course;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    return Opacity(
      opacity: course.available ? 1 : 0.55,
      child: Material(
        color: selected ? colors.primarySoft : colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: selected ? colors.primary : colors.border,
            width: selected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Text(course.flag, style: const TextStyle(fontSize: 30)),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    course.title(context),
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                if (!course.available)
                  Chip(label: Text(context.l10n.common_comingSoon))
                else
                  Icon(
                    selected ? Icons.check_circle : Icons.circle_outlined,
                    color: selected ? colors.primary : colors.border,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
