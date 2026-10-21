---
name: commands
description: Lệnh dự án — Makefile (get/gen/gen-api/l10n/analyze/test/run/build/rename), script trong tools/ (gen_api.dart, l10n_sync.dart), VSCode tasks, và multi-flavor dev/stg/prod + Firebase theo flavor + cấu hình native (flavorizr, google-services, Info.plist, signing Android, checklist release). Đọc khi cần biết "lệnh nào để làm X", build/chạy theo flavor, sinh code, đổi Firebase project/bundle ID, hoặc chuẩn bị release.
---

# Commands, flavors & native

Mọi lệnh chạy qua `fvm` (xem Makefile). `make help` in danh sách.

## Makefile

| Nhóm | Lệnh | Làm gì |
|---|---|---|
| Deps | `make get` / `clean` / `upgrade` | pub get / flutter clean / upgrade major |
| Codegen | `make gen` | `build_runner build --delete-conflicting-outputs` (riverpod, freezed, retrofit, auto_route, theme_tailor, flutter_gen) |
| | `make watch` | build_runner watch |
| | `make full-gen` | clean + get + gen-l10n + gen |
| | `make gen-assets` | như `gen` (sinh `lib/gen/assets.gen.dart`) |
| API | `make gen-api [PKG=api_client2]` | `dart run tools/gen_api.dart` — sinh REST client + provider từ OpenAPI vào `packages/<PKG>` |
| | `make gen-api-server [API=url] [PKG=..]` | tải script sinh từ backend (`$(API)/api/flutter/gen_api.dart`) rồi chạy |
| L10n | `make l10n` | `flutter gen-l10n` |
| | `make l10n-sync` | xoá key thừa + liệt kê key chưa dịch (so với `app_en.arb`) |
| | `make l10n-sync-translate` | sync + dịch Google + gen-l10n |
| Native | `make gen-flavor` | flutter_flavorizr (KHÔNG idempotent, xem dưới) |
| | `make gen-icons` / `gen-splash` | launcher icon theo flavor / native splash `--all-flavors` |
| Quality | `make analyze` / `format` / `fix` | flutter analyze / dart format . / dart fix --apply |
| Test | `make test` / `cov` | flutter test / coverage + HTML (cần `lcov`) |
| Run | `make run-dev` / `run-stg` / `run-prod` | `flutter run --flavor x -t lib/main_x.dart` |
| Android | `make apk-dev..prod`, `aab-dev..prod` | build release theo flavor |
| iOS | `make ios-dev..prod` | `.app` chưa ký (`--no-codesign`) |
| | `make ipa-dev..prod` | `.ipa` (cần signing Apple) |
| Rename | `make rename-package name=new_pkg` | đổi `name` pubspec + import `package:` trong lib/test |
| | `make rename-app name="App Name"` | đổi tên hiển thị |
| | `make rename-bundle-id name=com.x.y` | đổi bundle id Android + iOS |

Chạy 1 test: `fvm flutter test test/unit/core/errors/error_handler_test.dart`.

Sau khi sửa `@riverpod`, `@freezed`, `@RestApi`, `@RoutePage`, `@TailorMixin` hoặc thêm asset: `make gen`. Sửa ARB: `make l10n`.

## tools/

- `tools/gen_api.dart` — đổi URL spec ở hằng `schemaUrl` đầu file. Tự tạo `packages/<pkg>` (pubspec, build.yaml, openapi_generator.yaml), thêm dependency vào pubspec gốc, chạy `openapi_retrofit_generator`, tạo barrel, chạy build_runner trong package và gốc. Kết quả: Retrofit + Freezed + provider Riverpod, bảng endpoint ở `packages/<pkg>/API_USAGE.md`. Không sửa tay file trong package — chạy lại sẽ ghi đè.
- `tools/l10n_sync.dart` — cờ `--translate`, `--dry-run`. Đọc đường dẫn từ `l10n.yaml`.

