import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'ad_config.freezed.dart';
part 'ad_config.g.dart';

enum AdType {
  interstitial,
  appOpen,
  rewarded,
  rewardedInterstitial,
  native,
  banner,
}

/// Tên placement = key trong `ad_units.<loại>` trên Remote Config.
/// Thêm placement: thêm hằng ở đây + key trên Firebase (hoặc truyền chuỗi bất kỳ).
abstract final class InterstitialPlacement {
  static const splash = 'splash';
  static const afterQuiz = 'after_quiz';
}

abstract final class AppOpenPlacement {
  static const splash = 'splash';
  static const resume = 'resume';
}

abstract final class RewardedPlacement {
  static const bonus = 'bonus';
}

/// Rewarded interstitial: tự hiện ở điểm chuyển màn (không cần user bấm xem), vẫn có thưởng.
abstract final class RewardedInterstitialPlacement {
  static const levelEnd = 'level_end';
}

abstract final class NativePlacement {
  /// Native full tự hiện ngay sau khi đóng interstitial.
  static const afterInterstitial = 'after_interstitial';

  /// Native full gọi tay qua `showNativeFull()`.
  static const full = 'native_full';
  static const language = 'language';
  static const home = 'home';
}

abstract final class BannerPlacement {
  static const home = 'home';

  /// Banner neo đáy màn, dạng collapsible (dùng với `CollapsibleBanner.bottom`).
  static const bottom = 'bottom';
}

/// 1 ad unit. JSON: `{ "id": "ca-app-pub-...", "enable": true, "preload": true, "native_full_after": true }`.
@freezed
abstract class AdUnit with _$AdUnit {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory AdUnit({
    @Default('') String id,
    @Default(true) bool enable,

    /// false = không nạp sẵn, chỉ load lúc cần hiện (placement hiếm dùng → đỡ request thừa).
    @Default(true) bool preload,

    /// (chỉ interstitial) hiện native full ngay sau khi đóng interstitial này.
    @Default(true) bool nativeFullAfter,
  }) = _AdUnit;

  const AdUnit._();

  factory AdUnit.fromJson(Map<String, dynamic> json) => _$AdUnitFromJson(json);

  bool get isActive => enable && id.isNotEmpty;
}

/// Giới hạn tần suất theo LOẠI ad. `*_interval` = giây giữa 2 lần hiện;
/// `max_*_per_session` = tối đa mỗi phiên (0 = không giới hạn). Rewarded (user tự bấm xem) và
/// rewarded interstitial (tự bật lúc chuyển màn, chen ngang như interstitial) giới hạn riêng.
@freezed
abstract class AdRules with _$AdRules {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory AdRules({
    @Default(30) int interstitialInterval,
    @Default(30) int appOpenInterval,
    @Default(30) int rewardedInterval,
    @Default(30) int rewardedInterstitialInterval,
    @Default(30) int nativeFullInterval,
    @Default(3) int maxInterstitialPerSession,
    @Default(4) int maxAppOpenPerSession,
    @Default(5) int maxRewardedPerSession,
    @Default(3) int maxRewardedInterstitialPerSession,
    @Default(3) int maxNativeFullPerSession,
  }) = _AdRules;

  const AdRules._();

  factory AdRules.fromJson(Map<String, dynamic> json) =>
      _$AdRulesFromJson(json);

  int intervalOf(AdType type) => switch (type) {
    AdType.interstitial => interstitialInterval,
    AdType.appOpen => appOpenInterval,
    AdType.rewarded => rewardedInterval,
    AdType.rewardedInterstitial => rewardedInterstitialInterval,
    AdType.native => nativeFullInterval,
    AdType.banner => 0,
  };

  int maxPerSessionOf(AdType type) => switch (type) {
    AdType.interstitial => maxInterstitialPerSession,
    AdType.appOpen => maxAppOpenPerSession,
    AdType.rewarded => maxRewardedPerSession,
    AdType.rewardedInterstitial => maxRewardedInterstitialPerSession,
    AdType.native => maxNativeFullPerSession,
    AdType.banner => 0,
  };
}

/// Map placement → unit cho từng loại.
@freezed
abstract class AdUnits with _$AdUnits {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory AdUnits({
    @Default({}) Map<String, AdUnit> interstitial,
    @Default({}) Map<String, AdUnit> appOpen,
    @Default({}) Map<String, AdUnit> rewarded,
    @Default({}) Map<String, AdUnit> rewardedInterstitial,
    @Default({}) Map<String, AdUnit> native,
    @Default({}) Map<String, AdUnit> banner,
  }) = _AdUnits;

  const AdUnits._();

  factory AdUnits.fromJson(Map<String, dynamic> json) =>
      _$AdUnitsFromJson(json);

  Map<String, AdUnit> of(AdType type) => switch (type) {
    AdType.interstitial => interstitial,
    AdType.appOpen => appOpen,
    AdType.rewarded => rewarded,
    AdType.rewardedInterstitial => rewardedInterstitial,
    AdType.native => native,
    AdType.banner => banner,
  };

  Iterable<AdUnit> get all => AdType.values.expand((t) => of(t).values);
}

