import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingua/core/services/speech_service.dart';
import 'package:lingua/core/services/voice_input_service.dart';
import 'package:lingua/design/l10n/l10n_extensions.dart';
import 'package:lingua/design/l10n/locale_notifier.dart';
import 'package:lingua/design/theme/app_colors.dart';
import 'package:lingua/features/course/models/course_model.dart';
import 'package:lingua/features/course/providers/learner_notifier.dart';
import 'package:lingua/features/english/models/english_model.dart';
import 'package:lingua/features/english/providers/english_provider.dart';
import 'package:lingua/features/english/widgets/english_widgets.dart';
import 'package:lingua/shared/base/speak_button.dart';
import 'package:lingua/shared/states/async_view.dart';

/// Nghe – chép (gõ lại câu nghe được) hoặc luyện nói (đọc to, máy so với câu mẫu).
enum SentenceMode { dictation, speaking }

/// Tỉ lệ từ khớp tối thiểu để tính là đúng khi luyện nói (nhận giọng không hoàn hảo).
const _speakingPass = 0.8;

/// 10 câu giao tiếp của 1 tình huống ([topicId] = null → trộn mọi tình huống).
@RoutePage()
class SentencePracticePage extends HookConsumerWidget {
  const SentencePracticePage({required this.mode, this.topicId, super.key});

  final SentenceMode mode;
  final String? topicId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(localeProvider).languageCode;
    final state = ref.watch(phraseTopicsProvider);
    final topics = state.value;
    final topic = topics?.where((t) => t.id == topicId).firstOrNull;
    final round = useState(0);
    final phrases = useMemoized(
      () => topics == null
          ? const <Phrase>[]
          : ([
              for (final t in topic == null ? topics : [topic]) ...t.items,
            ]..shuffle()).take(10).toList(),
      [topics, round.value],
    );
    final l10n = context.l10n;
    final title = mode == SentenceMode.dictation
        ? l10n.practice_dictation
        : l10n.practice_speaking;
    if (topics == null) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: AsyncView<List<Topic<Phrase>>>(
          state: state,
          onRetry: () => ref.invalidate(phraseTopicsProvider),
          builder: (_, _) => const SizedBox.shrink(),
        ),
      );
    }
    return _SentenceSession(
      key: ValueKey(round.value),
      mode: mode,
      title: topic == null ? title : '$title · ${topic.name(language)}',
      phrases: phrases,
      onRetry: () => round.value++,
    );
  }
}

class _SentenceSession extends HookConsumerWidget {
  const _SentenceSession({
    required this.mode,
    required this.title,
    required this.phrases,
    required this.onRetry,
    super.key,
  });

  final SentenceMode mode;
  final String title;
  final List<Phrase> phrases;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.colors;
    final index = useState(0);
    final answered = useState(0);
    final correct = useState(0);
    // Kết quả câu hiện tại: null = chưa trả lời.
    final result = useState<bool?>(null);
    final total = phrases.length;

    void answer({required bool ok}) {
      result.value = ok;
      answered.value++;
      if (ok) correct.value++;
      ref
          .read(learnerProvider.notifier)
          .recordAnswer(correct: ok, key: phrases[index.value].key);
    }

    /// Sang câu kế ([result] = null khi bỏ qua câu không làm được).
    void next() {
      result.value = null;
      index.value++;
    }

    if (index.value >= total) {
      return PracticeResult(
        correct: correct.value,
        total: answered.value,
        onRetry: onRetry,
      );
    }

    final phrase = phrases[index.value];
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: index.value / total,
            color: Module.enPhrases.color,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          Text(
            l10n.quiz_progress(index.value + 1, total),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colors.textMuted),
          ),
          const SizedBox(height: 4),
          switch (mode) {
            SentenceMode.dictation => _DictationView(
              key: ValueKey(index.value),
              phrase: phrase,
              result: result.value,
              onAnswer: answer,
            ),
            SentenceMode.speaking => _SpeakingView(
              key: ValueKey(index.value),
              phrase: phrase,
              result: result.value,
              onAnswer: answer,
              onSkip: next,
            ),
          },
        ],
      ),
      bottomNavigationBar: result.value == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: FilledButton(
                  onPressed: next,
                  child: Text(
                    index.value == total - 1
                        ? l10n.quiz_seeResult
                        : l10n.quiz_continue,
                  ),
                ),
              ),
            ),
    );
  }
}

/// Nghe – chép: tự đọc câu khi mở, nghe lại / nghe chậm, gõ câu rồi kiểm tra từng từ.
class _DictationView extends HookConsumerWidget {
  const _DictationView({
    required this.phrase,
    required this.result,
    required this.onAnswer,
    super.key,
  });

  final Phrase phrase;
  final bool? result;
  final void Function({required bool ok}) onAnswer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = context.colors;
    final input = useTextEditingController();
    final typed = useValueListenable(input).text.trim();
    final showMeaning = useState(false);
    final matches = useState<List<({String word, bool hit})>?>(null);
    final answered = result != null;

