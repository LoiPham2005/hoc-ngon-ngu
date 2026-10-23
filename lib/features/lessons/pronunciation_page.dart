import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingua/core/services/speech_service.dart';
import 'package:lingua/design/l10n/l10n_extensions.dart';
import 'package:lingua/design/theme/app_colors.dart';
import 'package:lingua/features/course/models/course_model.dart';
import 'package:lingua/features/course/widgets/module_card.dart';
import 'package:lingua/features/lessons/models/lesson_model.dart';
import 'package:lingua/features/lessons/widgets/lesson_widgets.dart';
import 'package:lingua/routes/app_router.dart';
import 'package:lingua/shared/base/app_ui.dart';

/// Bảng 44 âm IPA: bấm 1 âm → nghe từ ví dụ; ✓ = đã luyện.
@RoutePage()
class PronunciationPage extends ConsumerWidget {
  const PronunciationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final p = moduleProgress(ref, Module.enPronunciation);
    final sections = [
      (l10n.ipa_vowels, PhonemeKind.vowel),
      (l10n.ipa_diphthongs, PhonemeKind.diphthong),
      (l10n.ipa_consonants, PhonemeKind.consonant),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(Module.enPronunciation.title(context))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          RoundedProgress(
            p.total == 0 ? 0 : p.learned / p.total,
            color: Module.enPronunciation.color,
          ),
          const SizedBox(height: 6),
          Text(
            '${l10n.learn_progress(p.learned, p.total)} · ${l10n.ipa_hint}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Card(
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              onTap: () => context.router.push(const MinimalPairsRoute()),
              leading: const Text('🎧', style: TextStyle(fontSize: 28)),
              title: Text(l10n.pairs_title),
              subtitle: Text(l10n.pairs_desc),
              trailing: const Icon(Icons.chevron_right_rounded),
            ),
          ),
          for (final (title, kind) in sections) ...[
            const SizedBox(height: 12),
            SectionTitle(title),
            for (final ph in phonemes.where((p) => p.kind == kind))
              _PhonemeTile(ph),
          ],
        ],
      ),
    );
  }
}

class _PhonemeTile extends ConsumerWidget {
  const _PhonemeTile(this.phoneme);

  final Phoneme phoneme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => ref
              .read(speechProvider)
              .speak(phoneme.example, language: 'en-US'),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
            child: Row(
              children: [
                SizedBox(
                  width: 64,
                  child: Text(
                    '/${phoneme.symbol}/',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: context.colors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.volume_up_rounded,
                            size: 16,
                            color: context.colors.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            phoneme.example,
                            style: theme.textTheme.titleMedium,
                          ),
                        ],
                      ),
                      Text(phoneme.tip, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                LearnedToggle(phoneme.key),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