## VSCode

- `.vscode/tasks.json`: nhóm Deps, Codegen (Build/Watch), L10n, Full Gen, Native (Flavorizr/Icons/Splash), Quality, Test (All/Coverage), Run Flavor, Build App Target, Rename — gọi lại lệnh tương ứng của Makefile.
- `.vscode/launch.json`: cấu hình chạy/debug theo flavor.

## Flavors

| Flavor | Entry | applicationId / bundleId | Tên app |
|---|---|---|---|
| dev | `--flavor dev` | `com.loipham.lingua.dev` | Lingua Dev |
| stg | `--flavor stg` | `com.loipham.lingua.stg` | Lingua Stg |
| prod | `--flavor prod` | `com.loipham.lingua` | Lingua |

- 1 entry `lib/main.dart` cho mọi flavor: flavor lấy từ `appFlavor` (do `--flavor` truyền vào, không cần `-t`). Giá trị theo flavor (API URL, logging, Crashlytics, Sentry DSN) ở `FlavorConfig.current` (lib/config/flavor_config.dart). Không có file env.
- Code rẽ nhánh theo flavor: `FlavorConfig.isDev` / `isProd` / `current.flavor`, không so chuỗi.
- Dev: Analytics tắt, IAP chạy giả lập khi chưa có RevenueCat key, Ads dùng test ID, Crashlytics/Sentry tắt.

## Firebase theo flavor

Đặt file thẳng vào vị trí native:
```
android/app/src/{dev,stg,prod}/google-services.json
ios/Runner/{dev,stg,prod}/GoogleService-Info.plist
```
iOS chọn plist theo scheme (`Runner-dev`/`-stg`/`-prod`). Thiếu `google-services.json` đúng package → build Android lỗi "No matching client for package name".

Đổi Firebase project: tải config mới → thay 6 file → `make clean` → `make run-dev`. Không cần `gen-flavor`.

## flutter_flavorizr

`flavorizr.yaml` khai báo flavor, bundle id, icon. KHÔNG idempotent: `make gen-flavor` ghi đè `lib/app.dart`, `ios/Runner/Info.plist`, `android/app/build.gradle.kts`... Chỉ chạy khi setup lần đầu hoặc thêm flavor mới; chạy xong khôi phục file đã custom (`git checkout -- lib/app.dart ios/Runner/Info.plist android/app/build.gradle.kts`) và xoá file mẫu nó sinh ra.

## Native

- Android: `android/app/build.gradle.kts` (plugin google-services + crashlytics, signing, R8), `android/app/proguard-rules.pro`, `AndroidManifest.xml` (AdMob App ID), native ad factory đăng ký trong `MainActivity.kt`.
- iOS: `ios/Runner/Info.plist` (`GADApplicationIdentifier`, `NSUserTrackingUsageDescription`, SKAdNetwork, các `NS...UsageDescription`), `NativeAdFactory*.swift`.
- Signing Android: `cp android/key.properties.example android/key.properties`, điền thông tin keystore (`keytool -genkey -v -keystore android/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload`). Có `key.properties` → ký release; không có → build.gradle.kts fallback ký debug.

## Checklist release

| Việc | Ở đâu |
|---|---|
| API URL, Sentry DSN | `FlavorConfig.current` (lib/config/flavor_config.dart) |
| AdMob App ID thật | `AndroidManifest.xml`, `Info.plist` |
| Ad unit thật | Remote Config key `ad_config` |
| RevenueCat key | `IapConstants` (lib/modules/iap/iap_constants.dart) |
| Firebase config thật | 6 file google-services / GoogleService-Info |
| Keystore Android | `android/key.properties` |
| Mô tả quyền iOS | `Info.plist` `NS...UsageDescription` (xoá quyền không dùng) |
| Bundle id / tên app | `make rename-bundle-id`, `make rename-app`, `flavorizr.yaml` |
