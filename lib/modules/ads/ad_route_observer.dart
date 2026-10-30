import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';
import 'package:lingua/modules/ads/ad_manager.dart';

/// Hiện interstitial khi người dùng MỞ một màn trong [triggers] (route → placement) — điểm chuyển
/// màn tự nhiên do chính họ bấm. Dùng chung giới hạn của loại interstitial (`rules`) với các
/// vị trí khác, nên không bị dồn quảng cáo. Quay lại (pop) không tính.
class AdRouteObserver extends AutoRouterObserver {
  AdRouteObserver(this._ads, this.triggers);

  final AdManager _ads;
  final Map<String, String> triggers;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final placement = triggers[route.settings.name];
    if (route is! PageRoute || placement == null) return;
    // Sau khung hình đầu của màn mới: ad phủ lên, đóng ad là thấy nội dung ngay.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => unawaited(_ads.showInterstitial(placement)),
    );
  }
}
