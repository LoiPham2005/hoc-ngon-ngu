import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:lingua/config/flavor_config.dart';
import 'package:lingua/core/di/global_providers.dart';
import 'package:lingua/core/services/connectivity_provider.dart';
import 'package:lingua/core/services/remote_config_service.dart';
import 'package:lingua/core/utils/logger.dart';
import 'package:lingua/modules/ads/ad_config.dart';
import 'package:lingua/modules/ads/ad_consent.dart';
import 'package:lingua/modules/ads/ad_loading_overlay.dart';
import 'package:lingua/modules/ads/ad_stats.dart';
import 'package:lingua/modules/ads/full_screen_ads.dart';
import 'package:lingua/modules/ads/widgets/native_ad_full_screen.dart';
import 'package:lingua/modules/analytics/analytics_service.dart';
import 'package:lingua/modules/attribution/attribution_service.dart';
import 'package:lingua/routes/app_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'ad_manager.g.dart';

/// Điểm vào duy nhất của module Ads.
///
/// ```dart
/// final ads = ref.read(adManagerProvider);
/// // Mọi hàm show CHỜ tới khi ad đóng hẳn (không hiện được → xong ngay) → await xong là đi tiếp.
/// await ads.showInterstitial(InterstitialPlacement.lessonDone);  goNext();
/// await ads.showRewarded('streak_freeze', onReward: (r) => keepStreak());
/// await ads.showNativeFull();
/// AdBannerWidget(placement: BannerPlacement.list);  NativeAdWidget(placement: NativePlacement.result);
/// ads.setPremium(true);  ads.pauseAds(const Duration(minutes: 30));
/// ```
class AdManager {
  AdManager(this._prefs, this._remote, this._analytics, this._attribution);

  final SharedPreferences _prefs;
  final RemoteConfigService _remote;
  final AnalyticsService _analytics;
  final AttributionService _attribution;

  /// Đếm request / hiện / bấm theo vị trí trên máy này, in ra Debug Console.
  late final stats = AdStats(_prefs);
  late final interstitial = FullScreenAds.interstitial(
    _analytics,
    reportPaid,
    stats,
  );
  late final appOpen = FullScreenAds.appOpen(_analytics, reportPaid, stats);
  late final rewarded = FullScreenAds.rewarded(_analytics, reportPaid, stats);
  late final rewardedInterstitial = FullScreenAds.rewardedInterstitial(
    _analytics,
    reportPaid,
    stats,
  );
  final consent = AdConsent();
  final _loading = AdLoadingOverlay();

  /// Cấu hình đang áp dụng (đã tính premium / tạm tắt). Widget lắng nghe để ẩn/hiện realtime.
  final config = ValueNotifier<AdConfig>(AdConfig.disabled);

  /// Native toàn màn đang hiện (vẽ bằng Flutter, không đè được banner ngoài Navigator) →
  /// banner phải ẩn: AdMob cấm quảng cáo khác nằm cùng màn quảng cáo toàn màn hình.
  final nativeFullShowing = ValueNotifier<bool>(false);

  static const _kRemoteKey = 'ad_config';

  /// Người dùng mua về (Adjust) → phần khác biệt trộn đè lên [_kRemoteKey].
  static const _kRemoteKeyPaid = 'ad_config_paid';
  static const _kPremium = 'ads_premium';
  static const _kPausedUntil = 'ads_paused_until';

  /// Thêm hashed id máy test (in ra console lần load đầu) — chỉ áp ở dev/stg.
  static const _testDeviceIds = <String>[];

  /// Đang hiện / vừa ĐÓNG ad toàn màn → chặn app open/native full trong 10s (tránh 2 ad
  /// chồng nhau, vd đóng interstitial → app resume → app open).
  static const _cooldown = Duration(seconds: 10);

