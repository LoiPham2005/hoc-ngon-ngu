import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingua/core/services/permission_service.dart';
import 'package:lingua/core/services/sound_service.dart';
import 'package:lingua/core/utils/toast.dart';
import 'package:lingua/design/l10n/l10n_extensions.dart';
import 'package:lingua/design/l10n/locale_notifier.dart';
import 'package:lingua/design/theme/app_colors.dart';
import 'package:lingua/design/theme/app_palette.dart';
import 'package:lingua/design/theme/theme_notifier.dart';
import 'package:lingua/features/course/models/course_model.dart';
import 'package:lingua/features/course/providers/learner_notifier.dart';
import 'package:lingua/features/profile/providers/backup_service.dart';
import 'package:lingua/features/profile/providers/reminder_notifier.dart';
import 'package:lingua/routes/app_router.dart';
import 'package:lingua/shared/base/app_ui.dart';
import 'package:lingua/shared/dialogs/app_confirmation_dialog.dart';
import 'package:lingua/shared/dialogs/permission_dialog.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Hồ sơ người học + cài đặt: giao diện, ngôn ngữ app, mục tiêu, dữ liệu, giới thiệu.
@RoutePage()
class ProfilePage extends HookConsumerWidget {
  const ProfilePage({super.key});

  static const goals = [5, 10, 20, 30];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final learner = ref.watch(learnerProvider);
    final reminder = ref.watch(reminderProvider);
    final notifier = ref.read(learnerProvider.notifier);
    final theme = ref.watch(themeProvider);
    final locale = ref.watch(localeProvider);
    final version = useFuture(useMemoized(PackageInfo.fromPlatform)).data;
    final course = learner.course ?? Course.ja;
    final l10n = context.l10n;
    final colors = context.colors;
    final text = Theme.of(context).textTheme;

