---
name: modules
description: Module trong lib/modules (Ads AdMob qua AdManager, Attribution Adjust (người dùng mua về / tự nhiên, ROAS), IAP RevenueCat + isPremiumProvider, Analytics Firebase, AppConfig Remote Config) + RemoteConfigService dùng chung và core services trong lib/core/services (NotificationService, FcmService, AppVersionService.checkAndPrompt, AppQuickActions, SessionNotifier, BiometricNotifier vân tay/Face ID). Đọc khi hiện quảng cáo, mua premium, log event, bắt buộc cập nhật / bảo trì / thông báo từ Remote Config, bắn local notification, xử lý push FCM, kiểm tra cập nhật app, hoặc sửa app shortcut.
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

File: `ad_config.dart` (model + placement + cấu hình dev), `ad_manager.dart` (điểm vào duy nhất, `adManagerProvider`), `full_screen_ads.dart` (show chung cho interstitial / app open / rewarded / rewarded interstitial — giữ sẵn ad bằng **Preloader API chính thức của SDK** `InterstitialAdPreloader`/`RewardedAdPreloader`/`AppOpenAdPreloader`, SDK tự nạp lại + hết hạn + retry), `ad_consent.dart` (ATT + UMP), `widgets/` (banner, native, native toàn màn). Bản `google_mobile_ads` 9.2.0.

