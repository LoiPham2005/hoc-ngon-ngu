import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';
import 'package:lingua/modules/analytics/analytics_service.dart';

/// Ghi `screen_view` mỗi lần chuyển màn / đổi tab → Firebase biết màn nào vào nhiều / ít,
/// người dùng đi tiếp đâu và rời app ở màn nào (xem skill modules → Analytics).
/// Tên màn = tên route bỏ đuôi "Route" (`HomeRoute` → `Home`); dialog / bottom sheet không tính.
///
/// Mỗi Navigator (gốc, tab, router lồng) có 1 observer riêng → dùng chung 1 [ScreenTracker].
class AnalyticsRouteObserver extends AutoRouterObserver {
  AnalyticsRouteObserver(this._screens);

  final ScreenTracker _screens;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _page(route);

  /// Đóng màn → màn bên dưới hiện lại (đóng dialog thì màn dưới vẫn là màn cũ → không ghi lại).
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _page(previousRoute);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      _page(newRoute);

  @override
  void didInitTabRoute(TabPageRoute route, TabPageRoute? previousRoute) =>
      _screens.tab(route.name);

  @override
  void didChangeTabRoute(TabPageRoute route, TabPageRoute previousRoute) =>
      _screens.tab(route.name);

  void _page(Route<dynamic>? route) {
    final name = route?.settings.name;
    if (route is PageRoute && name != null) _screens.page(name);
  }
}

/// Màn đang hiện, dùng chung cho mọi [AnalyticsRouteObserver].
class ScreenTracker {
  ScreenTracker(this._analytics, {this.shells = const {}});

  final AnalyticsService _analytics;

  /// Route chỉ là khung chứa tab (vd `MainRoute`): không tính là 1 màn — tab bên trong tự ghi;
  /// quay về khung (đóng màn chi tiết) → ghi lại tab đang mở.
  final Set<String> shells;

  String? _current;
  String? _tab;

  void page(String name) {
    if (shells.contains(name)) {
      if (_tab case final tab?) _log(tab);
      return;
    }
    _log(name);
  }

  void tab(String name) {
    _tab = name;
    _log(name);
  }

  void _log(String name) {
    if (name == _current) return;
    _current = name;
    final screen = name.endsWith('Route')
        ? name.substring(0, name.length - 'Route'.length)
        : name;
    unawaited(_analytics.logScreenView(screen));
  }
}