    void play({bool slow = false}) => ref
        .read(speechProvider)
        .speak(phrase.text, language: 'en-US', slow: slow);
    useEffect(() {
      play();
      return null;
    }, const []);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.sentence_dictationAsk, style: theme.textTheme.titleSmall),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed: play,
                icon: const Icon(Icons.volume_up_rounded),
                label: Text(l10n.sentence_listenAgain),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => play(slow: true),
                icon: const Text('🐢'),
                label: Text(l10n.sentence_slow),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (showMeaning.value || answered)
          Card(
            color: colors.primarySoft,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(phrase.meaning, style: theme.textTheme.bodyLarge),
            ),
          )
        else
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => showMeaning.value = true,
              icon: const Icon(Icons.lightbulb_outline_rounded),
              label: Text(l10n.sentence_showMeaning),
            ),
          ),
        const SizedBox(height: 12),
        TextField(
          controller: input,
          enabled: !answered,
          minLines: 2,
          maxLines: 4,
          textCapitalization: TextCapitalization.sentences,
          autocorrect: false,
          decoration: InputDecoration(
            hintText: l10n.sentence_typeHint,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        if (!answered)
          FilledButton(
            onPressed: typed.isEmpty
                ? null
                : () {
                    final m = matchWords(phrase.text, typed);
                    matches.value = m;
                    onAnswer(ok: m.every((w) => w.hit));
                  },
            child: Text(l10n.grammar_check),
          )
        else ...[
          WordMatchText(matches.value!),
          const SizedBox(height: 12),
          AnswerFeedback(
            ok: result!,
            detail: result!
                ? null
                : l10n.sentence_score(_percent(matches.value!)),
            speech: phrase.text,
          ),
        ],
      ],
    );
  }
}

/// Luyện nói: hiện câu mẫu (nghe được), bấm micro đọc to → so từng từ, chấm % khớp.
/// Lần đọc đầu tiên được tính điểm; đọc lại chỉ để luyện thêm.
class _SpeakingView extends HookConsumerWidget {
  const _SpeakingView({
    required this.phrase,
    required this.result,
    required this.onAnswer,
    required this.onSkip,
    super.key,
  });

  final Phrase phrase;
  final bool? result;
  final void Function({required bool ok}) onAnswer;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = context.colors;
    final voice = ref.read(voiceInputProvider);
    final listening = useState(false);
    final heard = useState('');
    final matches = useState<List<({String word, bool hit})>?>(null);
    final unavailable = useState(false);
    final notHeard = useState(false);
    final graded = useRef(false);
    final mounted = useIsMounted();

    useEffect(() => voice.stop, const []);

    void evaluate(String words) {
      listening.value = false;
      if (words.trim().isEmpty) {
        notHeard.value = true;
        return;
      }
      final m = matchWords(phrase.text, words);
      matches.value = m;
      if (!graded.value) {
        graded.value = true;
        onAnswer(ok: _ratio(m) >= _speakingPass);
      }
    }

    Future<void> toggleMic() async {
      if (listening.value) {
        await voice.stop();
        return;
      }
      if (!await voice.ensureReady()) {
        if (mounted()) unavailable.value = true;
        return;
      }
      heard.value = '';
      notHeard.value = false;
      matches.value = null;
      listening.value = true;
      await voice.listen(
        localeId: 'en_US',
        onResult: (words, isFinal) {
          if (!mounted()) return;
          heard.value = words;
          if (isFinal) evaluate(words);
        },
      );
    }

    final m = matches.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.speaking_ask, style: theme.textTheme.titleSmall),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (m == null)
                        Text(phrase.text, style: theme.textTheme.headlineSmall)
                      else
                        WordMatchText(m, style: theme.textTheme.headlineSmall),
                      const SizedBox(height: 4),
                      Text(
                        phrase.meaning,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                SpeakButton(phrase.text, language: 'en-US'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 28),
        Center(
          child: SizedBox.square(
            dimension: 88,
            child: IconButton.filled(
              onPressed: toggleMic,
              style: IconButton.styleFrom(
                backgroundColor: listening.value
                    ? colors.error
                    : colors.primary,
              ),
              icon: Icon(
                listening.value ? Icons.stop_rounded : Icons.mic_rounded,
                size: 44,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          listening.value
              ? l10n.speaking_listening
              : m != null
              ? l10n.speaking_tryAgain
              : l10n.speaking_tap,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
        if (heard.value.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            l10n.speaking_youSaid(heard.value),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(color: colors.textMuted),
          ),
        ],
        if (notHeard.value) ...[
          const SizedBox(height: 12),
          Text(
            l10n.speaking_notHeard,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: colors.warning),
          ),
        ],
        if (m != null) ...[
          const SizedBox(height: 16),
          AnswerFeedback(
            ok: _ratio(m) >= _speakingPass,
            title: l10n.sentence_score(_percent(m)),
          ),
        ],
        if (unavailable.value) ...[
          const SizedBox(height: 16),
          Text(
            l10n.speaking_unavailable,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: colors.error),
          ),
          if (result == null)
            TextButton(onPressed: onSkip, child: Text(l10n.common_skip)),
        ],
      ],
    );
  }
}

double _ratio(List<({String word, bool hit})> m) =>
    m.isEmpty ? 0 : m.where((w) => w.hit).length / m.length;

int _percent(List<({String word, bool hit})> m) => (_ratio(m) * 100).round();