```dart
final ads = ref.read(adManagerProvider);
await ads.showInterstitial(InterstitialPlacement.afterQuiz);  next();  // chờ đóng hẳn (kể cả native full theo sau)
await ads.showAppOpen(AppOpenPlacement.splash);
await ads.showRewarded(RewardedPlacement.bonus, onReward: (r) => addCoin(r.amount));
await ads.showRewardedInterstitial(RewardedInterstitialPlacement.levelEnd, onReward: (r) => ...);  // không cần user bấm xem
await ads.showNativeFull();
// Cần phản ứng đúng lúc ad lên màn (vd game): onShowed — iOS hiện ad không đổi vòng đời app
await ads.showInterstitial(p, onShowed: game.pause);  game.resume();
ads.preload(AdType.interstitial, InterstitialPlacement.splash);   // nạp sẵn trước khi vào màn
ads.setPremium(true); ads.pauseAds(const Duration(minutes: 30)); ads.resumeAds(); ads.adFreeRemaining;
ads.showPrivacyOptions();  ads.resetSession();

const AdBannerWidget(placement: BannerPlacement.home)                                   // large anchored adaptive
Scaffold(bottomNavigationBar: SafeArea(top: false, child: AdBannerWidget(placement: BannerPlacement.bottom, collapsible: CollapsibleBanner.bottom)))
const NativeAdWidget(placement: NativePlacement.home, size: NativeAdSize.small)
```
- Mọi hàm show **chờ tới khi ad đóng hẳn** rồi mới xong → `await` xong là đi tiếp, không cần callback, không bao giờ kẹt. Trả `true` = đã hiện; `false` = không hiện (xong ngay): tắt ads/premium, chưa consent, vượt giới hạn, đang hiện / vừa đóng ad khác < 10s, offline, load quá 5s.
- **Gõ sai key trên Remote Config** (`ad_config` / `ad_config_paid`) bị bỏ qua im lặng khi đọc → `AdManager` tự kiểm bằng `unknownAdConfigKeys` (so với cấu trúc model; `ad_config_paid` báo thêm vị trí không có trong `ad_config`) và báo `talker.error` (Crashlytics, mỗi lỗi 1 lần / phiên). Xem Crashlytics sau khi sửa cấu hình.
- Ad toàn màn chưa có sẵn phải tải tại chỗ (> 300ms) → tự hiện lớp phủ "Đang tải quảng cáo…" chặn chạm (`ad_loading_overlay.dart`), tránh ad bật lên đột ngột khi user đang bấm → click nhầm (AdMob phạt). Không cần làm gì ở nơi gọi.
- Consent: `AdConsent.canRequestAds` theo `ConsentInformation.canRequestAds()` chính thức (offline → dùng lựa chọn đã lưu). Đặt nút "Quyền riêng tư" ở Cài đặt khi `isPrivacyOptionsRequired` → `ads.showPrivacyOptions()`.
- Gỡ lỗi "không có ad": **Ad Inspector** (lingua không có trang demo ads → gọi tạm ở bản dev) — `MobileAds.instance.openAdInspector`. Chỉ mở trên máy test (máy ảo / `_testDeviceIds` / khai báo trên AdMob).
- **ID dự phòng / giá sàn** (`fallback_ids`): `id` = ad unit đặt giá sàn cao (ít ad nhưng đắt), `fallback_ids` = ad unit thường (luôn có ad). Nạp sẵn song song mỗi ID 1 ad, lúc hiện ưu tiên ID đứng trước; tải tại chỗ / banner / native thử lần lượt. Chỉ đáng dùng khi lượng hiển thị lớn — app nhỏ: để trống, bật "Google optimized floor" trên 1 ID.
- Đo lường: `ad_impression_custom` (theo placement + `ad_source` = mạng thắng khi mediation), `ad_requested`, `ad_load_failed`. Doanh thu xem ở Firebase (`ad_impression` tự ghi khi đã liên kết AdMob).
- Ad tải tại chỗ về muộn hơn thời gian chờ → giữ lại cho lần hiện sau, không bỏ phí.
- Placement = chuỗi = key trong `ad_units.<loại>` (hằng sẵn: `InterstitialPlacement`, `AppOpenPlacement`, `RewardedPlacement`, `NativePlacement`, `BannerPlacement`; truyền chuỗi khác cũng được).
- `AdManager.initialize()` (step `Ads` ở AppInitializer) tự lo: áp Remote Config → consent (timeout 8s) → `MobileAds.initialize` → nạp sẵn → app open khi resume (bỏ qua nếu vừa hiện ad khác).
- Remote Config key `ad_config` (JSON snake_case, field thiếu = mặc định): `show_all_ads`, `preload`, `enable_interstitial|app_open|rewarded|rewarded_interstitial|native|banner`, `enable_native_full_after_interstitial`, `rules` (`interstitial_interval`, `app_open_interval`, `rewarded_interval`, `native_full_interval`, `rewarded_interstitial_interval`, `max_interstitial_per_session`, `max_app_open_per_session`, `max_rewarded_per_session`, `max_rewarded_interstitial_per_session`, `max_native_full_per_session`; 0 = không giới hạn; banner / native trong màn không có giới hạn — refresh banner chỉnh trên AdMob), `ad_units.<loại>.<placement>` = `{id, fallback_ids, enable, preload, native_full_after}`. Chưa có / JSON sai → tắt ads.
- Remote Config tắt (mặc định dev): `kDevAdConfig` (Google test ID, tự chọn bộ Android / iOS). Collapsible banner có test ID riêng (placement `bottom`); collapsible phải neo sát mép màn hình, chỉ lần load đầu được bung (auto-refresh sau đó là banner thường). Prod có test ID → `talker.error` + assert (AdMob khoá account nếu lọt).
- Premium: `AppInitializer` nối `iap.premium` → `ads.setPremium` (khi IAP thật).
- Native factory `nativeSmall` / `nativeMedium` / `nativeFull` đăng ký ở `MainActivity.kt` và `ios/Runner/NativeAdFactory*.swift`.
- Release: thay AdMob App ID test trong `AndroidManifest.xml` (`com.google.android.gms.ads.APPLICATION_ID`) và `Info.plist` (`GADApplicationIdentifier`).