  AdConfig _base = AdConfig.disabled;
  bool _ready = false;
  DateTime? _lastFullScreenAt;
  DateTime? _pausedUntil;
  Timer? _pauseTimer;
  DateTime? _lastResumeAt;
  AppLifecycleListener? _lifecycle;

  // native full
  final _native = <String, (NativeAd, DateTime)>{};
  final _nativeLoading = <String>{};
  DateTime? _nativeShownAt;
  int _nativeShownCount = 0;

  // ── Khởi tạo ────────────────────────────────────────────────

  /// Gọi 1 lần ở `AppInitializer`, SAU `RemoteConfigService.initialize()`.
  Future<void> initialize() async {
    final ts = _prefs.getInt(_kPausedUntil);
    if (ts != null) _setPause(DateTime.fromMillisecondsSinceEpoch(ts));
    _applyRemote();
    _remote.onUpdated.listen((_) => _applyRemote());
    _attribution.isPaid.addListener(_applyRemote);

    // Consent PHẢI trước MobileAds.initialize. Quá 8s → dùng lựa chọn đã lưu từ lần trước
    // (lần đầu mà chưa có → chưa load ads cho tới lần mở sau).
    await consent.request().timeout(
      const Duration(seconds: 8),
      onTimeout: () => talker.warning('[ADS] consent timeout'),
    );
    await consent.refresh();
    await MobileAds.instance.updateRequestConfiguration(
      RequestConfiguration(
        maxAdContentRating: MaxAdContentRating.t,
        testDeviceIds: FlavorConfig.isProd ? const [] : _testDeviceIds,
      ),
    );
    await MobileAds.instance.initialize().timeout(const Duration(seconds: 15));
    _ready = true;

    config.addListener(_preloadAll);
    // Có mạng lại → nạp lại ad bị lỗi lúc offline.
    globalContainer.listen(isOnlineProvider, (_, next) {
      if (next.value ?? false) _preloadAll();
    });
    // Ra nền → in bảng số liệu quảng cáo ra Debug Console (bản dev/stg).
    _lifecycle = AppLifecycleListener(
      onResume: _onResume,
      onPause: FlavorConfig.isProd ? null : stats.logSummary,
    );
    _preloadAll();
  }

  // ── Toàn màn ────────────────────────────────────────────────

  /// Các hàm show dưới đây CHỜ tới khi ad đóng hẳn rồi mới xong (không hiện được → xong
  /// ngay): `true` = đã hiện; `false` = không hiện (tắt / premium / chưa consent / vượt giới
  /// hạn / cooldown / chưa tải được). Nơi gọi chỉ cần `await` rồi đi tiếp, không cần callback.
  /// [onShowed]: gọi đúng lúc ad lên màn hình (vd tạm dừng game / nhạc — iOS hiện ad không
  /// đổi vòng đời app nên không tự dừng được).

  /// Đóng xong tự hiện native full (nếu unit + config cho phép) — `await` chờ cả 2.
  Future<bool> showInterstitial(
    String placement, {
    bool nativeAfter = true,
    VoidCallback? onShowed,
  }) async {
    final cfg = config.value;
    final unit = cfg.unit(AdType.interstitial, placement);
    if (unit == null || !_canRequest) return false;
    final chain =
        nativeAfter &&
        unit.nativeFullAfter &&
        cfg.enableNativeFullAfterInterstitial;
    if (chain) {
      _preloadNative(
        NativePlacement.afterInterstitial,
      ); // kịp sẵn lúc interstitial đóng
    }
    final shown = await _track(
      interstitial.show(
        placement,
        unit,
        cfg.rules,
        loading: _loading,
        onShowed: onShowed,
      ),
    );
    if (shown && chain) {
      await showNativeFull(
        placement: NativePlacement.afterInterstitial,
        ignoreCooldown: true,
      );
    }
    return shown;
  }

