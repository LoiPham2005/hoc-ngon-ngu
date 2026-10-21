import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';
import 'package:lingua/features/home/home_page.dart';
import 'package:lingua/features/japanese/kana_detail_page.dart';
import 'package:lingua/features/japanese/kana_table_page.dart';
import 'package:lingua/features/japanese/kanji_detail_page.dart';
import 'package:lingua/features/japanese/kanji_list_page.dart';
import 'package:lingua/features/japanese/models/kana_model.dart';
import 'package:lingua/features/japanese/models/kanji_model.dart';
import 'package:lingua/features/learn/learn_page.dart';
import 'package:lingua/features/main/main_page.dart';
import 'package:lingua/features/onboarding/onboarding_page.dart';
import 'package:lingua/features/practice/practice_page.dart';
import 'package:lingua/features/practice/providers/quiz_session_notifier.dart';
import 'package:lingua/features/practice/quiz_page.dart';
import 'package:lingua/features/profile/profile_page.dart';
import 'package:lingua/features/splash/splash_page.dart';

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
    AutoRoute(page: QuizRoute.page, path: '/quiz'),
  ];
}