### Mediation (AppLovin, Meta, Unity, Mintegral, Pangle…) — làm theo từng app, KHÔNG sửa khung
Code ads không đổi gì: AdMob tự gọi các mạng khác qua adapter. Chỉ bật khi app đã có lượng hiển thị thật (ít traffic thì mediation không tăng doanh thu).
1. Mở tài khoản từng mạng, lấy key / app id của mạng đó.
2. AdMob Console → **Mediation** → tạo mediation group cho từng định dạng / ad unit → thêm ad source, ưu tiên **Bidding**; điền key của mạng ngay trên AdMob.
3. Thêm adapter chính thức của Google: `make mediation networks="applovin meta unity"` (thêm `gma_mediation_<mạng>` + `pod install`; mạng có sẵn ghi trong Makefile). Đọc README adapter: có mạng đòi `minSdk` / iOS tối thiểu cao hơn.
4. iOS: thêm `SKAdNetworkItems` của từng mạng vào `Info.plist` (danh sách trên trang tài liệu của mạng) — thiếu là mất doanh thu iOS.
5. AdMob → **Privacy & messaging**: bật mạng mới trong danh sách đối tác của thông báo GDPR (UMP tự truyền consent cho đối tác Google chứng nhận).
6. Cập nhật khai báo **Data safety** (Google Play) / **App Privacy** (App Store) vì có thêm SDK thu thập dữ liệu.
7. Kiểm tra: Ad Inspector (`MobileAds.instance.openAdInspector`, gọi tạm ở bản dev) → từng ad source phải "loaded"; bật test mode của mạng khi thử, tắt trước khi release.
8. Collapsible banner chỉ bung với ad của Google; ad từ mạng khác hiện như banner thường.

## Attribution — Adjust (lib/modules/attribution/)

Đo **nguồn cài đặt** (MMP): người dùng đến từ chiến dịch quảng cáo trả tiền hay tự nhiên + doanh thu quảng cáo từng người → ROAS theo chiến dịch. **Chỉ cần khi chạy quảng cáo mua người dùng ở nhiều nền tảng** (Meta, TikTok, Unity…); chỉ chạy Google Ads → Firebase (liên kết Google Ads) là đủ.

- **App token** (Adjust dashboard → app → App token): Remote Config `attribution_config.app_token` (đổi không cần ra bản mới) → không có thì `_codeAppToken` trong `attribution_service.dart`. Cả hai trống → tắt hẳn. Lần mở đầu chưa có Remote Config mà token chỉ nằm trên đó → chờ tải xong mới khởi động (Adjust vẫn ghi nhận lượt cài). Nên điền cả 2 chỗ. dev/stg = `sandbox`, prod = `production`.
- Remote Config `attribution_config` (`attribution_config.dart`): `app_token`, `paid_when_unknown` (chưa rõ nguồn — rỗng / Unattributed / Untrusted Devices — coi là mua về? mặc định không), `value_events` (`[{token, ad_revenue, currency}` hoặc `{token, ad_impressions}]`: doanh thu quảng cáo cộng dồn / số lượt vượt ngưỡng → gửi sự kiện Adjust 1 lần / người, Adjust chuyển cho Google / Meta / TikTok tối ưu chiến dịch). KHÔNG để API token Adjust ở đây (ai dịch ngược app cũng đọc được).
- `attributionServiceProvider.isPaid` (`ValueNotifier<bool>`): lưu `network` Adjust trả về; Organic / Google Organic Search → tự nhiên, chưa rõ → theo `paid_when_unknown`, còn lại (tên mạng quảng cáo) → mua về. Tính lại khi Remote Config đổi.
- **Hai chế độ quảng cáo**: người dùng mua về → Remote Config `ad_config_paid` **chỉ ghi phần khác** (giãn cách, bật thêm vị trí…), app trộn đè lên `ad_config` bằng `mergeAdConfigJson` (object lồng nhau trộn tiếp, giá trị khác thì thay). ID quảng cáo thường chỉ khai ở `ad_config`, không chép đôi. **Muốn ad unit riêng cho người dùng mua về** (tách doanh thu trong báo cáo AdMob, đặt giá sàn / mediation group khác): ghi `"id"` (và `fallback_ids`) cho vị trí đó trong `ad_config_paid` — khi ấy `ad_config_paid` cũng phải có giá trị điều kiện **iOS** riêng như `ad_config` (ID Android/iOS khác nhau). Không có key → dùng nguyên `ad_config`. Đổi realtime khi Adjust trả kết quả. Vẫn phải trong chính sách AdMob.
  ```json
  { "rules": { "interstitial_interval": 45, "max_interstitial_per_session": 6 },
    "ad_units": { "interstitial": { "after_quiz": { "native_full_after": true } } } }
  ```