  /// Placement không có unit → dùng unit `resume`.
  /// [timeout]: chờ tải tối đa khi chưa nạp sẵn. [loadingOverlay] `false` ở màn khởi động
  /// (splash vốn đã là màn chờ, không cần thêm "Đang tải quảng cáo…").
  Future<bool> showAppOpen(
    String placement, {
    VoidCallback? onShowed,
    Duration timeout = const Duration(seconds: 5),
    bool loadingOverlay = true,
  }) async {
    final cfg = config.value;
    final unit =
        cfg.unit(AdType.appOpen, placement) ??
        cfg.unit(AdType.appOpen, AppOpenPlacement.resume);
    final blocked = !_canRequest
        ? 'SDK chưa sẵn sàng / chưa có consent'
        : _inCooldown
        ? 'vừa hiện ad toàn màn khác < ${_cooldown.inSeconds}s'
        : null;
    if (unit == null || blocked != null) {
      talker.debug(
        '[ADS] appOpen.$placement bỏ qua: ${blocked ?? 'placement tắt / chưa có unit'}',
      );
      return false;
    }
    return _track(
      appOpen.show(
        placement,
        unit,
        cfg.rules,
        loading: loadingOverlay ? _loading : null,
        onShowed: onShowed,
        timeout: timeout,
      ),
    );
  }

  Future<bool> showRewarded(
    String placement, {
    required void Function(RewardItem reward) onReward,
    VoidCallback? onShowed,
  }) async {
    final cfg = config.value;
    final unit = cfg.unit(AdType.rewarded, placement);
    if (unit == null || !_canRequest) return false;
    return _track(
      rewarded.show(
        placement,
        unit,
        cfg.rules,
        loading: _loading,
        onShowed: onShowed,
        onReward: onReward,
      ),
    );
  }

  /// Rewarded interstitial — hiện ở điểm chuyển màn, user không cần bấm xem vẫn có thưởng.
  Future<bool> showRewardedInterstitial(
    String placement, {
    required void Function(RewardItem reward) onReward,
    VoidCallback? onShowed,
  }) async {
    final cfg = config.value;
    final unit = cfg.unit(AdType.rewardedInterstitial, placement);
    if (unit == null || !_canRequest) return false;
    return _track(
      rewardedInterstitial.show(
        placement,
        unit,
        cfg.rules,
        loading: _loading,
        onShowed: onShowed,
        onReward: onReward,
      ),
    );
  }

