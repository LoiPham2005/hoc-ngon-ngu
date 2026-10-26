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
import 'package:lingua/modules/ads/full_screen_ads.dart';
import 'package:lingua/modules/ads/widgets/native_ad_full_screen.dart';
import 'package:lingua/modules/analytics/analytics_service.dart';
import 'package:lingua/routes/app_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'ad_manager.g.dart';

/// Điểm vào duy nhất của module Ads.
///
/// ```dart
/// final ads = ref.read(adManagerProvider);
/// await ads.showInterstitial(InterstitialPlacement.splash, onDismissed: goNext);
/// await ads.showRewarded(RewardedPlacement.bonus, onReward: (r) => addCoin(r.amount));
/// await ads.showRewardedInterstitial(RewardedInterstitialPlacement.levelEnd, onReward: (r) => ...);
/// ads.showNativeFull();
/// AdBannerWidget(placement: BannerPlacement.home);  NativeAdWidget(placement: NativePlacement.home);
/// ads.setPremium(true);  ads.pauseAds(const Duration(minutes: 30));
/// ```
class AdManager {
  AdManager(this._prefs, this._remote, AnalyticsService analytics)
    : interstitial = FullScreenAds.interstitial(analytics),
      appOpen = FullScreenAds.appOpen(analytics),
      rewarded = FullScreenAds.rewarded(analytics),
      rewardedInterstitial = FullScreenAds.rewardedInterstitial(analytics);

  final SharedPreferences _prefs;
  final RemoteConfigService _remote;
  final FullScreenAds<InterstitialAd> interstitial;
  final FullScreenAds<AppOpenAd> appOpen;
  final FullScreenAds<RewardedAd> rewarded;
  final FullScreenAds<RewardedInterstitialAd> rewardedInterstitial;
  final consent = AdConsent();

  /// Cấu hình đang áp dụng (đã tính premium / tạm tắt). Widget lắng nghe để ẩn/hiện realtime.
  final config = ValueNotifier<AdConfig>(AdConfig.disabled);

  static const _kRemoteKey = 'ad_config';
  static const _kPremium = 'ads_premium';
  static const _kPausedUntil = 'ads_paused_until';

  /// Thêm hashed id máy test (in ra console lần load đầu) — chỉ áp ở dev/stg.
  static const _testDeviceIds = <String>[];

  /// Vừa hiện ad toàn màn → chặn app open/native full trong 10s (tránh 2 ad chồng nhau,
  /// vd đóng interstitial → app resume → app open).
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

