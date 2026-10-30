import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingua/config/app_info.dart';
import 'package:lingua/config/system_ui_manager.dart';
import 'package:lingua/core/di/global_providers.dart';
import 'package:lingua/core/services/quick_actions_service.dart';
import 'package:lingua/core/utils/logger.dart';
import 'package:lingua/design/l10n/locale_notifier.dart';
import 'package:lingua/design/theme/app_palette.dart';
import 'package:lingua/design/theme/app_theme.dart';
import 'package:lingua/design/theme/styles/app_dimensions.dart';
import 'package:lingua/design/theme/theme_notifier.dart';
import 'package:lingua/features/profile/providers/reminder_notifier.dart';
import 'package:lingua/gen/l10n/app_localizations.dart';
import 'package:lingua/modules/ads/ad_config.dart';
import 'package:lingua/modules/ads/ad_manager.dart';
import 'package:lingua/modules/ads/ad_route_observer.dart';
import 'package:lingua/modules/ads/widgets/ad_banner_host.dart';
import 'package:lingua/modules/analytics/analytics_route_observer.dart';
import 'package:lingua/modules/analytics/analytics_service.dart';
import 'package:lingua/modules/app_config/app_gate.dart';
import 'package:lingua/routes/app_router.dart';
import 'package:lingua/shared/states/connectivity_banner.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:toastification/toastification.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) => UncontrolledProviderScope(
    container: globalContainer,
    child: const _AppView(),
  );
}

class _AppView extends HookConsumerWidget {
  const _AppView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Ghi màn đang xem lên Analytics; MainRoute chỉ là khung tab (tab bên trong tự ghi).
    final screens = useMemoized(
      () => ScreenTracker(
        ref.read(analyticsServiceProvider),
        shells: {MainRoute.name},
      ),
    );
    // Tạo 1 lần: gọi `appRouter.config()` trong build là mỗi lần đổi theme / ngôn ngữ lại tạo
    // RouterConfig (bộ phân tích đường dẫn…) mới.
    final routerConfig = useMemoized(
      () => appRouter.config(
        navigatorObservers: () => [
          TalkerRouteObserver(talker),
          AnalyticsRouteObserver(screens),
          // Mở một học phần từ màn Khoá học → interstitial (điểm chuyển màn tự nhiên).
          AdRouteObserver(
            ref.read(adManagerProvider),
            {
              for (final route in _contentRoutes)
                route: InterstitialPlacement.openContent,
              for (final route in _detailRoutes)
                route: InterstitialPlacement.openDetail,
              for (final route in _practiceRoutes)
                route: InterstitialPlacement.practiceStart,
            },
            tabPlacement: InterstitialPlacement.tabSwitch,
          ),
        ],
      ),
    );
    useEffect(() {
      // Áp lại System UI khi resume (nav bar Android hay lòi ra sau dialog/chuyển app).
      final lifecycle = AppLifecycleListener(
        onResume: SystemUIManager.applyUiMode,
      );
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => AppQuickActions.init(),
      );
      return lifecycle.dispose;
    }, const <Object?>[]);

    // Đổi ngôn ngữ app → tên shortcut + nội dung nhắc học đổi theo.
    ref.listen(localeProvider, (_, _) {
      AppQuickActions.update();
      ref.read(reminderProvider.notifier).sync();
    });
    final theme = ref.watch(themeProvider);

    return ToastificationWrapper(
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: AppInfo.appName,
        theme: AppTheme.build(theme.accent, Brightness.light),
        darkTheme: AppTheme.build(theme.accent, Brightness.dark),
        themeMode: theme.mode,
        locale: ref.watch(localeProvider),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: routerConfig,
        builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
          // Icon status bar sáng/tối theo theme (màn không có AppBar vẫn đúng).
          value:
              (Theme.of(context).brightness == Brightness.dark
                      ? SystemUiOverlayStyle.light
                      : SystemUiOverlayStyle.dark)
                  .copyWith(statusBarColor: AppPalette.transparent),
          child: MediaQuery.withClampedTextScaling(
            minScaleFactor: AppDimensions.minTextScale,
            maxScaleFactor: AppDimensions.maxTextScale,
            child: ConnectivityBanner(
              child: AppGate(
                child: AdBannerHost(
                  route: screens.route,
                  placement: BannerPlacement.list,
                  hiddenOn: _noBannerRoutes,
                  suppressed: ref.read(adManagerProvider).nativeFullShowing,
                  child: FlutterSmartDialog.init()(context, child),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Màn làm bài: không banner (không làm người học mất tập trung); vào màn → interstitial
/// `practice_start` (chưa làm câu nào nên không cắt ngang).
final _practiceRoutes = {
  QuizRoute.name,
  GrammarPracticeRoute.name,
  DialogueQuizRoute.name,
  SentencePracticeRoute.name,
  MinimalPairQuizRoute.name,
  IrregularTypingRoute.name,
  PhraseOrderRoute.name,
};

/// Mở app lần đầu / đang làm bài → không banner.
final _noBannerRoutes = {
  SplashRoute.name,
  OnboardingRoute.name,
  ..._practiceRoutes,
};

/// Màn chi tiết / tra cứu → interstitial `open_detail`.
final _detailRoutes = {
  WordDetailRoute.name,
  KanaDetailRoute.name,
  KanjiDetailRoute.name,
  GrammarLessonRoute.name,
  DialogueRoute.name,
  VocabListRoute.name,
  PracticeRoute.name,
  SearchRoute.name,
  StatsRoute.name,
};

/// Màn mở ra từ thẻ học phần ở Khoá học → interstitial `open_content`.
final _contentRoutes = {
  KanaTableRoute.name,
  KanjiListRoute.name,
  PronunciationRoute.name,
  TopicsRoute.name,
  PhraseListRoute.name,
  GrammarListRoute.name,
  DialogueListRoute.name,
  MinimalPairsRoute.name,
  IrregularVerbsRoute.name,
};