/// Cấu hình ads — Remote Config key `ad_config` (JSON snake_case, field thiếu dùng mặc định):
/// ```json
/// {
///   "show_all_ads": true, "preload": true,
///   "enable_interstitial": true, "enable_app_open": true, "enable_rewarded": true, "enable_rewarded_interstitial": true,
///   "enable_native": true, "enable_banner": true, "enable_native_full_after_interstitial": true,
///   "rules": { "interstitial_interval": 30, "max_interstitial_per_session": 3 },
///   "ad_units": { "interstitial": { "splash": { "id": "ca-app-pub-..." } }, "banner": { "home": { "id": "..." } } }
/// }
/// ```
@freezed
abstract class AdConfig with _$AdConfig {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory AdConfig({
    /// Công tắc tổng.
    @Default(true) bool showAllAds,

    /// Nạp sẵn ad lúc vào app + ngay sau mỗi lần hiện. false = chỉ load lúc cần hiện.
    @Default(true) bool preload,
    @Default(true) bool enableInterstitial,
    @Default(true) bool enableAppOpen,
    @Default(true) bool enableRewarded,
    @Default(true) bool enableRewardedInterstitial,
    @Default(true) bool enableNative,
    @Default(true) bool enableBanner,
    @Default(true) bool enableNativeFullAfterInterstitial,
    @Default(AdRules()) AdRules rules,
    @Default(AdUnits()) AdUnits adUnits,
  }) = _AdConfig;

  const AdConfig._();

  factory AdConfig.fromJson(Map<String, dynamic> json) =>
      _$AdConfigFromJson(json);

  /// Tắt hết (fallback khi chưa có / lỗi Remote Config).
  static const disabled = AdConfig(showAllAds: false);

  bool isTypeEnabled(AdType type) =>
      showAllAds &&
      switch (type) {
        AdType.interstitial => enableInterstitial,
        AdType.appOpen => enableAppOpen,
        AdType.rewarded => enableRewarded,
        AdType.rewardedInterstitial => enableRewardedInterstitial,
        AdType.native => enableNative,
        AdType.banner => enableBanner,
      };

  /// Unit được phép hiện của [type]/[placement]; `null` = không hiện.
  AdUnit? unit(AdType type, String placement) {
    if (!isTypeEnabled(type)) return null;
    final u = adUnits.of(type)[placement];
    return (u?.isActive ?? false) ? u : null;
  }
}

// ── Cấu hình dev: Google test ID ─────────────────────────────────

/// Mọi id bắt đầu bằng tiền tố này là TEST id — tuyệt đối không lên prod.
const kGoogleTestPublisher = 'ca-app-pub-3940256099942544/';

/// Test ID của Google (Android / iOS khác nhau).
AdConfig _devConfig({required bool ios}) {
  String id(String android, String iosId) =>
      '$kGoogleTestPublisher${ios ? iosId : android}';
  final interstitial = id('1033173712', '4411468910');
  final appOpen = id('9257395921', '5575463023');
  final native = id('2247696110', '3986624511');
  final rewarded = id('5224354917', '1712485313');
  final rewardedInterstitial = id('5354046379', '6978759866');
  final banner = id('9214589741', '2435281174');
  // Google có test ID riêng cho collapsible — dùng ID banner thường sẽ không bung.
  final collapsibleBanner = id('2014213617', '8388050270');

  // Viết đủ mọi field (kể cả bằng mặc định) để đổi nhanh khi test.
  return AdConfig(
    showAllAds: false,
    preload: true,
    enableInterstitial: true,
    enableAppOpen: true,
    enableRewarded: true,
    enableRewardedInterstitial: true,
    enableNative: true,
    enableBanner: true,
    enableNativeFullAfterInterstitial: true,
    rules: const AdRules(
      // Giây giữa 2 lần hiện.
      interstitialInterval: 0,
      appOpenInterval: 15,
      rewardedInterval: 30,
      rewardedInterstitialInterval: 30,
      nativeFullInterval: 30,
      // Tối đa mỗi phiên, 0 = không giới hạn.
      maxInterstitialPerSession: 0,
      maxAppOpenPerSession: 0,
      maxRewardedPerSession: 0,
      maxRewardedInterstitialPerSession: 0,
      maxNativeFullPerSession: 0,
    ),
    adUnits: AdUnits(
      interstitial: {
        InterstitialPlacement.splash: AdUnit(
          id: interstitial,
          enable: true,
          preload: true,
          nativeFullAfter: true,
        ),
        InterstitialPlacement.afterQuiz: AdUnit(
          id: interstitial,
          enable: true,
          preload: true,
          nativeFullAfter: false,
        ),
      },
      appOpen: {
        AppOpenPlacement.splash: AdUnit(
          id: appOpen,
          enable: true,
          preload: true,
        ),
        AppOpenPlacement.resume: AdUnit(
          id: appOpen,
          enable: true,
          preload: true,
        ),
      },
      rewarded: {
        RewardedPlacement.bonus: AdUnit(
          id: rewarded,
          enable: true,
          preload: true,
        ),
      },
      rewardedInterstitial: {
        RewardedInterstitialPlacement.levelEnd: AdUnit(
          id: rewardedInterstitial,
          enable: true,
          preload: true,
        ),
      },
      native: {
        // Toàn màn — nạp sẵn theo `preload`.
        NativePlacement.afterInterstitial: AdUnit(
          id: native,
          enable: true,
          preload: true,
        ),
        NativePlacement.full: AdUnit(id: native, enable: true, preload: true),
        // Gắn trong màn — load khi widget hiện (`preload` không áp dụng).
        NativePlacement.language: AdUnit(id: native, enable: true),
        NativePlacement.home: AdUnit(id: native, enable: true),
      },
      banner: {
        // Banner load khi widget hiện (`preload` không áp dụng).
        BannerPlacement.home: AdUnit(id: banner, enable: true),
        BannerPlacement.bottom: AdUnit(id: collapsibleBanner, enable: true),
      },
    ),
  );
}

/// Dùng khi Remote Config tắt (`FlavorConfig.useRemoteConfig = false`, mặc định ở dev).
final kDevAdConfig = _devConfig(ios: Platform.isIOS);
