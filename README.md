# lingua

Flutter base template gọn: **Riverpod (state + DI) · Retrofit · auto_route · multi-flavor**.

## Stack

| | |
|---|---|
| State + DI | flutter_riverpod 3 (codegen) + flutter_hooks |
| Network | dio + retrofit + dio_smart_retry · client OpenAPI sinh tự động ở `packages/api_client` |
| Routing | auto_route (typed) |
| Model | freezed + json_serializable |
| Storage | shared_preferences + flutter_secure_storage |
| Log / lỗi | talker (+ dio/riverpod logger) → Crashlytics + Sentry |
| UI | Material 3 + theme_tailor · toastification · flutter_smart_dialog |
| Có sẵn | Firebase (Analytics, Crashlytics, Remote Config, FCM), local notification, force update, quick actions, AdMob, RevenueCat |

## Bắt đầu

```bash
fvm install
make get
make gen        # build_runner (sau mọi thay đổi @riverpod/@freezed/@RestApi/@RoutePage)
make run-dev    # hoặc run-stg / run-prod
```

`make help` để xem toàn bộ lệnh. Sinh REST client từ OpenAPI backend: `make gen-api`.

## Cấu trúc

```
lib/
  config/     flavor_config, app_info, app_initializer, system_ui_manager
  core/       di, errors, riverpod (BaseNotifier), network, services, utils (log, toast)
  design/     theme + l10n
  shared/     widget dùng chung
  features/   mỗi feature 1 thư mục phẳng: _model, _service, _notifier, _page
  modules/    ads, iap, analytics, app_config
  routes/     app_router + guard
```

Mẫu để copy khi viết feature mới: `lib/features/_reference/voucher/`. Quy ước chi tiết xem `CLAUDE.md`.
