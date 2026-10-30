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
  /// Ngay khi xong 1 bài (màn kết quả) — điểm dừng tự nhiên, nguồn doanh thu chính.
  static const lessonDone = 'lesson_done';

  /// Mở một học phần / danh sách bài từ màn Khoá học (`OpenContentAdObserver`).
  static const openContent = 'open_content';
}

abstract final class RewardedPlacement {
  /// "Xem quảng cáo để giữ chuỗi ngày học" (thẻ ở Trang chủ khi lỡ đúng 1 ngày).
  static const streakFreeze = 'streak_freeze';
}

abstract final class AppOpenPlacement {
  /// Mở app từ lần thứ 2 (lần đầu không hiện — xem SplashPage).
  static const splash = 'splash';

  /// Quay lại app từ nền (AdManager tự hiện).
  static const resume = 'resume';
}

abstract final class NativePlacement {
  /// Native full tự hiện ngay sau khi đóng interstitial (chỉ bật cho người dùng mua về).
  static const afterInterstitial = 'after_interstitial';

  /// Native full gọi tay qua `showNativeFull()`.
  static const full = 'native_full';

  /// Native nhỏ dưới điểm số ở màn kết quả bài.
  static const result = 'result';

  /// Native xen giữa các dòng của danh sách (từ vựng, ngữ pháp, hội thoại, học phần).
  static const list = 'list';

  /// Native cuối Trang chủ.
  static const home = 'home';

  /// Native dưới danh sách khoá ở màn chọn khoá học (lần mở đầu).
  static const onboarding = 'onboarding';
}

abstract final class BannerPlacement {
  /// Banner neo đáy MỌI màn (trừ lúc làm bài) — `AdBannerHost` trong `MaterialApp.builder`.
  static const list = 'list';
}

/// 1 ad unit. JSON:
/// `{ "id": "ca-app-pub-...", "fallback_ids": ["ca-app-pub-..."], "enable": true, "preload": true, "native_full_after": true }`.
@freezed
abstract class AdUnit with _$AdUnit {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory AdUnit({
    @Default('') String id,

    /// ID dự phòng, thử lần lượt khi [id] không có ad. Dùng cho "giá sàn": [id] = ad unit đặt
    /// giá sàn cao (ít ad nhưng đắt), dự phòng = ad unit thường (luôn có ad). Có ad đắt thì
    /// ăn giá cao, không có thì vẫn có ad để hiện. Chỉ đáng dùng khi lượng hiển thị lớn —
    /// app nhỏ thì bật "giá sàn tự động (Google optimized)" trên 1 ID là đủ.
    @Default(<String>[]) List<String> fallbackIds,
    @Default(true) bool enable,

    /// false = không nạp sẵn, chỉ load lúc cần hiện (placement hiếm dùng → đỡ request thừa).
    @Default(true) bool preload,

    /// (chỉ interstitial) hiện native full ngay sau khi đóng interstitial này.
    @Default(true) bool nativeFullAfter,
  }) = _AdUnit;

  const AdUnit._();

  factory AdUnit.fromJson(Map<String, dynamic> json) => _$AdUnitFromJson(json);

  bool get isActive => enable && id.isNotEmpty;

