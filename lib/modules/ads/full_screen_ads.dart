import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:lingua/core/utils/logger.dart';
import 'package:lingua/modules/ads/ad_config.dart';
import 'package:lingua/modules/ads/ad_loading_overlay.dart';
import 'package:lingua/modules/analytics/analytics_service.dart';

/// Preloader chính thức của SDK (≥ 9.1.0): tự giữ sẵn ad, tự nạp lại sau khi lấy ra,
/// tự xử lý hết hạn + retry.
typedef _Preloader<T> = ({
  Future<void> Function({
    required String preloadId,
    required PreloadConfiguration preloadConfiguration,
    required PreloadCallback callback,
  })
  start,
  Future<T?> Function(String preloadId) poll,
  Future<void> Function(String preloadId) destroy,
});

/// Hiện 1 loại ad toàn màn (interstitial, app open, rewarded, rewarded interstitial):
/// lấy ad từ preloader (placement `preload: true`) hoặc load ngay lúc hiện,
/// giới hạn tần suất theo loại, đo impression / click / doanh thu.
class FullScreenAds<T extends AdWithoutView> {
  FullScreenAds._(
    this.type,
    this._analytics, {
    required this.load,
    required this.attach,
    required this.present,
    this.preloader,
  });

  static FullScreenAds<InterstitialAd> interstitial(AnalyticsService a) =>
      FullScreenAds._(
        AdType.interstitial,
        a,
        load: (id, ok, fail) => InterstitialAd.load(
          adUnitId: id,
          request: const AdRequest(),
          adLoadCallback: InterstitialAdLoadCallback(
            onAdLoaded: ok,
            onAdFailedToLoad: fail,
          ),
        ),
        attach: (ad, cb) => ad.fullScreenContentCallback = cb,
        present: (ad, _) => ad.show(),
        preloader: (
          start: InterstitialAdPreloader.start,
          poll: InterstitialAdPreloader.pollAd,
          destroy: InterstitialAdPreloader.destroy,
        ),
      );

  static FullScreenAds<AppOpenAd> appOpen(AnalyticsService a) =>
      FullScreenAds._(
        AdType.appOpen,
        a,
        load: (id, ok, fail) => AppOpenAd.load(
          adUnitId: id,
          request: const AdRequest(),
          adLoadCallback: AppOpenAdLoadCallback(
            onAdLoaded: ok,
            onAdFailedToLoad: fail,
          ),
        ),
        attach: (ad, cb) => ad.fullScreenContentCallback = cb,
        present: (ad, _) => ad.show(),
        preloader: (
          start: AppOpenAdPreloader.start,
          poll: AppOpenAdPreloader.pollAd,
          destroy: AppOpenAdPreloader.destroy,
        ),
      );

  static FullScreenAds<RewardedAd> rewarded(AnalyticsService a) =>
      FullScreenAds._(
        AdType.rewarded,
        a,
        load: (id, ok, fail) => RewardedAd.load(
          adUnitId: id,
          request: const AdRequest(),
          rewardedAdLoadCallback: RewardedAdLoadCallback(
            onAdLoaded: ok,
            onAdFailedToLoad: fail,
          ),
        ),
        attach: (ad, cb) => ad.fullScreenContentCallback = cb,
        present: (ad, onReward) =>
            ad.show(onUserEarnedReward: (_, reward) => onReward?.call(reward)),
        preloader: (
          start: RewardedAdPreloader.start,
          poll: RewardedAdPreloader.pollAd,
          destroy: RewardedAdPreloader.destroy,
        ),
      );

