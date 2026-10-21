import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingua/design/l10n/l10n_extensions.dart';
import 'package:lingua/design/l10n/locale_notifier.dart';
import 'package:lingua/design/theme/app_colors.dart';
import 'package:lingua/design/theme/app_palette.dart';
import 'package:lingua/features/course/models/course_model.dart';
import 'package:lingua/features/course/providers/learner_notifier.dart';
import 'package:lingua/features/practice/providers/quiz_session_notifier.dart';
import 'package:lingua/routes/app_router.dart';
import 'package:lingua/shared/base/app_ui.dart';

/// Chọn bài luyện: từng học phần + Kana tổng hợp. Kanji hỏi theo Hán Việt hoặc nghĩa.
@RoutePage()
class PracticePage extends HookConsumerWidget {
  const PracticePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final course =
        ref.watch(learnerProvider.select((l) => l.course)) ?? Course.ja;
    final vietnamese = ref.watch(localeProvider).languageCode == 'vi';
    // Hán Việt chỉ có nghĩa với người Việt → giao diện khác chỉ hỏi nghĩa.
    final kanjiMode = useState(QuizMode.hanViet);
    final mode = vietnamese ? kanjiMode.value : QuizMode.meaning;
    final l10n = context.l10n;
    final modules = course.modules;

    void start(QuizTopic topic) => context.router.push(QuizRoute(topic: topic));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.practice_title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          Text(
            l10n.practice_subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: context.colors.textMuted),
          ),
          const SizedBox(height: 16),
          SectionTitle(l10n.learn_alphabet),
          for (final m in modules.where((m) => !m.isKanji))
            _PracticeTile(
              glyph: m.glyph,
              color: m.color,
              title: m.title(context),
              onTap: () => start(QuizTopic(m, QuizMode.reading)),
            ),
          _PracticeTile(
            glyph: 'あア',
            color: AppPalette.kanjiN4,
            title: l10n.practice_kanaMix,
            subtitle: l10n.practice_kanaMix_desc,
            onTap: () => start(const QuizTopic.kanaMix()),
          ),
          const SizedBox(height: 12),
          SectionTitle(l10n.learn_kanji),
          if (vietnamese) ...[
            Text(
              l10n.practice_quizType,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            SegmentedButton<QuizMode>(
              segments: [
                ButtonSegment(
                  value: QuizMode.hanViet,
                  label: Text(l10n.quiz_mode_hanViet),
                ),
                ButtonSegment(
                  value: QuizMode.meaning,
                  label: Text(l10n.quiz_mode_meaning),
                ),
              ],
              selected: {kanjiMode.value},
              onSelectionChanged: (s) => kanjiMode.value = s.first,
            ),
            const SizedBox(height: 12),
          ],
          for (final m in modules.where((m) => m.isKanji))
            _PracticeTile(
              glyph: m.glyph,
              color: m.color,
              title: m.title(context),
              onTap: () => start(QuizTopic(m, mode)),
            ),
        ],
      ),
    );
  }
}

class _PracticeTile extends StatelessWidget {
  const _PracticeTile({
    required this.glyph,
    required this.color,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final String glyph;
  final Color color;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: GlyphBadge(glyph, color: color, size: 46),
        title: Text(title, style: Theme.of(context).textTheme.titleMedium),
        subtitle: subtitle == null ? null : Text(subtitle!),
        trailing: Icon(Icons.play_circle_fill_rounded, color: color, size: 32),
      ),
    ),
  );
}
