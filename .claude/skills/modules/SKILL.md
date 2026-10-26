---
name: modules
description: Module trong lib/modules (Ads AdMob qua AdManager, IAP RevenueCat + isPremiumProvider, Analytics Firebase, AppConfig Remote Config) + RemoteConfigService dùng chung và core services trong lib/core/services (NotificationService, FcmService, AppVersionService.checkAndPrompt, AppQuickActions, SessionNotifier, BiometricNotifier vân tay/Face ID). Đọc khi hiện quảng cáo, mua premium, log event, bắt buộc cập nhật / bảo trì / thông báo từ Remote Config, bắn local notification, xử lý push FCM, kiểm tra cập nhật app, hoặc sửa app shortcut.
---

# Modules & core services

Mọi service là provider `@Riverpod(keepAlive: true)` đặt cạnh class. Trong widget/notifier: `ref.read(xProvider)`; chỗ không có `ref`: `globalContainer.read(xProvider)`. Thứ tự init ở `AppInitializer` (skill `architecture`).

## Remote Config (lib/core/services/remote_config_service.dart)

`remoteConfigServiceProvider` dùng chung cho ads, app_config, iap_config: `initialize()` (boot, sau Firebase — dùng ngay giá trị đã cache, tải mới chạy nền nên không chờ mạng), `json(key)` (Map hoặc null), `decode(key, fromJson, fallback)` (JSON sai → fallback), `getBool/getString`, `onUpdated` (stream realtime).

Module thêm key cấu hình mới: provider 1 dòng, tự build lại khi Firebase đổi:
```dart
@Riverpod(keepAlive: true)
IapConfig iapConfig(Ref ref) =>
    ref.remoteConfig('iap_config', IapConfig.fromJson, const IapConfig());
```
Mỗi module 1 key riêng (`ad_config`, `app_config`, `iap_config`): gỡ module gọn, đặt điều kiện (Android/iOS, quốc gia) riêng từng key, JSON sai chỉ hỏng key đó. Bật/tắt theo flavor: `FlavorConfig.useRemoteConfig` (mặc định dev `false` → module dùng cấu hình local; đổi `true` để dev đọc Remote Config của project Firebase dev).

## Ads (lib/modules/ads)

File: `ad_config.dart` (model + placement + cấu hình dev), `ad_manager.dart` (điểm vào duy nhất, `adManagerProvider`), `full_screen_ads.dart` (show chung cho interstitial / app open / rewarded / rewarded interstitial — giữ sẵn ad bằng **Preloader API chính thức của SDK** `InterstitialAdPreloader`/`RewardedAdPreloader`/`AppOpenAdPreloader`, SDK tự nạp lại + hết hạn + retry), `ad_consent.dart` (ATT + UMP), `widgets/` (banner, native, native toàn màn). Bản `google_mobile_ads` 9.1.0.

