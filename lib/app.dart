import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingua/config/app_info.dart';
import 'package:lingua/config/system_ui_manager.dart';
import 'package:lingua/core/di/global_providers.dart';
import 'package:lingua/core/services/quick_actions_service.dart';
import 'package:lingua/core/services/session_notifier.dart';
import 'package:lingua/core/utils/logger.dart';
import 'package:lingua/design/l10n/locale_notifier.dart';
import 'package:lingua/design/theme/app_theme.dart';
import 'package:lingua/design/theme/theme_notifier.dart';
import 'package:lingua/gen/l10n/app_localizations.dart';
import 'package:lingua/routes/app_router.dart';
import 'package:lingua/shared/states/app_error_screen.dart';
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
    useEffect(() {
      ErrorWidget.builder = (details) => AppErrorScreen(details: details);
      // Áp lại System UI khi resume (nav bar Android hay lòi ra sau dialog/chuyển app).
      final lifecycle = AppLifecycleListener(
        onResume: SystemUIManager.applyUiMode,
      );
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => AppQuickActions.init(),
      );
      return lifecycle.dispose;
    }, const <Object?>[]);

    ref.listen(sessionProvider, (previous, isAuthenticated) {
      if (previous == true && !isAuthenticated) {
        appRouter.replaceAll([const LoginRoute()]);
      }
      if (previous != isAuthenticated) {
        AppQuickActions.update(isAuthenticated: isAuthenticated);
      }
    });

    return ToastificationWrapper(
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: AppInfo.appName,
        theme: AppTheme.fromVariant(ref.watch(themeProvider)),
        locale: ref.watch(localeProvider),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: appRouter.config(
          navigatorObservers: () => [TalkerRouteObserver(talker)],
        ),
        builder: (context, child) => ConnectivityBanner(
          child: FlutterSmartDialog.init()(context, child),
        ),
      ),
    );
  }
}