    String accentName(AppAccent a) => switch (a) {
      AppAccent.indigo => l10n.accent_indigo,
      AppAccent.sakura => l10n.accent_sakura,
      AppAccent.emerald => l10n.accent_emerald,
      AppAccent.ocean => l10n.accent_ocean,
      AppAccent.sunset => l10n.accent_sunset,
    };

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profile_title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: colors.primarySoft,
                    child: Text(
                      course.flag,
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.profile_learner, style: text.titleLarge),
                        Text(
                          l10n.profile_learning(course.title(context)),
                          style: text.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 22)),
                      Text(
                        '${notifier.currentStreak}',
                        style: text.titleMedium,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          SectionTitle(l10n.section_appearance),
          _Panel(
            children: [
              Text(l10n.appearance_mode, style: text.titleSmall),
              const SizedBox(height: 8),
              SegmentedButton<ThemeMode>(
                segments: [
                  ButtonSegment(
                    value: ThemeMode.system,
                    icon: const Icon(Icons.brightness_auto_rounded),
                    label: Text(l10n.mode_system),
                  ),
                  ButtonSegment(
                    value: ThemeMode.light,
                    icon: const Icon(Icons.light_mode_rounded),
                    label: Text(l10n.mode_light),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    icon: const Icon(Icons.dark_mode_rounded),
                    label: Text(l10n.mode_dark),
                  ),
                ],
                selected: {theme.mode},
                showSelectedIcon: false,
                onSelectionChanged: (s) =>
                    ref.read(themeProvider.notifier).setMode(s.first),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(l10n.appearance_accent, style: text.titleSmall),
                  ),
                  Text(accentName(theme.accent), style: text.bodySmall),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (final accent in AppAccent.values)
                    _Swatch(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? accent.dark
                          : accent.light,
                      selected: accent == theme.accent,
                      tooltip: accentName(accent),
                      onTap: () =>
                          ref.read(themeProvider.notifier).setAccent(accent),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          SectionTitle(l10n.section_learning),
          _Panel(
            children: [
              Text(l10n.appLanguage, style: text.titleSmall),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(value: 'vi', label: Text(l10n.language_vi)),
                  ButtonSegment(value: 'en', label: Text(l10n.language_en)),
                  ButtonSegment(value: 'ja', label: Text(l10n.language_ja)),
                ],
                selected: {locale.languageCode},
                showSelectedIcon: false,
                onSelectionChanged: (s) =>
                    ref.read(localeProvider.notifier).set(Locale(s.first)),
              ),
              const SizedBox(height: 16),
              Text(l10n.dailyGoal, style: text.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final g in goals)
                    ChoiceChip(
                      label: Text(l10n.dailyGoal_value(g)),
                      selected: learner.dailyGoal == g,
                      onSelected: (_) => notifier.setDailyGoal(g),
                    ),
                ],
              ),
              const Divider(height: 28),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.music_note_rounded),
                title: Text(l10n.sound_effects),
                subtitle: Text(l10n.sound_effects_desc),
                value: ref.watch(soundEnabledProvider),
                onChanged: (on) async {
                  await ref
                      .read(soundEnabledProvider.notifier)
                      .set(enabled: on);
                  if (on) {
                    await ref.read(soundServiceProvider).play(Sfx.correct);
                  }
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.record_voice_over_rounded),
                title: Text(l10n.voice_title),
                subtitle: Text(l10n.voice_desc),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.router.push(const VoiceSettingsRoute()),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.notifications_active_rounded),
                title: Text(l10n.reminder),
                subtitle: Text(
                  reminder.enabled
                      ? l10n.reminder_on(
                          MaterialLocalizations.of(context).formatTimeOfDay(
                            TimeOfDay(
                              hour: reminder.hour,
                              minute: reminder.minute,
                            ),
                          ),
                        )
                      : l10n.reminder_off,
                ),
                value: reminder.enabled,
                onChanged: (on) async {
                  if (on &&
                      !await ensurePermission(
                        context,
                        ref,
                        AppPermission.notification,
                      )) {
                    return;
                  }
                  await ref
                      .read(reminderProvider.notifier)
                      .setEnabled(enabled: on);
                },
              ),
              if (reminder.enabled)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.schedule_rounded),
                  title: Text(l10n.reminder_time),
                  trailing: Text(
                    MaterialLocalizations.of(context).formatTimeOfDay(
                      TimeOfDay(hour: reminder.hour, minute: reminder.minute),
                    ),
                    style: text.titleMedium,
                  ),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay(
                        hour: reminder.hour,
                        minute: reminder.minute,
                      ),
                    );
                    if (picked != null) {
                      await ref
                          .read(reminderProvider.notifier)
                          .setTime(picked.hour, picked.minute);
                    }
                  },
                ),
              const Divider(height: 28),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Text(
                  course.flag,
                  style: const TextStyle(fontSize: 24),
                ),
                title: Text(l10n.changeCourse),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () =>
                    context.router.push(OnboardingRoute(changing: true)),
              ),
            ],
          ),
          const SizedBox(height: 20),

          SectionTitle(l10n.section_data),
          _Panel(
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.upload_file_rounded),
                title: Text(l10n.backup_export),
                subtitle: Text(l10n.backup_export_desc),
                onTap: () async {
                  switch (await ref.read(backupProvider).export()) {
                    case ExportResult.saved:
                      toast.success(l10n.backup_exported);
                    case ExportResult.failed:
                      toast.error(l10n.backup_failed);
                    case ExportResult.cancelled:
                  }
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.download_rounded),
                title: Text(l10n.backup_restore),
                subtitle: Text(l10n.backup_restore_desc),
                onTap: () async {
                  final ok = await AppConfirmationDialog.show(
                    context,
                    title: l10n.backup_restore,
                    message: l10n.backup_restore_confirm,
                    confirmText: l10n.backup_restore,
                  );
                  if (!ok) return;
                  switch (await ref.read(backupProvider).restore()) {
                    case RestoreResult.restored:
                      toast.success(l10n.backup_restored);
                    case RestoreResult.invalid:
                      toast.error(l10n.backup_invalid);
                    case RestoreResult.failed:
                      toast.error(l10n.backup_failed);
                    case RestoreResult.cancelled:
                  }
                },
              ),
              const Divider(height: 20),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.restart_alt_rounded, color: colors.error),
                title: Text(
                  l10n.resetProgress,
                  style: TextStyle(color: colors.error),
                ),
                onTap: () async {
                  final ok = await AppConfirmationDialog.show(
                    context,
                    title: l10n.resetProgress_title,
                    message: l10n.resetProgress_message,
                    confirmText: l10n.resetProgress,
                    destructive: true,
                  );
                  if (!ok) return;
                  await notifier.resetProgress();
                  toast.success(l10n.resetProgress_done);
                },
              ),
            ],
          ),
          const SizedBox(height: 20),

          SectionTitle(l10n.section_about),
          _Panel(
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.info_outline_rounded),
                title: Text(l10n.about_version),
                trailing: Text(
                  version == null
                      ? ''
                      : '${version.version} (${version.buildNumber})',
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.dataset_outlined),
                title: Text(l10n.about_data),
                subtitle: Text(l10n.about_data_desc),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    ),
  );
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.color,
    required this.selected,
    required this.tooltip,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: InkResponse(
      onTap: onTap,
      radius: 28,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? context.colors.text : context.colors.surface,
            width: 3,
          ),
        ),
        child: selected
            ? Icon(Icons.check_rounded, color: context.colors.onPrimary)
            : null,
      ),
    ),
  );
}