```dart
final ads = ref.read(adManagerProvider);
await ads.showInterstitial(InterstitialPlacement.afterQuiz, onDismissed: next);  // Future<bool>, tự hiện native full sau khi đóng
await ads.showAppOpen(AppOpenPlacement.splash);
await ads.showRewarded(RewardedPlacement.bonus, onReward: (r) => addCoin(r.amount));
await ads.showRewardedInterstitial(RewardedInterstitialPlacement.levelEnd, onReward: (r) => ...);  // không cần user bấm xem
ads.showNativeFull(onClosed: next);
ads.preload(AdType.interstitial, InterstitialPlacement.splash);   // nạp sẵn trước khi vào màn
ads.setPremium(true); ads.pauseAds(const Duration(minutes: 30)); ads.resumeAds(); ads.adFreeRemaining;
ads.showPrivacyOptions();  ads.resetSession();

const AdBannerWidget(placement: BannerPlacement.home)                                   // large anchored adaptive
Scaffold(bottomNavigationBar: SafeArea(top: false, child: AdBannerWidget(placement: BannerPlacement.bottom, collapsible: CollapsibleBanner.bottom)))
const NativeAdWidget(placement: NativePlacement.home, size: NativeAdSize.small)
```
- Hàm show trả `false` (không gọi `onDismissed`) khi: tắt ads/premium, chưa consent, vượt giới hạn, đang cooldown 10s sau ad khác, offline, load quá 5s → nơi gọi tự đi tiếp.
- Placement = chuỗi = key trong `ad_units.<loại>` (hằng sẵn: `InterstitialPlacement`, `AppOpenPlacement`, `RewardedPlacement`, `NativePlacement`, `BannerPlacement`; truyền chuỗi khác cũng được).
- `AdManager.initialize()` (step `Ads` ở AppInitializer) tự lo: áp Remote Config → consent (timeout 8s) → `MobileAds.initialize` → nạp sẵn → app open khi resume (bỏ qua nếu vừa hiện ad khác).
- Remote Config key `ad_config` (JSON snake_case, field thiếu = mặc định): `show_all_ads`, `preload`, `enable_interstitial|app_open|rewarded|rewarded_interstitial|native|banner`, `enable_native_full_after_interstitial`, `rules` (`interstitial_interval`, `app_open_interval`, `rewarded_interval`, `native_full_interval`, `max_interstitial_per_session`, `max_app_open_per_session`, `max_rewarded_per_session`, `max_native_full_per_session`; 0 = không giới hạn; rewarded interstitial dùng chung giới hạn rewarded), `ad_units.<loại>.<placement>` = `{id, enable, preload, native_full_after}`. Chưa có / JSON sai → tắt ads.
- Remote Config tắt (mặc định dev): `kDevAdConfig` (Google test ID, tự chọn bộ Android / iOS). Collapsible banner có test ID riêng (placement `bottom`); collapsible phải neo sát mép màn hình, chỉ lần load đầu được bung (auto-refresh sau đó là banner thường). Prod có test ID → `talker.error` + assert (AdMob khoá account nếu lọt).
- Premium: `AppInitializer` nối `iap.premium` → `ads.setPremium` (khi IAP thật).
- Native factory `nativeSmall` / `nativeMedium` / `nativeFull` đăng ký ở `MainActivity.kt` và `ios/Runner/NativeAdFactory*.swift`.
- Release: thay AdMob App ID test trong `AndroidManifest.xml` (`com.google.android.gms.ads.APPLICATION_ID`) và `Info.plist` (`GADApplicationIdentifier`).
- Demo: `features/ads_demo` (route `/ads-demo`).

## IAP — RevenueCat (lib/modules/iap/)

```dart
final iap = ref.read(iapServiceProvider);
final packages = await iap.packages();
final result = await iap.purchase(packages.first);   // PurchaseResult: success | cancelled | failed(message)
await iap.restore();  await iap.logIn(userId);  await iap.logOut();
final isPremium = ref.watch(isPremiumProvider);       // tự cập nhật
```
- Key RevenueCat `_googleKey` / `_appleKey` trong file, entitlement `premium`. Key rỗng → chế độ giả lập (`isMock`): không gọi store, dùng `debugSetPremium(true)` để test UI.
- `cancelled` thì không báo lỗi; `failed` có `message` tiếng Việt để toast.
- Bật/tắt từ xa — Remote Config key `iap_config` (`iap_config.dart`), áp dụng ngay:
  - `purchase_enabled: false` → ngừng bán (`packages()` rỗng, `purchase()` từ chối). Người đã mua vẫn giữ premium; nút "Khôi phục giao dịch" luôn phải hiện (Apple bắt buộc).
  - `premium_for_all: true` → `isPremiumProvider` = true cho mọi người (khẩn cấp: store / màn mua lỗi; hoặc bỏ tính năng trả phí). Quảng cáo tự tắt theo (AppInitializer đồng bộ `isPremiumProvider` → `ads.setPremium`).
  - Cố ý KHÔNG có cờ tước premium người đã trả tiền. Đổi giá / gói / tặng premium từng người → làm trên RevenueCat.
  - Bỏ hẳn gói trả phí khi còn người đăng ký: bật `premium_for_all` → ngừng bán gói trên App Store Connect / Play Console → giữ code IAP tới khi gói cuối hết hạn.

## Analytics (lib/modules/analytics/analytics_service.dart)

`analyticsServiceProvider` → `logEvent(name, params)` (tự bỏ param null), `logScreenView(name)`, `setUserId(id)`, `logAdRevenue(...)` (ads tự gọi). Tắt ở dev. Lỗi chỉ log, không ném.

## AppConfig (lib/modules/app_config/) — điều khiển app từ xa

Remote Config key `app_config` (JSON, mẫu ở `firebase/remote_config.test.json`). Field thiếu / JSON sai → mặc định (không khoá gì):

| Key | Tác dụng |
|---|---|
| `min_version` | Bản đang chạy thấp hơn → **bắt buộc cập nhật** (khoá app, chỉ còn nút "Cập nhật ngay") |
| `maintenance` + `maintenance_message` | Khoá app, hiện màn bảo trì (message trống → câu mặc định) |
| `notice_title` / `notice_body` / `notice_url` | Thông báo lúc mở app, mỗi nội dung hiện 1 lần (tiêu đề trống = tắt) |