  /// Thứ tự thử: [id] rồi tới [fallbackIds].
  List<String> get ids => [id, ...fallbackIds.where((e) => e.isNotEmpty)];
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

/// Trộn [override] đè lên [base] (JSON của `ad_config`): object lồng nhau trộn tiếp từng key,
/// còn lại (số, bool, chuỗi, mảng) lấy giá trị của [override]. Dùng cho `ad_config_paid` — chỉ
/// ghi phần khác, không phải chép lại cả `ad_config`.
Map<String, dynamic> mergeAdConfigJson(
  Map<String, dynamic> base,
  Map<String, dynamic> override,
) => {
  ...base,
  for (final MapEntry(:key, :value) in override.entries)
    key: switch ((base[key], value)) {
      (final Map<String, dynamic> a, final Map<String, dynamic> b) =>
        mergeAdConfigJson(a, b),
      _ => value,
    },
};

/// Key gõ sai trong JSON cấu hình ads — không có trong model nên bị BỎ QUA IM LẶNG khi đọc
/// (vd `interstitial_intervall`, `native_full_afer`). Trả đường dẫn từng key lạ để báo lỗi.
/// Có [base] (kiểm `ad_config_paid`): báo thêm vị trí không có trong `ad_config` — vd gõ
/// `after_quizz`: code không bao giờ gọi vị trí đó → phần khai thêm vô tác dụng.
List<String> unknownAdConfigKeys(
  Map<String, dynamic> json, {
  Map<String, dynamic>? base,
}) {
  final unknown = <String>[];
  void check(Map<String, dynamic> map, Iterable<String> known, String path) {
    for (final key in map.keys) {
      if (!known.contains(key)) unknown.add('$path$key');
    }
  }

  check(json, const AdConfig().toJson().keys, '');
  if (json['rules'] case final Map<String, dynamic> rules) {
    check(rules, const AdRules().toJson().keys, 'rules.');
  }
  if (json['ad_units'] case final Map<String, dynamic> units) {
    check(units, const AdUnits().toJson().keys, 'ad_units.');
    final unitKeys = const AdUnit().toJson().keys;
    final baseUnits = base?['ad_units'];
    for (final MapEntry(key: type, value: places) in units.entries) {
      if (places is! Map<String, dynamic>) continue;
      final basePlaces = baseUnits is Map ? baseUnits[type] : null;
      for (final MapEntry(key: place, value: unit) in places.entries) {
        if (base != null &&
            (basePlaces is! Map || !basePlaces.containsKey(place))) {
          unknown.add('ad_units.$type.$place (không có trong ad_config)');
        }
        if (unit is Map<String, dynamic>) {
          check(unit, unitKeys, 'ad_units.$type.$place.');
        }
      }
    }
  }
  return unknown;
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
  final banner = id('9214589741', '2435281174');
  final rewarded = id('5224354917', '1712485313');

  // Theo docs/ad-plan.md (giai đoạn 1). Giãn cách để 0 cho dễ thử; bản thật đặt trên Remote Config.
  return AdConfig(
    showAllAds: true,
    preload: true,
    enableInterstitial: true,
    enableAppOpen: true,
    enableRewarded: true,
    enableRewardedInterstitial: false,
    enableNative: true,
    enableBanner: true,
    enableNativeFullAfterInterstitial: false,
    rules: const AdRules(
      interstitialInterval: 0,
      appOpenInterval: 15,
      maxInterstitialPerSession: 0,
      maxAppOpenPerSession: 0,
    ),
    adUnits: AdUnits(
      interstitial: {
        // Nạp sẵn: hiện thường xuyên → luôn có sẵn đúng lúc xong bài (show rate cao).
        InterstitialPlacement.lessonDone: AdUnit(
          id: interstitial,
          preload: true,
          nativeFullAfter: false,
        ),
        InterstitialPlacement.openContent: AdUnit(
          id: interstitial,
          preload: true,
          nativeFullAfter: false,
        ),
      },
      // Người dùng tự bấm xem → nạp tay khi thẻ "giữ chuỗi" hiện, không giữ sẵn.
      rewarded: {
        RewardedPlacement.streakFreeze: AdUnit(id: rewarded, preload: false),
      },
      appOpen: {
        AppOpenPlacement.splash: AdUnit(id: appOpen, preload: true),
        AppOpenPlacement.resume: AdUnit(id: appOpen, preload: true),
      },
      native: {
        // Tắt cho người dùng tự nhiên; bật trong ad_config_paid.
        NativePlacement.afterInterstitial: AdUnit(
          id: native,
          enable: false,
          preload: false,
        ),
        // Trong màn — tự tải khi widget hiện (`preload` không áp dụng).
        NativePlacement.result: AdUnit(id: native, preload: false),
        NativePlacement.list: AdUnit(id: native, preload: false),
        NativePlacement.home: AdUnit(id: native, preload: false),
        NativePlacement.onboarding: AdUnit(id: native, preload: false),
      },
      banner: {BannerPlacement.list: AdUnit(id: banner, preload: false)},
    ),
  );
}

/// Dùng khi Remote Config tắt (`FlavorConfig.useRemoteConfig = false`, mặc định ở dev).
final kDevAdConfig = _devConfig(ios: Platform.isIOS);
