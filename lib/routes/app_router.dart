import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';
import 'package:lingua/features/_reference/generated_api/generated_user_list_page.dart';
import 'package:lingua/features/_reference/openapi_user/openapi_user_list_page.dart';
import 'package:lingua/features/_reference/pagination_demo/pagination_demo_page.dart';
import 'package:lingua/features/_reference/voucher/voucher_list_page.dart';
import 'package:lingua/features/ads_demo/ads_demo_page.dart';
import 'package:lingua/features/auth/login_page.dart';
import 'package:lingua/features/auth/register_page.dart';
import 'package:lingua/features/home/home_page.dart';
import 'package:lingua/features/japanese/japanese_page.dart';
import 'package:lingua/features/japanese/kana_detail_page.dart';
import 'package:lingua/features/japanese/kana_quiz_page.dart';
import 'package:lingua/features/japanese/kanji_detail_page.dart';
import 'package:lingua/features/japanese/kanji_quiz_page.dart';
import 'package:lingua/features/japanese/models/kana_model.dart';
import 'package:lingua/features/japanese/models/kanji_model.dart';
import 'package:lingua/features/main/main_page.dart';
import 'package:lingua/features/settings/settings_page.dart';
import 'package:lingua/features/splash/splash_page.dart';
import 'package:lingua/routes/route_guards.dart';

part 'app_router.gr.dart';

/// Router duy nhất của app — dùng `appRouter` ở chỗ không có `context`.
final appRouter = AppRouter();

@AutoRouterConfig(replaceInRouteName: 'Page,Route')
class AppRouter extends RootStackRouter {
  static const _auth = [AuthGuard()];

  @override
  List<AutoRoute> get routes => [
    AutoRoute(page: SplashRoute.page, path: '/splash', initial: true),
    AutoRoute(page: LoginRoute.page, path: '/login'),
    AutoRoute(page: RegisterRoute.page, path: '/register'),
    AutoRoute(page: AdsDemoRoute.page, path: '/ads-demo'),
    // Học tiếng Nhật: Kana + Kanji N5–N2 (dữ liệu local, không cần đăng nhập)
    AutoRoute(page: JapaneseRoute.page, path: '/japanese'),
    AutoRoute(page: KanaDetailRoute.page, path: '/japanese/kana'),
    AutoRoute(page: KanaQuizRoute.page, path: '/japanese/kana-quiz'),
    AutoRoute(page: KanjiDetailRoute.page, path: '/japanese/kanji'),
    AutoRoute(page: KanjiQuizRoute.page, path: '/japanese/kanji-quiz'),
    // Shell bottom nav. KHÔNG đặt path '/': mở app hệ điều hành gửi '/' → phải vào Splash
    // (route initial) để chạy check version + vân tay; '/' mà trỏ Main là bỏ qua Splash.
    AutoRoute(
      page: MainRoute.page,
      path: '/main',
      guards: _auth,
      children: [
        AutoRoute(page: HomeRoute.page, path: ''),
        AutoRoute(page: SettingsRoute.page, path: 'settings'),
      ],
    ),
    AutoRoute(page: PaginationDemoRoute.page, path: '/pagination-demo'),
    AutoRoute(page: OpenapiUserListRoute.page, path: '/users', guards: _auth),
    AutoRoute(
      page: GeneratedUserListRoute.page,
      path: '/users-generated',
      guards: _auth,
    ),
  ];
}
