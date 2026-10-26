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
/// giới hạn tần suất theo loại, đo lượt hiện theo placement (doanh thu: Firebase tự ghi).
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

  /// placement → các ad unit id (chính + dự phòng) đang chạy preloader, theo thứ tự ưu tiên.
  final _preloading = <String, List<String>>{};

  /// Ad tự nạp sẵn cho loại không có preloader.
  final _ready = <String, (T, DateTime)>{};
  final _loading = <String>{};

  bool _showing = false;
  DateTime? _lastShownAt;
  int _shownCount = 0;

  String _preloadId(String placement) => '${type.name}.$placement';

  /// Preloader thứ [i] của placement (0 = id chính, giữ nguyên tên cũ).
  String _preloadIdAt(String placement, int i) =>
      i == 0 ? _preloadId(placement) : '${_preloadId(placement)}#$i';

  /// Bắt đầu giữ sẵn ad cho placement (gọi lại an toàn; đổi ad id → khởi động lại).
  /// Có ID dự phòng → giữ sẵn song song mỗi ID 1 ad; lúc hiện ưu tiên ID đứng trước (giá cao).
  Future<void> preload(String placement, AdUnit unit) async {
    final p = preloader;
    if (p == null) {
      unawaited(_preloadManually(placement, unit));
      return;
    }
    final ids = unit.ids;
    final current = _preloading[placement];
    if (current != null && listEquals(current, ids)) return;
    if (current != null) await _destroyPreloads(placement, current.length);
    _preloading[placement] = ids;
    for (final (i, id) in ids.indexed) {
      await p.start(
        preloadId: _preloadIdAt(placement, i),
        preloadConfiguration: PreloadConfiguration(adUnitId: id, bufferSize: 1),
        callback: PreloadCallback(
          onAdFailedToPreload: (id, e) => talker.warning(
            '[ADS] $id preload failed: ${e.code} ${e.message}',
          ),
        ),
      );
    }
  }

  /// Ngừng giữ sẵn ad (placement bị tắt / unit đổi sang không preload).
  Future<void> stopPreload(String placement) async {
    final ready = _ready.remove(placement);
    if (ready != null) unawaited(ready.$1.dispose());
    final ids = _preloading.remove(placement);
    if (ids != null) await _destroyPreloads(placement, ids.length);
  }

  Future<void> _destroyPreloads(String placement, int count) async {
    for (var i = 0; i < count; i++) {
      await preloader?.destroy(_preloadIdAt(placement, i));
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
      // Doanh thu / click: KHÔNG tự ghi — liên kết AdMob ↔ Firebase thì Firebase tự ghi
      // `ad_impression` (kèm doanh thu, mọi định dạng, cả mạng mediation) + `ad_click`.
      // Tự ghi thêm = đếm đôi doanh thu trong Analytics.
      attach(
        ad,
        FullScreenContentCallback<T>(
          onAdShowedFullScreenContent: (_) {
            _lastShownAt = DateTime.now();
            _shownCount++;
            // Theo placement + mạng nào thắng (mediation) — Firebase chỉ biết theo ad unit.
            _analytics.logEvent('ad_impression_custom', {
              'ad_unit_name': name,
              'ad_source':
                  ad.responseInfo?.loadedAdapterResponseInfo?.adSourceName ??
                  '',
            });
            loading?.hide();
            onShowed?.call();
          },
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

  /// Lấy ad đã giữ sẵn (ID giá cao trước); không có thì tải ngay theo thứ tự ID, chờ tối đa
  /// [timeout]. Quá giờ mà ad về muộn → giữ lại cho lần sau, không bỏ phí.
  Future<T?> _take(String placement, AdUnit unit, Duration timeout) async {
    final ids = unit.ids;
    if (listEquals(_preloading[placement], ids)) {
      for (var i = 0; i < ids.length; i++) {
        final ad = await preloader!.poll(_preloadIdAt(placement, i));
        if (ad != null) return ad;
      }
    }
    final ready = _ready.remove(placement);
    if (ready != null) {
      if (DateTime.now().difference(ready.$2) < const Duration(hours: 1)) {
        return ready.$1;
      }
      unawaited(ready.$1.dispose());
    }
    final loading = _loadFirst(ids);
    return loading.timeout(
      timeout,
      onTimeout: () {
        unawaited(loading.then((late) => _keep(placement, late)));
        return null;
      },
    );
  }

  /// Thử lần lượt từng ID tới khi có ad (ID đầu thường đặt giá sàn cao).
  Future<T?> _loadFirst(List<String> ids) async {
    for (final id in ids) {
      final ad = await _loadNow(id);
      if (ad != null) return ad;
    }
    return null;
  }

  /// Giữ ad tải xong muộn cho lần hiện sau (đã có ad giữ sẵn → bỏ).
  void _keep(String placement, T? ad) {
    if (ad == null) return;
    if (_ready.containsKey(placement)) {
      unawaited(ad.dispose());
    } else {
      _ready[placement] = (ad, DateTime.now());
    }
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
    final ad = await _loadFirst(unit.ids);
    _loading.remove(placement);
    if (ad != null) _ready[placement] = (ad, DateTime.now());
  }
}