  /// SDK chưa có preloader cho loại này → nạp sẵn 1 ad tự giữ (hết hạn sau 1h).
  static FullScreenAds<RewardedInterstitialAd> rewardedInterstitial(
    AnalyticsService a,
  ) => FullScreenAds._(
    AdType.rewardedInterstitial,
    a,
    load: (id, ok, fail) => RewardedInterstitialAd.load(
      adUnitId: id,
      request: const AdRequest(),
      rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
        onAdLoaded: ok,
        onAdFailedToLoad: fail,
      ),
    ),
    attach: (ad, cb) => ad.fullScreenContentCallback = cb,
    present: (ad, onReward) =>
        ad.show(onUserEarnedReward: (_, reward) => onReward?.call(reward)),
  );

  final AdType type;
  final AnalyticsService _analytics;
  final void Function(
    String id,
    void Function(T ad) onLoaded,
    void Function(LoadAdError e) onFailed,
  )
  load;
  final void Function(T ad, FullScreenContentCallback<T> cb) attach;
  final Future<void> Function(T ad, void Function(RewardItem)? onReward)
  present;
  final _Preloader<T>? preloader;

  /// placement → ad unit id đang chạy preloader.
  final _preloading = <String, String>{};

  /// Ad tự nạp sẵn cho loại không có preloader.
  final _ready = <String, (T, DateTime)>{};
  final _loading = <String>{};

  bool _showing = false;
  DateTime? _lastShownAt;
  int _shownCount = 0;

  String _preloadId(String placement) => '${type.name}.$placement';

  /// Bắt đầu giữ sẵn ad cho placement (gọi lại an toàn; đổi ad id → khởi động lại).
  Future<void> preload(String placement, AdUnit unit) async {
    final p = preloader;
    if (p == null) {
      unawaited(_preloadManually(placement, unit));
      return;
    }
    if (_preloading[placement] == unit.id) return;
    if (_preloading.containsKey(placement)) {
      await p.destroy(_preloadId(placement));
    }
    _preloading[placement] = unit.id;
    await p.start(
      preloadId: _preloadId(placement),
      preloadConfiguration: PreloadConfiguration(
        adUnitId: unit.id,
        bufferSize: 1,
      ),
      callback: PreloadCallback(
        onAdFailedToPreload: (id, e) =>
            talker.warning('[ADS] $id preload failed: ${e.code} ${e.message}'),
      ),
    );
  }

  /// Ngừng giữ sẵn ad (placement bị tắt / unit đổi sang không preload).
  Future<void> stopPreload(String placement) async {
    final ready = _ready.remove(placement);
    if (ready != null) unawaited(ready.$1.dispose());
    if (_preloading.remove(placement) != null) {
      await preloader?.destroy(_preloadId(placement));
    }
  }

  /// Placement đang được giữ sẵn ad.
  Iterable<String> get preloadingPlacements => {
    ..._preloading.keys,
    ..._ready.keys,
  };

  /// Hiện ad và CHỜ tới khi ad đóng hẳn: `true` = đã hiện rồi đóng; `false` = không hiện
  /// được (vượt giới hạn, không có ad / load quá [timeout], lỗi hiện).
  Future<bool> show(
    String placement,
    AdUnit unit,
    AdRules rules, {
    AdLoadingOverlay? loading,
    VoidCallback? onShowed,
    void Function(RewardItem reward)? onReward,
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final name = _preloadId(placement);
    final blocked = _showing
        ? 'đang hiện 1 ad ${type.name}'
        : _limitReason(rules);
    if (blocked != null) {
      talker.warning('[ADS] $name bỏ qua: $blocked');
      return false;
    }
    _showing = true;
    var presented = false;
    final closed = Completer<bool>();
    // Ad sẵn thì lấy ngay (không thấy lớp phủ); phải tải tại chỗ > 300ms → hiện "Đang tải…".
    final loadingTimer = loading == null
        ? null
        : Timer(const Duration(milliseconds: 300), loading.show);
    try {
      unawaited(_analytics.logEvent('ad_requested', {'ad_unit_name': name}));
      final ad = await _take(placement, unit, timeout);
      if (ad == null) return false;
      ad.onPaidEvent = (_, valueMicros, _, currency) => _analytics.logAdRevenue(
        valueMicros: valueMicros,
        currency: currency,
        adUnitName: name,
        adFormat: type.name,
      );
      attach(
        ad,
        FullScreenContentCallback<T>(
          onAdShowedFullScreenContent: (_) {
            _lastShownAt = DateTime.now();
            _shownCount++;
            _analytics.logEvent('ad_impression_custom', {'ad_unit_name': name});
            loading?.hide();
            onShowed?.call();
          },
          onAdClicked: (_) =>
              _analytics.logEvent('ad_click', {'ad_unit_name': name}),
          onAdDismissedFullScreenContent: (ad) {
            ad.dispose();
            _showing = false;
            if (preloader == null && unit.preload) {
              unawaited(_preloadManually(placement, unit));
            }
            closed.complete(true);
          },
          onAdFailedToShowFullScreenContent: (ad, e) {
            ad.dispose();
            _showing = false;
            talker.warning('[ADS] $name show failed: ${e.code} ${e.message}');
            closed.complete(false);
          },
        ),
      );
      await present(ad, onReward);
      presented = true; // callback dismiss/failed sẽ mở khoá `_showing`
      return await closed.future;
    } catch (e, s) {
      talker.error('[ADS] $name show threw', e, s);
      return false;
    } finally {
      loadingTimer?.cancel();
      loading?.hide();
      if (!presented) _showing = false;
    }
  }

  /// Đang hiện trên màn hình.
  bool get isShowing => _showing;

  void resetSession() {
    _shownCount = 0;
    _lastShownAt = null;
  }

  /// Lý do bị chặn bởi `rules`; `null` = được hiện.
  String? _limitReason(AdRules rules) {
    final max = rules.maxPerSessionOf(type);
    if (max > 0 && _shownCount >= max) {
      return 'đã hiện $_shownCount/$max lần trong phiên '
          '(max_${type.name}_per_session; phiên = tới khi kill app)';
    }
    final last = _lastShownAt;
    final gap = last == null ? null : DateTime.now().difference(last).inSeconds;
    final interval = rules.intervalOf(type);
    if (gap != null && gap < interval) {
      return 'mới cách lần trước ${gap}s < ${interval}s (${type.name}_interval)';
    }
    return null;
  }

  /// Lấy ad đã giữ sẵn; không có thì load ngay (chờ tối đa [timeout]).
  Future<T?> _take(String placement, AdUnit unit, Duration timeout) async {
    if (_preloading[placement] == unit.id) {
      final ad = await preloader!.poll(_preloadId(placement));
      if (ad != null) return ad;
    }
    final ready = _ready.remove(placement);
    if (ready != null) {
      if (DateTime.now().difference(ready.$2) < const Duration(hours: 1)) {
        return ready.$1;
      }
      unawaited(ready.$1.dispose());
    }
    return _loadNow(unit.id).timeout(timeout, onTimeout: () => null);
  }

  Future<T?> _loadNow(String id) {
    final done = Completer<T?>();
    load(id, done.complete, (e) {
      talker.warning('[ADS] ${type.name} load failed: ${e.code} ${e.message}');
      _analytics.logEvent('ad_load_failed', {
        'ad_format': type.name,
        'error_code': e.code,
      });
      done.complete(null);
    });
    return done.future;
  }

  Future<void> _preloadManually(String placement, AdUnit unit) async {
    if (_ready.containsKey(placement) || !_loading.add(placement)) return;
    final ad = await _loadNow(unit.id);
    _loading.remove(placement);
    if (ad != null) _ready[placement] = (ad, DateTime.now());
  }
}
