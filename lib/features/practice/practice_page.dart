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
import 'package:lingua/features/english/models/english_model.dart';
import 'package:lingua/features/english/providers/english_provider.dart';
import 'package:lingua/features/japanese/models/kana_model.dart';
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

    /// Bài Kana: hỏi luyện âm cơ bản / âm đục / cả hai rồi mới vào bài.
    Future<void> startKana(
      String title,
      QuizTopic Function(KanaSet set) topic, {
      int scripts = 1,
    }) async {
      final set = await showKanaSetSheet(
        context,
        title: title,
        scripts: scripts,
      );
      if (set != null) start(topic(set));
    }

    if (course == Course.en) return const _EnglishPractice();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.practice_title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          _Subtitle(l10n.practice_subtitle),
          const SizedBox(height: 16),
          SectionTitle(l10n.learn_alphabet),
          for (final m in modules.where((m) => !m.isKanji))
            _PracticeTile(
              glyph: m.glyph,
              color: m.color,
              title: m.title(context),
              onTap: () => startKana(
                m.title(context),
                (set) => QuizTopic(m, QuizMode.reading, kanaSet: set),
              ),
            ),
          _PracticeTile(
            glyph: 'あア',
            color: AppPalette.kanjiN4,
            title: l10n.practice_kanaMix,
            subtitle: l10n.practice_kanaMix_desc,
            onTap: () => startKana(
              l10n.practice_kanaMix,
              (set) => QuizTopic.kanaMix(kanaSet: set),
              scripts: KanaScript.values.length,
            ),
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

/// Luyện tiếng Anh: từ vựng (nghĩa / nghe), câu giao tiếp, ngữ pháp — mỗi bài chọn chủ đề / bài trước.
class _EnglishPractice extends ConsumerWidget {
  const _EnglishPractice();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final lang = Localizations.localeOf(context).languageCode;

    Future<void> start<T>(
      String title,
      List<Topic<T>> topics,
      QuizTopic Function(String? group) topic,
    ) async {
      final picked = await showTopicSheet(
        context,
        title: title,
        topics: [for (final t in topics) (t.id, '${t.emoji}  ${t.name(lang)}')],
      );
      if (picked != null && context.mounted) {
        await context.router.push(QuizRoute(topic: topic(picked.id)));
      }
    }

    final words = ref.watch(vocabTopicsProvider).value ?? const [];
    final phrases = ref.watch(phraseTopicsProvider).value ?? const [];
    final lessons = ref.watch(grammarLessonsProvider).value ?? const [];

    Future<void> startGrammar() async {
      final picked = await showTopicSheet(
        context,
        title: l10n.practice_grammar,
        topics: [
          for (final g in lessons) (g.id, '${g.emoji}  ${g.name(lang)}'),
        ],
      );
      if (picked != null && context.mounted) {
        await context.router.push(GrammarPracticeRoute(lessonId: picked.id));
      }
    }

    final tiles = [
      (
        Module.enVocabulary,
        'Aa',
        l10n.practice_vocabMeaning,
        l10n.practice_vocabMeaning_desc,
        () => start(
          l10n.practice_vocabMeaning,
          words,
          (g) => QuizTopic(Module.enVocabulary, QuizMode.meaning, group: g),
        ),
      ),
      (
        Module.enPronunciation,
        '🎧',
        l10n.practice_vocabListening,
        l10n.practice_vocabListening_desc,
        () => start(
          l10n.practice_vocabListening,
          words,
          (g) => QuizTopic(Module.enVocabulary, QuizMode.listening, group: g),
        ),
      ),
      (
        Module.enPhrases,
        '💬',
        l10n.practice_phrases,
        l10n.practice_phrases_desc,
        () => start(
          l10n.practice_phrases,
          phrases,
          (g) => QuizTopic(Module.enPhrases, QuizMode.meaning, group: g),
        ),
      ),
      (
        Module.enGrammar,
        '✍️',
        l10n.practice_grammar,
        l10n.practice_grammar_desc,
        startGrammar,
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.practice_title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          _Subtitle(l10n.practice_subtitle),
          const SizedBox(height: 16),
          for (final (module, glyph, title, subtitle, onTap) in tiles)
            _PracticeTile(
              glyph: glyph,
              color: module.color,
              title: title,
              subtitle: subtitle,
              onTap: onTap,
            ),
        ],
      ),
    );
  }
}

class _Subtitle extends StatelessWidget {
  const _Subtitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(color: context.colors.textMuted),
  );
}

/// Bảng chọn chủ đề: "Tất cả chủ đề" (id = null) hoặc một chủ đề. Đóng bảng → null.
Future<({String? id})?> showTopicSheet(
  BuildContext context, {
  required String title,
  required List<(String id, String label)> topics,
}) {
  final l10n = context.l10n;
  return showModalBottomSheet<({String? id})>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.92,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          Text(
            l10n.practice_pickTopic,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Card(
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              onTap: () => Navigator.of(context).pop((id: null)),
              leading: const Icon(Icons.shuffle_rounded),
              title: Text(l10n.practice_allTopics),
              trailing: Icon(
                Icons.play_circle_fill_rounded,
                color: context.colors.primary,
              ),
            ),
          ),
          for (final (id, label) in topics)
            ListTile(
              onTap: () => Navigator.of(context).pop((id: id)),
              title: Text(label),
              trailing: const Icon(Icons.chevron_right_rounded),
            ),
        ],
      ),
    ),
  );
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

/// Bảng chọn phần Kana (vuốt từ dưới lên). [scripts] = số bảng chữ (Kana tổng hợp = 2) để hiện số chữ.
Future<KanaSet?> showKanaSetSheet(
  BuildContext context, {
  required String title,
  int scripts = 1,
}) {
  final l10n = context.l10n;
  int count(KanaSet set) =>
      KanaTable.of(KanaScript.hiragana, set).length * scripts;
  final options = [
    (KanaSet.basic, l10n.kana_basic, 'あ か さ'),
    (KanaSet.dakuten, l10n.kana_dakuten, 'が ざ ぱ'),
    (KanaSet.all, l10n.kanaSet_all, 'あ が ぱ'),
  ];
  return showModalBottomSheet<KanaSet>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            Text(
              l10n.practice_pickSet,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            for (final (set, label, sample) in options)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    onTap: () => Navigator.of(context).pop(set),
                    title: Text(
                      label,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    subtitle: Text(
                      '$sample · ${l10n.practice_charCount(count(set))}',
                    ),
                    trailing: Icon(
                      Icons.play_circle_fill_rounded,
                      color: context.colors.primary,
                      size: 30,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