- **Doanh thu**: mọi lượt hiển thị (toàn màn, banner, native) tự gửi về Adjust qua `AdManager.reportPaid` (`onPaidEvent`, nguồn `admob_sdk`, kèm placement + mạng mediation thắng). Firebase vẫn tự ghi doanh thu riêng khi đã liên kết AdMob — không đếm đôi.
- iOS: dùng chung hộp thoại ATT của `AdConsent`; Adjust chờ tối đa 30s cho người dùng trả lời (`attConsentWaitingInterval`) để lấy IDFA. SKAdNetwork do SDK tự lo.
- Kiểm tra: build dev/stg → log `[ATTRIBUTION]` + log verbose của Adjust ("Install tracked"); Adjust dashboard → Testing console với mã thiết bị test.

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

## Analytics (lib/modules/analytics/)

`analyticsServiceProvider` → `logEvent(name, params)` (tự bỏ param null), `logScreenView(name)`, `setUserId(id)`.

**Màn hình tự ghi**: `AnalyticsRouteObserver` (gắn trong `app.dart`) ghi `screen_view` mỗi lần chuyển màn / đổi tab, tên = route bỏ "Route" (`HomeRoute` → `Home`); dialog không tính. `ScreenTracker(shells: {MainRoute.name})`: route chỉ là khung tab không tính là màn. Thêm màn mới không phải làm gì. Đã tắt màn tự ghi của Firebase (`google_analytics_automatic_screen_reporting_enabled` trong AndroidManifest, `FirebaseAutomaticScreenReportingEnabled` trong Info.plist) — nếu không mọi màn đều ra "MainActivity".
- Sự kiện mốc học tập của lingua: `features/course/providers/learning_events.dart` (extension trên `AnalyticsService`) — `course_selected` (`first` = xong onboarding), `practice_completed` (`type`, `topic`, `total`, `correct`, `accuracy`), `daily_goal_reached` (`goal`, `streak`). `course_selected` / `daily_goal_reached` tự ghi trong `LearnerNotifier._save`; màn luyện tập mới nhớ gọi `practiceCompleted` lúc xong bài.

**Xem số liệu** (Firebase console → Analytics, hoặc Google Analytics):
- Màn nào vào nhiều / ít, ở lại bao lâu: Reports → Engagement → *Pages and screens*.
- Người dùng đi tiếp đâu, thoát ở màn nào: Explore → *Path exploration* (chọn màn bắt đầu).
- Rơi rụng ở bước nào: Explore → *Funnel exploration* (dựng từ `screen_view` + sự kiện mốc).
- Có quay lại không: Reports → *Retention*. Thoát vì crash: Crashlytics.
- Thử ngay (bản dev KHÔNG gửi số liệu → chạy stg): Android `adb shell setprop debug.firebase.analytics.app <package>`; iOS thêm `-FIRDebugEnabled` vào Arguments của scheme → Firebase → DebugView. Số liệu báo cáo thường trễ vài giờ. Doanh thu quảng cáo KHÔNG tự ghi: liên kết AdMob ↔ Firebase thì Firebase tự ghi `ad_impression` (kèm doanh thu, mọi định dạng, cả mạng mediation) + `ad_click` — tự ghi thêm là đếm đôi. Tắt ở dev. Lỗi chỉ log, không ném.

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