  /// Native toàn màn. Chưa sẵn sàng / bị giới hạn → xong ngay (`false`) và nạp sẵn cho lần sau.
  Future<bool> showNativeFull({
    String placement = NativePlacement.full,
    bool ignoreCooldown = false,
    VoidCallback? onShowed,
  }) async {
    final cfg = config.value;
    final rules = cfg.rules;
    final max = rules.maxPerSessionOf(AdType.native);
    final last = _nativeShownAt;
    if (cfg.unit(AdType.native, placement) == null) return false;
    final blocked = (max > 0 && _nativeShownCount >= max)
        ? 'session_cap'
        : (last != null &&
              DateTime.now().difference(last).inSeconds <
                  rules.intervalOf(AdType.native))
        ? 'interval'
        : (!ignoreCooldown && _inCooldown)
        ? 'cooldown'
        : null;
    final entry = blocked != null ? null : _native.remove(placement);
    final context = appRouter.navigatorKey.currentContext;
    if (entry == null || context == null) {
      stats.skip('native.$placement', blocked ?? 'not_ready');
      if (blocked == null) _preloadNative(placement);
      return false;
    }
    _nativeShownAt = DateTime.now();
    _nativeShownCount++;
    _lastFullScreenAt = DateTime.now();
    onShowed?.call();
    nativeFullShowing.value = true;
    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        useSafeArea: false,
        builder: (dialogContext) => NativeAdFullScreen(
          ad: entry.$1,
          onClosed: () => Navigator.of(dialogContext).pop(),
        ),
      );
    } finally {
      nativeFullShowing.value = false;
    }
    // Đóng bằng nút hay nút Back đều tới đây → luôn giải phóng ad.
    unawaited(entry.$1.dispose());
    _lastFullScreenAt = DateTime.now();
    // Nạp sẵn cái kế tiếp chỉ khi bật preload cả chung lẫn riêng vị trí này.
    if (cfg.preload && (cfg.unit(AdType.native, placement)?.preload ?? false)) {
      _preloadNative(placement);
    }
    return true;
  }

  /// Cooldown tính từ lúc ad ĐÓNG (đóng ad → app resume → không bật app open chồng lên).
  Future<bool> _track(Future<bool> show) async {
    final shown = await show;
    if (shown) _lastFullScreenAt = DateTime.now();
    return shown;
  }

  /// Nạp sẵn trước khi vào màn sẽ hiện ad.
  void preload(AdType type, String placement) {
    final cfg = config.value;
    final unit = cfg.unit(type, placement);
    if (unit == null || !_canRequest) return;
    switch (type) {
      case AdType.interstitial:
        unawaited(interstitial.preload(placement, unit));
      case AdType.appOpen:
        unawaited(appOpen.preload(placement, unit));
      case AdType.rewarded:
        unawaited(rewarded.preload(placement, unit));
      case AdType.rewardedInterstitial:
        unawaited(rewardedInterstitial.preload(placement, unit));
      case AdType.native:
        _preloadNative(placement);
      case AdType.banner:
        break; // banner tự load trong widget
    }
  }

  // ── Widget ──────────────────────────────────────────────────

  AdUnit? bannerUnit(String placement) =>
      config.value.unit(AdType.banner, placement);
  AdUnit? nativeUnit(String placement) =>
      config.value.unit(AdType.native, placement);

  // ── Bỏ quảng cáo ────────────────────────────────────────────

  /// Đã mua gói bỏ quảng cáo (lưu máy, sống qua restart).
  bool get isPremium => _prefs.getBool(_kPremium) ?? false;

  Future<void> setPremium(bool value) async {
    await _prefs.setBool(_kPremium, value);
    _emit();
  }

  /// Tắt ads có thời hạn (vd thưởng xem rewarded "30 phút không quảng cáo").
  Future<void> pauseAds(Duration duration) async {
    final until = DateTime.now().add(duration);
    await _prefs.setInt(_kPausedUntil, until.millisecondsSinceEpoch);
    _setPause(until);
  }

  void resumeAds() => _setPause(null);

  /// Thời gian không quảng cáo còn lại (`null` = không tạm tắt).
  Duration? get adFreeRemaining {
    final left = _pausedUntil?.difference(DateTime.now());
    return left != null && left > Duration.zero ? left : null;
  }

  /// Mở form quyền riêng tư (UMP) rồi nạp lại ads theo lựa chọn mới.
  Future<void> showPrivacyOptions() async {
    await consent.showPrivacyOptions();
    _preloadAll();
  }

  /// Xoá giới hạn tần suất như vừa mở app.
  void resetSession() {
    interstitial.resetSession();
    appOpen.resetSession();
    rewarded.resetSession();
    rewardedInterstitial.resetSession();
    _lastFullScreenAt = null;
    _nativeShownAt = null;
    _nativeShownCount = 0;
  }

  void dispose() {
    _lifecycle?.dispose();
    _pauseTimer?.cancel();
  }

  // ── Nội bộ ──────────────────────────────────────────────────

  bool get _canRequest => _ready && consent.canRequestAds;

  bool get _inCooldown {
    if (_fullScreen.any((e) => e.$2.isShowing)) return true;
    final last = _lastFullScreenAt;
    return last != null && DateTime.now().difference(last) < _cooldown;
  }

  void _applyRemote() {
    var base = kDevAdConfig;
    if (_remote.enabled) {
      // Người dùng mua về (chiến dịch trả tiền) → `ad_config_paid` CHỈ ghi phần khác
      // (giãn cách, bật thêm vị trí…) và được trộn đè lên `ad_config`; ID quảng cáo chỉ khai
      // 1 chỗ ở `ad_config`. Chưa khai `ad_config_paid` → dùng nguyên `ad_config`.
      final common = _remote.json(_kRemoteKey);
      final paid = _attribution.isPaid.value
          ? _remote.json(_kRemoteKeyPaid)
          : null;
      _reportUnknownKeys(common);
      final json = common == null || paid == null
          ? common
          : mergeAdConfigJson(common, paid);
      try {
        base = json == null ? AdConfig.disabled : AdConfig.fromJson(json);
      } catch (e, s) {
        talker.error('[ADS] ad_config sai định dạng → tắt ads', e, s);
        base = AdConfig.disabled;
      }
    }
    if (FlavorConfig.isProd) _assertNoTestIds(base);
    _base = base;
    _emit();
  }

  /// Key gõ sai trên Remote Config bị bỏ qua im lặng → báo lỗi (Crashlytics, mỗi lỗi 1 lần /
  /// phiên) để người sửa cấu hình biết. Kiểm cả `ad_config_paid` dù người này không phải
  /// người dùng mua về — sai ở đâu cũng nên biết sớm.
  void _reportUnknownKeys(Map<String, dynamic>? common) {
    final issues = [
      if (common != null)
        for (final k in unknownAdConfigKeys(common)) '$_kRemoteKey.$k',
      if (_remote.json(_kRemoteKeyPaid) case final p?)
        for (final k in unknownAdConfigKeys(p, base: common))
          '$_kRemoteKeyPaid.$k',
    ];
    for (final issue in issues) {
      if (_reportedConfigIssues.add(issue)) {
        talker.error(
          '[ADS] Remote Config: key lạ / gõ sai → bị bỏ qua: $issue',
        );
      }
    }
  }

  final _reportedConfigIssues = <String>{};

  /// Test id lọt lên prod = AdMob khoá account → báo lỗi (Crashlytics) + assert khi debug.
  void _assertNoTestIds(AdConfig cfg) {
    final ids = cfg.adUnits.all
        .where((u) => u.isActive)
        .expand((u) => u.ids)
        .where((id) => id.startsWith(kGoogleTestPublisher))
        .toSet();
    if (ids.isEmpty) return;
    talker.error('[ADS] ⛔ PROD đang dùng Google TEST ad id: ${ids.join(', ')}');
    assert(false, 'PROD chứa Google test ad id: $ids');
  }

  void _emit() {
    final off = isPremium || adFreeRemaining != null;
    config.value = off ? _base.copyWith(showAllAds: false) : _base;
  }

  void _setPause(DateTime? until) {
    _pauseTimer?.cancel();
    final left = until?.difference(DateTime.now());
    if (left == null || left <= Duration.zero) {
      _pausedUntil = null;
      _prefs.remove(_kPausedUntil);
    } else {
      _pausedUntil = until;
      _pauseTimer = Timer(left, () => _setPause(null));
    }
    _emit();
  }

  void _onResume() {
    // Timer bị đóng băng khi app ở nền → tính lại mốc hết hạn.
    if (_pausedUntil != null) _setPause(_pausedUntil);
    final now = DateTime.now();
    final last = _lastResumeAt;
    _lastResumeAt = now;
    if (last != null && now.difference(last) < const Duration(seconds: 1)) {
      return; // chuyển app qua lại liên tục
    }
    unawaited(showAppOpen(AppOpenPlacement.resume));
  }

  List<(AdType, FullScreenAds<AdWithoutView>)> get _fullScreen => [
    (AdType.interstitial, interstitial),
    (AdType.appOpen, appOpen),
    (AdType.rewarded, rewarded),
    (AdType.rewardedInterstitial, rewardedInterstitial),
  ];

  /// Đồng bộ ad giữ sẵn theo config: placement `preload` → giữ sẵn; tắt / premium → dừng
  /// (không request thừa).
  void _preloadAll() {
    final cfg = config.value;
    final on = _canRequest && cfg.showAllAds && cfg.preload;
    // Unit được phép hiện VÀ bật `preload` (unit `preload: false` → chỉ load lúc hiện).
    AdUnit? preloadUnit(AdType type, String placement) {
      final unit = cfg.unit(type, placement);
      return (unit?.preload ?? false) ? unit : null;
    }

    for (final (type, ads) in _fullScreen) {
      final wanted = <String, AdUnit>{
        if (on)
          for (final placement in cfg.adUnits.of(type).keys)
            placement: ?preloadUnit(type, placement),
      };
      for (final placement in ads.preloadingPlacements.toList()) {
        if (!wanted.containsKey(placement)) {
          unawaited(ads.stopPreload(placement));
        }
      }
      wanted.forEach(
        (placement, unit) => unawaited(ads.preload(placement, unit)),
      );
    }
    if (!on) return;
    for (final placement in [
      if (cfg.enableInterstitial && cfg.enableNativeFullAfterInterstitial)
        NativePlacement.afterInterstitial,
      NativePlacement.full,
    ]) {
      if (preloadUnit(AdType.native, placement) != null) {
        _preloadNative(placement);
      }
    }
  }

  /// Doanh thu 1 lượt hiển thị (mọi định dạng) → [stats] + Adjust tính ROAS theo chiến dịch.
  /// Firebase tự ghi doanh thu khi đã liên kết AdMob, không gửi ở đây.
  void reportPaid(
    Ad ad,
    double valueMicros,
    String currency,
    String placement,
  ) {
    stats.paid(placement, valueMicros, currency);
    _attribution.trackAdRevenue(
      valueMicros: valueMicros,
      currency: currency,
      placement: placement,
      adSource: ad.responseInfo?.loadedAdapterResponseInfo?.adSourceName,
      adUnitId: ad.adUnitId,
    );
  }

  /// Nạp sẵn native toàn màn; ID thứ [index] không có ad → thử ID dự phòng kế tiếp.
  void _preloadNative(String placement, [int index = 0]) {
    final unit = config.value.unit(AdType.native, placement);
    if (unit == null || !_canRequest || _nativeLoading.contains(placement)) {
      return;
    }
    final ids = unit.ids;
    if (index >= ids.length) return;
    final cached = _native[placement];
    if (cached != null) {
      if (DateTime.now().difference(cached.$2) < const Duration(hours: 1)) {
        return;
      }
      _native.remove(placement)?.$1.dispose();
    }
    _nativeLoading.add(placement);
    final ad = NativeAd(
      adUnitId: ids[index],
      factoryId: 'nativeFull', // factory native toàn màn (Android/iOS)
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          _nativeLoading.remove(placement);
          _native[placement] = (ad as NativeAd, DateTime.now());
          stats.request('native.$placement', matched: true);
        },
        onAdImpression: (_) => stats.impression('native.$placement'),
        onAdClicked: (_) => stats.click('native.$placement'),
        onPaidEvent: (ad, valueMicros, _, currency) =>
            reportPaid(ad, valueMicros, currency, 'native.$placement'),
        onAdFailedToLoad: (ad, e) {
          _nativeLoading.remove(placement);
          ad.dispose();
          stats.request('native.$placement', matched: false);
          talker.warning('[ADS] native.$placement load failed: ${e.message}');
          _preloadNative(placement, index + 1);
        },
      ),
    );
    unawaited(ad.load());
  }
}

@Riverpod(keepAlive: true)
AdManager adManager(Ref ref) => AdManager(
  ref.read(sharedPrefsProvider),
  ref.read(remoteConfigServiceProvider),
  ref.read(analyticsServiceProvider),
  ref.read(attributionServiceProvider),
);
