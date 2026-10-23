import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';
import 'package:lingua/features/course/models/course_model.dart';
import 'package:lingua/features/home/home_page.dart';
import 'package:lingua/features/japanese/kana_detail_page.dart';
import 'package:lingua/features/japanese/kana_table_page.dart';
import 'package:lingua/features/japanese/kanji_detail_page.dart';
import 'package:lingua/features/japanese/kanji_list_page.dart';
import 'package:lingua/features/japanese/models/kana_model.dart';
import 'package:lingua/features/japanese/models/kanji_model.dart';
import 'package:lingua/features/learn/learn_page.dart';
import 'package:lingua/features/lessons/dialogue_list_page.dart';
import 'package:lingua/features/lessons/dialogue_page.dart';
import 'package:lingua/features/lessons/grammar_lesson_page.dart';
import 'package:lingua/features/lessons/grammar_list_page.dart';
import 'package:lingua/features/lessons/grammar_practice_page.dart';
import 'package:lingua/features/lessons/irregular_typing_page.dart';
import 'package:lingua/features/lessons/irregular_verbs_page.dart';
import 'package:lingua/features/lessons/minimal_pairs_page.dart';
import 'package:lingua/features/lessons/phrase_list_page.dart';
import 'package:lingua/features/lessons/phrase_order_page.dart';
import 'package:lingua/features/lessons/pronunciation_page.dart';
import 'package:lingua/features/lessons/sentence_practice_page.dart';
import 'package:lingua/features/lessons/topics_page.dart';
import 'package:lingua/features/lessons/vocab_list_page.dart';
import 'package:lingua/features/lessons/word_detail_page.dart';
import 'package:lingua/features/main/main_page.dart';
import 'package:lingua/features/onboarding/onboarding_page.dart';
import 'package:lingua/features/practice/practice_page.dart';
import 'package:lingua/features/practice/providers/quiz_session_notifier.dart';
import 'package:lingua/features/practice/quiz_page.dart';
import 'package:lingua/features/profile/profile_page.dart';
import 'package:lingua/features/profile/voice_settings_page.dart';
import 'package:lingua/features/search/search_page.dart';
import 'package:lingua/features/splash/splash_page.dart';
import 'package:lingua/features/stats/stats_page.dart';

part 'app_router.gr.dart';

/// Router duy nhất của app — dùng `appRouter` ở chỗ không có `context`.
final appRouter = AppRouter();

@AutoRouterConfig(replaceInRouteName: 'Page,Route')
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(page: SplashRoute.page, path: '/splash', initial: true),
    AutoRoute(page: OnboardingRoute.page, path: '/onboarding'),
    // Shell 4 tab. KHÔNG đặt path '/': mở app hệ điều hành gửi '/' → phải vào Splash (initial).
    AutoRoute(
      page: MainRoute.page,
      path: '/main',
      children: [
        AutoRoute(page: HomeRoute.page, path: ''),
        AutoRoute(page: LearnRoute.page, path: 'learn'),
        AutoRoute(page: PracticeRoute.page, path: 'practice'),
        AutoRoute(page: ProfileRoute.page, path: 'profile'),
      ],
    ),
    AutoRoute(page: KanaTableRoute.page, path: '/kana'),
    AutoRoute(page: KanaDetailRoute.page, path: '/kana/detail'),
    AutoRoute(page: KanjiListRoute.page, path: '/kanji'),
    AutoRoute(page: KanjiDetailRoute.page, path: '/kanji/detail'),
    AutoRoute(page: PronunciationRoute.page, path: '/en/pronunciation'),
    AutoRoute(page: TopicsRoute.page, path: '/en/topics'),
    AutoRoute(page: VocabListRoute.page, path: '/en/vocab'),
    AutoRoute(page: WordDetailRoute.page, path: '/en/word'),
    AutoRoute(page: PhraseListRoute.page, path: '/en/phrases'),
    AutoRoute(page: GrammarListRoute.page, path: '/en/grammar'),
    AutoRoute(page: GrammarLessonRoute.page, path: '/en/grammar/lesson'),
    AutoRoute(page: GrammarPracticeRoute.page, path: '/en/grammar/practice'),
    AutoRoute(page: DialogueListRoute.page, path: '/en/dialogues'),
    AutoRoute(page: DialogueRoute.page, path: '/en/dialogue'),
    AutoRoute(page: DialogueQuizRoute.page, path: '/en/dialogue/quiz'),
    AutoRoute(page: SentencePracticeRoute.page, path: '/en/sentences'),
    AutoRoute(page: IrregularVerbsRoute.page, path: '/en/irregular-verbs'),
    AutoRoute(
      page: IrregularTypingRoute.page,
      path: '/en/irregular-verbs/typing',
    ),
    AutoRoute(page: MinimalPairsRoute.page, path: '/en/minimal-pairs'),
    AutoRoute(page: MinimalPairSetRoute.page, path: '/en/minimal-pairs/set'),
    AutoRoute(page: MinimalPairQuizRoute.page, path: '/en/minimal-pairs/quiz'),
    AutoRoute(page: PhraseOrderRoute.page, path: '/phrases/order'),
    AutoRoute(page: VoiceSettingsRoute.page, path: '/settings/voices'),
    AutoRoute(page: QuizRoute.page, path: '/quiz'),
    AutoRoute(page: SearchRoute.page, path: '/search'),
    AutoRoute(page: StatsRoute.page, path: '/stats'),
  ];
}
