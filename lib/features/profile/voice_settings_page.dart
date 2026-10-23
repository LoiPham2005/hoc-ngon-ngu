import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingua/core/services/speech_service.dart';
import 'package:lingua/core/services/voice_settings.dart';
import 'package:lingua/design/l10n/l10n_extensions.dart';
import 'package:lingua/design/theme/app_colors.dart';
import 'package:lingua/features/course/models/course_model.dart';
import 'package:lingua/features/course/providers/learner_notifier.dart';
import 'package:lingua/shared/base/app_ui.dart';

/// Câu nghe thử theo ngôn ngữ đọc.
const _samples = {
  'en-US': 'Hello! Nice to meet you. How are you today?',
  'ja-JP': 'こんにちは。はじめまして。お元気ですか。',
};

/// Chọn giọng đọc từng ngôn ngữ: giọng chính, giọng người thứ 2 trong hội thoại, tốc độ đọc.
/// Mỗi giọng có nút ▶ nghe thử; chưa ưng → hướng dẫn tải giọng chất lượng cao của máy.
@RoutePage()
class VoiceSettingsPage extends HookConsumerWidget {
  const VoiceSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final speech = ref.read(speechProvider);
    final settings = ref.read(voiceSettingsProvider.notifier);
    final current = ref.watch(learnerProvider.select((l) => l.course));
    final courses = [
      for (final c in Course.values)
        if (c.available) c,
    ];
    final course = useState(current ?? courses.first);
    final language = course.value.speechLanguage;
    final prefs = ref.watch(
      voiceSettingsProvider.select((s) => s[language] ?? const VoicePrefs()),
    );
    final voicesFuture = useMemoized(() => speech.voices(language), [language]);
    final voices = useFuture(voicesFuture);
    final sample = _samples[language] ?? '';

    void preview(TtsVoice? voice, {double? rate}) => speech.speakWith(
      sample,
      language: language,
      voice: voice,
      rate: rate ?? prefs.rate,
    );

    final list = voices.data ?? const <TtsVoice>[];
    String label(TtsVoice v) {
      // iOS có tên người (Samantha, Kyoko…); Android là mã khó đọc → đánh số.
      final named = !v.name.contains('-') && !v.name.contains('#');
      final base = named ? v.name : l10n.voice_numbered(list.indexOf(v) + 1);
      return '$base · ${v.locale}';
    }

    String? subtitle(TtsVoice v) {
      final tags = [
        if (v.gender == 'male') l10n.voice_male,
        if (v.gender == 'female') l10n.voice_female,
        if (v.isHighQuality) l10n.voice_highQuality,
        if (v.network) l10n.voice_network,
      ];
      return tags.isEmpty ? null : tags.join(' · ');
    }

    Widget voiceTile({
      required String title,
      required TtsVoice? value,
      required TtsVoice? selected,
      required ValueChanged<TtsVoice?> onSelect,
      String? sub,
    }) => RadioListTile<String>(
      value: value?.id ?? '',
      groupValue: selected?.id ?? '',
      onChanged: (_) {
        onSelect(value);
        preview(value);
      },
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: sub == null ? null : Text(sub),
      secondary: IconButton(
        tooltip: l10n.voice_preview,
        icon: const Icon(Icons.play_circle_outline_rounded),
        onPressed: () => preview(value),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.voice_title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          if (courses.length > 1)
            SegmentedButton<Course>(
              segments: [
                for (final c in courses)
                  ButtonSegment(
                    value: c,
                    label: Text('${c.flag} ${c.title(context)}'),
                  ),
              ],
              selected: {course.value},
              showSelectedIcon: false,
              onSelectionChanged: (s) => course.value = s.first,
            ),
          const SizedBox(height: 16),
          SectionTitle(l10n.voice_rate),
          Row(
            children: [
              Text(l10n.voice_rate_slow, style: theme.textTheme.bodySmall),
              Expanded(
                child: Slider(
                  value: prefs.rate,
                  min: VoicePrefs.minRate,
                  max: VoicePrefs.maxRate,
                  divisions: 9,
                  onChanged: (v) => settings.setRate(language, v),
                  onChangeEnd: (v) => preview(prefs.voice, rate: v),
                ),
              ),
              Text(l10n.voice_rate_fast, style: theme.textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 8),
          if (voices.connectionState != ConnectionState.done)
            const Center(child: CircularProgressIndicator())
          else if (list.isEmpty)
            Text(l10n.voice_none, style: theme.textTheme.bodyMedium)
          else ...[
            SectionTitle(l10n.voice_main),
            voiceTile(
              title: l10n.voice_default,
              value: null,
              selected: prefs.voice,
              onSelect: (v) => settings.setVoice(language, v),
            ),
            for (final v in list)
              voiceTile(
                title: label(v),
                sub: subtitle(v),
                value: v,
                selected: prefs.voice,
                onSelect: (v) => settings.setVoice(language, v),
              ),
            const SizedBox(height: 12),
            SectionTitle(l10n.voice_partner),
            voiceTile(
              title: l10n.voice_auto,
              value: null,
              selected: prefs.partner,
              onSelect: (v) => settings.setPartner(language, v),
            ),
            for (final v in list)
              voiceTile(
                title: label(v),
                sub: subtitle(v),
                value: v,
                selected: prefs.partner,
                onSelect: (v) => settings.setPartner(language, v),
              ),
          ],
          const SizedBox(height: 16),
          Card(
            color: context.colors.primarySoft,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.voice_more, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text(
                    Platform.isIOS
                        ? l10n.voice_more_ios
                        : l10n.voice_more_android,
                    style: theme.textTheme.bodySmall,
                  ),
                  if (!Platform.isIOS)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: speech.openVoiceSettings,
                        child: Text(l10n.tts_openSettings),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