    // Consent PHẢI trước MobileAds.initialize. Quá 8s → vẫn chạy (ads non-personalized).
    await consent.request().timeout(
      const Duration(seconds: 8),
      onTimeout: () => talker.warning('[ADS] consent timeout'),
    );
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
    _lifecycle = AppLifecycleListener(onResume: _onResume);
    _preloadAll();
  }

  // ── Toàn màn ────────────────────────────────────────────────

  /// Tự hiện native full sau khi đóng (nếu unit + config cho phép), rồi mới gọi [onDismissed].
  Future<bool> showInterstitial(
    String placement, {
    VoidCallback? onDismissed,
    bool nativeAfter = true,
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
    final shown = await interstitial.show(
      placement,
      unit,
      cfg.rules,
      onDismissed: chain
          ? () => showNativeFull(
              placement: NativePlacement.afterInterstitial,
              onClosed: onDismissed,
              ignoreCooldown: true,
            )
          : onDismissed,
    );
    if (shown) _lastFullScreenAt = DateTime.now();
    return shown;
  }

  /// Placement không có unit → dùng unit `resume`.
  Future<bool> showAppOpen(
    String placement, {
    VoidCallback? onDismissed,
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
    final shown = await appOpen.show(
      placement,
      unit,
      cfg.rules,
      onDismissed: onDismissed,
    );
    if (shown) _lastFullScreenAt = DateTime.now();
    return shown;
  }

  Future<bool> showRewarded(
    String placement, {
    required void Function(RewardItem reward) onReward,
    VoidCallback? onDismissed,
  }) async {
    final cfg = config.value;
    final unit = cfg.unit(AdType.rewarded, placement);
    if (unit == null || !_canRequest) return false;
    final shown = await rewarded.show(
      placement,
      unit,
      cfg.rules,
      onReward: onReward,
      onDismissed: onDismissed,
    );
    if (shown) _lastFullScreenAt = DateTime.now();
    return shown;
  }

  /// Rewarded interstitial — hiện ở điểm chuyển màn, user không cần bấm xem vẫn có thưởng.
  Future<bool> showRewardedInterstitial(
    String placement, {
    required void Function(RewardItem reward) onReward,
    VoidCallback? onDismissed,
  }) async {
    final cfg = config.value;
    final unit = cfg.unit(AdType.rewardedInterstitial, placement);
    if (unit == null || !_canRequest) return false;
    final shown = await rewardedInterstitial.show(
      placement,
      unit,
      cfg.rules,
      onReward: onReward,
      onDismissed: onDismissed,
    );
    if (shown) _lastFullScreenAt = DateTime.now();
    return shown;
  }

  /// Native toàn màn. Chưa sẵn sàng / bị giới hạn → gọi [onClosed] ngay và nạp sẵn cho lần sau.
  void showNativeFull({
    String placement = NativePlacement.full,
    VoidCallback? onClosed,
    bool ignoreCooldown = false,
  }) {
    final cfg = config.value;
    final rules = cfg.rules;
    final max = rules.maxPerSessionOf(AdType.native);
    final last = _nativeShownAt;
    final blocked =
        cfg.unit(AdType.native, placement) == null ||
        (max > 0 && _nativeShownCount >= max) ||
        (last != null &&
            DateTime.now().difference(last).inSeconds <
                rules.intervalOf(AdType.native)) ||
        (!ignoreCooldown && _inCooldown);
    final entry = blocked ? null : _native.remove(placement);
    final context = appRouter.navigatorKey.currentContext;
    if (entry == null || context == null) {
      if (!blocked) _preloadNative(placement);
      onClosed?.call();
      return;
    }
    _nativeShownAt = DateTime.now();
    _nativeShownCount++;
    _lastFullScreenAt = DateTime.now();
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      useSafeArea: false,
      builder: (dialogContext) => NativeAdFullScreen(
        ad: entry.$1,
        onClosed: () {
          Navigator.of(dialogContext).pop();
          entry.$1.dispose();
          // Nạp sẵn cái kế tiếp chỉ khi bật preload cả chung lẫn riêng vị trí này.
          if (cfg.preload &&
              (cfg.unit(AdType.native, placement)?.preload ?? false)) {
            _preloadNative(placement);
          }
          onClosed?.call();
        },
      ),
    );
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
    final last = _lastFullScreenAt;
    return last != null && DateTime.now().difference(last) < _cooldown;
  }

  void _applyRemote() {
    var base = kDevAdConfig;
    if (_remote.enabled) {
      final json = _remote.json(_kRemoteKey);
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

  /// Test id lọt lên prod = AdMob khoá account → báo lỗi (Crashlytics) + assert khi debug.
  void _assertNoTestIds(AdConfig cfg) {
    final ids = cfg.adUnits.all
        .where((u) => u.isActive && u.id.startsWith(kGoogleTestPublisher))
        .map((u) => u.id)
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
    showAppOpen(AppOpenPlacement.resume);
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

  void _preloadNative(String placement) {
    final unit = config.value.unit(AdType.native, placement);
    if (unit == null || !_canRequest || _nativeLoading.contains(placement)) {
      return;
    }
    final cached = _native[placement];
    if (cached != null) {
      if (DateTime.now().difference(cached.$2) < const Duration(hours: 1)) {
        return;
      }
      _native.remove(placement)?.$1.dispose();
    }
    _nativeLoading.add(placement);
    final ad = NativeAd(
      adUnitId: unit.id,
      factoryId: 'nativeFull', // factory native toàn màn (Android/iOS)
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          _nativeLoading.remove(placement);
          _native[placement] = (ad as NativeAd, DateTime.now());
        },
        onAdFailedToLoad: (ad, e) {
          _nativeLoading.remove(placement);
          ad.dispose();
          talker.warning('[ADS] native.$placement load failed: ${e.message}');
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
);
