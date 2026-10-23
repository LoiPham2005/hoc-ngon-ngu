import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingua/design/l10n/l10n_extensions.dart';
import 'package:lingua/design/theme/app_colors.dart';
import 'package:lingua/features/course/models/course_model.dart';
import 'package:lingua/features/lessons/models/lesson_model.dart';
import 'package:lingua/features/lessons/providers/lesson_provider.dart';
import 'package:lingua/features/lessons/widgets/lesson_widgets.dart';
import 'package:lingua/features/practice/providers/quiz_session_notifier.dart';
import 'package:lingua/routes/app_router.dart';
import 'package:lingua/shared/base/app_ui.dart';
import 'package:lingua/shared/base/speak_button.dart';
import 'package:lingua/shared/states/async_view.dart';

/// Bảng động từ bất quy tắc V1 – V2 – V3, lọc theo nhóm hình thái (AAA, ABB, ABA, ABC).
/// Bấm 1 dòng → xem câu ví dụ; luyện: trắc nghiệm hoặc tự gõ V2, V3.
@RoutePage()
class IrregularVerbsPage extends HookConsumerWidget {
  const IrregularVerbsPage({super.key});

  static const patterns = ['AAA', 'ABB', 'ABA', 'ABC'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final state = ref.watch(irregularVerbsProvider);
    final pattern = useState<String?>(null);
    const module = Module.enIrregularVerbs;
    return Scaffold(
      appBar: AppBar(title: Text(module.title(context))),
      body: AsyncView<List<IrregularVerb>>(
        state: state,
        onRetry: () => ref.invalidate(irregularVerbsProvider),
        builder: (context, verbs) {
          final shown = [
            for (final v in verbs)
              if (pattern.value == null || v.pattern == pattern.value) v,
          ];
          final learned = learnedCount(ref, verbs.map((v) => v.key));
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              RoundedProgress(learned / verbs.length, color: module.color),
              const SizedBox(height: 6),
              Text(
                l10n.learn_progress(learned, verbs.length),
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: Text(l10n.irregular_all),
                    selected: pattern.value == null,
                    onSelected: (_) => pattern.value = null,
                  ),
                  for (final p in patterns)
                    ChoiceChip(
                      label: Text('$p · ${patternLabel(context, p)}'),
                      selected: pattern.value == p,
                      onSelected: (_) => pattern.value = p,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              for (final v in shown)
                Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    onTap: () => _showVerb(context, v),
                    contentPadding: const EdgeInsets.fromLTRB(4, 2, 8, 2),
                    leading: LearnedToggle(v.key),
                    title: Text(
                      '${v.base} · ${v.past} · ${v.participle}',
                      style: theme.textTheme.titleMedium,
                    ),
                    subtitle: Text(v.meaning),
                    trailing: SpeakButton(v.speech, language: 'en-US'),
                  ),
                ),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.router.push(
                    QuizRoute(topic: const QuizTopic(module, QuizMode.meaning)),
                  ),
                  icon: const Icon(Icons.quiz_rounded),
                  label: Text(l10n.irregular_quiz),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () =>
                      context.router.push(const IrregularTypingRoute()),
                  icon: const Icon(Icons.keyboard_rounded),
                  label: Text(l10n.irregular_typing),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showVerb(BuildContext context, IrregularVerb v) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Tag('${v.pattern} · ${patternLabel(context, v.pattern)}'),
                  const Spacer(),
                  SpeakButton(v.speech, language: 'en-US'),
                ],
              ),
              const SizedBox(height: 8),
              for (final (label, form) in [
                ('V1', v.base),
                (l10n.irregular_v2, v.past),
                (l10n.irregular_v3, v.participle),
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 140,
                        child: Text(label, style: theme.textTheme.bodySmall),
                      ),
                      Text(form, style: theme.textTheme.titleLarge),
                    ],
                  ),
                ),
              Text(
                v.meaning,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: context.colors.primary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SentenceText(v.example, meaning: v.exampleVi),
                  ),
                  SpeakButton(v.example, language: 'en-US'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tên nhóm hình thái: "V2 = V3"…
String patternLabel(BuildContext context, String pattern) {
  final l10n = context.l10n;
  return switch (pattern) {
    'AAA' => l10n.irregular_pattern_AAA,
    'ABB' => l10n.irregular_pattern_ABB,
    'ABA' => l10n.irregular_pattern_ABA,
    _ => l10n.irregular_pattern_ABC,
  };
}