- `AppGate` (`app_gate.dart`) đặt sẵn trong `MaterialApp.builder` (app.dart): đổi trên Firebase là áp dụng **ngay** (realtime), gỡ khoá thì về đúng màn đang dở. Không cần tự kiểm tra ở màn nào.
- `showAppNotice(context, ref)` (`app_notice.dart`) — đã gọi trong `SplashPage`.
- Đọc ở chỗ khác: `ref.watch(appConfigProvider)` → `AppConfig` (`mustUpdate(version)`, `hasNotice`).
- Link chính sách / điều khoản KHÔNG ở đây (phải có cả khi offline lúc Apple duyệt) → `AppInfo.privacyPolicyUrl` / `termsUrl`.

## Core services (lib/core/services)

### NotificationService — local notification
`notificationServiceProvider`: `initialize()` (đã gọi lúc boot), `showNotification(id:, title:, body:, payload:)`, `cancel(id)`, `cancelAll()`, callback `onTap(String? payload)` (chưa nơi nào gán — gán khi cần điều hướng).

### FcmService — push
`fcmServiceProvider` (phụ thuộc NotificationService): `init()` (xin quyền, lắng nghe foreground/opened/initial message), `getToken()`, `deleteToken()`, callback `onMessageTap(Map<String, dynamic> data)`. Foreground message được hiện bằng local notification với `payload = jsonEncode(message.data)`.
```dart
globalContainer.read(fcmServiceProvider).onMessageTap = (data) {
  if (data['type'] == 'voucher') appRouter.push(const VoucherListRoute());
};
```

### AppVersionService — kiểm tra cập nhật
`appVersionServiceProvider`:
- `checkAndPrompt(BuildContext)` — bản mới **không bắt buộc**: hỏi thẳng store, không cần server. Android: Google Play In-App Updates (`in_app_update`); iOS: `itunes.apple.com/lookup?bundleId=…`. "Để sau" → 3 ngày sau mới hỏi lại bản đó. Lỗi / app không cài từ store → bỏ qua. Đã gọi trong `SplashPage`. Xem thử: `--dart-define=MOCK_UPDATE=true`.
- `openStore()` — Android: màn cập nhật của Google Play ngay trong app (không được → trang CH Play); iOS: trang App Store.
- **Bắt buộc** cập nhật: đặt `min_version` trong Remote Config `app_config` (xem AppConfig) — chạy cho cả 2 nền tảng, đổi bất cứ lúc nào.
- `packageInfoProvider` — phiên bản app đang chạy.

### AppQuickActions — shortcut icon app
`lib/core/services/quick_actions_service.dart`, static: `AppQuickActions.init()` (gọi sau frame đầu trong `app.dart`), `AppQuickActions.update(isAuthenticated:)` (tự gọi khi `sessionProvider` đổi). Thêm shortcut: thêm `ShortcutItem` trong `update` + `case` trong `init` (điều hướng bằng `appRouter`). Icon = drawable Android / imageset iOS.

### SessionNotifier
`sessionProvider` — `bool` đã đăng nhập, `ready`, `login(access, [refresh])`, `logout()`. Chi tiết ở skill `state-management`.

### BiometricNotifier — vân tay / Face ID (`local_auth`)
`biometricProvider` (bool = đã bật). Chỉ mở khoá token đã lưu, KHÔNG lưu mật khẩu. Đã nối sẵn: Splash (bật → quét mới vào), Login (hỏi bật 1 lần sau đăng nhập + nút "Dùng vân tay / Face ID"), Settings (công tắc).
- `authenticate(reason)` → `true`/`false` (huỷ/sai không ném lỗi) · `setEnabled(v, reason:)` (bật phải quét đúng) · `isAvailable()`.
- Native đã cấu hình: `MainActivity` = `FlutterFragmentActivity`, `LaunchTheme` AppCompat, `NSFaceIDUsageDescription`.

### Utils
`talker` (logger.dart) và `toast` (toast.dart) — xem skill `architecture`.

## Quy tắc

- Không gọi plugin (FirebaseAnalytics, MobileAds, Purchases...) trực tiếp trong feature — đi qua service của module.
- Service mới cần init lúc boot → provider keepAlive + `_step` trong AppInitializer.
- Mọi lỗi trong service: `talker.error(...)` và fail-open, không làm sập app.
