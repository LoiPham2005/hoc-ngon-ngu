import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingua/modules/analytics/analytics_route_observer.dart';
import 'package:lingua/modules/analytics/analytics_service.dart';

class _FakeAnalytics extends AnalyticsService {
  final screens = <String>[];

  @override
  Future<void> logScreenView(String screenName) async =>
      screens.add(screenName);
}

Route<void> _page(String name) => MaterialPageRoute<void>(
  settings: RouteSettings(name: name),
  builder: (_) => const SizedBox(),
);

Route<void> _dialog() =>
    RawDialogRoute<void>(pageBuilder: (_, _, _) => const SizedBox());

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeAnalytics analytics;
  late ScreenTracker screens;
  late AnalyticsRouteObserver observer;

  setUp(() {
    analytics = _FakeAnalytics();
    screens = ScreenTracker(analytics, shells: {'MainRoute'});
    observer = AnalyticsRouteObserver(screens);
  });

  test('logs each page once, without the "Route" suffix', () {
    final splash = _page('SplashRoute');
    observer.didPush(splash, null);
    observer.didPush(_page('LoginRoute'), splash);
    observer.didReplace(newRoute: _page('LoginRoute'));
    expect(analytics.screens, ['Splash', 'Login']);
  });

  test('dialogs are not screens; popping back logs the page below', () {
    final home = _page('HomeRoute');
    final detail = _page('DetailRoute');
    final dialog = _dialog();
    observer
      ..didPush(home, null)
      ..didPush(dialog, home)
      ..didPop(dialog, home)
      ..didPush(detail, home)
      ..didPop(detail, home);
    expect(analytics.screens, ['Home', 'Detail', 'Home']);
  });

  test('tab shell is skipped; returning to it logs the open tab', () {
    final main = _page('MainRoute');
    final detail = _page('DetailRoute');
    observer.didPush(main, null);
    screens
      ..tab('HomeRoute')
      ..tab('SettingsRoute');
    observer
      ..didPush(detail, main)
      ..didPop(detail, main);
    expect(analytics.screens, ['Home', 'Settings', 'Detail', 'Settings']);
  });
}
