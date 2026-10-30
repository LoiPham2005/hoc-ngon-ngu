# Kế hoạch quảng cáo — Lingua

Kịch bản đặt quảng cáo theo hành trình người dùng, tần suất, cấu hình Remote Config và lộ trình bật dần.
Nguyên tắc chung + chính sách: xem `flutter_base2/docs/app-monetization-playbook.md`.

---

## 1. Nguyên tắc riêng cho Lingua

1. **Không bao giờ chen ngang lúc đang làm bài** (quiz, nghe chép, luyện nói, xếp câu…). Người học mất mạch là bỏ app.
2. **Mỗi lần xong bài tối đa 1 quảng cáo toàn màn**, đặt ngay sau khi xong — điểm dừng tự nhiên nhất của app học.
3. **Lần mở đầu không có quảng cáo toàn màn** (splash, onboarding chọn khoá) — ấn tượng đầu quyết định giữ chân D1.
4. **Premium = không thấy quảng cáo nào** (kể cả rewarded — quyền lợi rewarded cho miễn phí).
5. Quảng cáo là **nguồn phụ**; nguồn chính về lâu dài là Premium (luyện thi JLPT, ôn không giới hạn). Đừng nhồi quảng cáo làm hỏng giữ chân.

---

## 2. Loại quảng cáo dùng

| Loại | Dùng ở Lingua | Vì sao |
|---|---|---|
| **App Open** | Mở app (từ lần thứ 2), quay lại app | Loại dành riêng cho lúc mở app |
| **Interstitial** | Ngay sau khi xong bài | Điểm dừng tự nhiên, giá cao |
| **Rewarded** | "Giữ chuỗi ngày học" khi lỡ 1 ngày | Người học rất quý chuỗi → tự nguyện xem, giá cao nhất |
| **Native trong màn** | Màn kết quả bài, cuối màn chọn khoá | Hoà vào nội dung, không che |
| **Banner** (adaptive, neo đáy) | Các màn danh sách | Hiện lâu, đều đặn |
| ~~Rewarded interstitial~~ | Không dùng | Chen ngang như interstitial mà đã có interstitial |
| ~~Native toàn màn~~ | Chỉ cho người dùng mua về (giai đoạn 3) | Rủi ro "xen kẽ quá dày" |

---

## 3. Kịch bản theo hành trình người dùng

### 3.1 Lần mở app đầu tiên
```
Splash ──► Onboarding (chọn khoá học) ──► Home
  │            └─ [GĐ2] native nhỏ dưới danh sách khoá (native.onboarding)
  └─ KHÔNG App Open lần đầu
```

### 3.2 Những lần mở sau
```
Splash ──► [App Open: app_open.splash] ──► Home
                                            └─ [GĐ2] native nhỏ cuối màn (native.home)
```
- Chỉ hiện nếu ad đã nạp sẵn; chưa có thì vào thẳng Home (không bắt chờ).

### 3.3 Quay lại app (từ nền)
```
(ra nền > 30s) ──► quay lại ──► [App Open: app_open.resume] (giãn ≥ 2 phút)
```
- Không hiện khi vừa đóng quảng cáo khác (cooldown 10s có sẵn trong code).

### 3.4 Duyệt nội dung
| Màn | Quảng cáo |
|---|---|
| Learn, KanaTable, KanjiList, VocabList, PhraseList, GrammarList, DialogueList, Topics, MinimalPairs | **Banner neo đáy** (`banner.list`) |
| KanjiDetail, KanaDetail, WordDetail, GrammarLesson, Dialogue | Không (đang đọc / nghe nội dung) |
| Search, Stats, Profile, VoiceSettings | Không (màn ngắn / cài đặt) |

### 3.5 Làm bài → xong bài (điểm kiếm tiền chính)
```
Quiz / GrammarPractice / DialogueQuiz / SentencePractice / MinimalPairQuiz /
IrregularTyping / PhraseOrder / ExerciseQuiz
   │  (đang làm: KHÔNG quảng cáo)
   ▼
Xong bài (đúng chỗ đang ghi sự kiện practice_completed)
   ├─ [Interstitial: interstitial.lesson_done]  (giãn ≥ 60s, ≤ 3 / phiên, bỏ qua bài < 5 câu)
   ▼
Màn kết quả
   └─ [Native trong màn: native.result]  dưới điểm số
```

### 3.6 Chuỗi ngày học (rewarded — GĐ2, cần làm tính năng mới)
```
Mở app sau khi lỡ 1 ngày ──► Home hiện thẻ:
  "Bạn lỡ hôm qua. Xem 1 quảng cáo để giữ chuỗi 12 ngày?"
     ├─ [Rewarded: rewarded.streak_freeze] ──► xem hết → giữ chuỗi
     └─ "Thôi" ──► chuỗi về 1
```
- Tối đa 1 lần giữ chuỗi / tuần. Premium: tự giữ chuỗi miễn phí (thêm lý do mua Premium).

---

## 4. Bảng vị trí quảng cáo

| Vị trí (key) | Loại | Màn / lúc | Tự nhiên | Mua về | Giai đoạn |
|---|---|---|---|---|---|
| `app_open.splash` | App Open | Mở app từ lần 2 | Bật | Bật | 1 |
| `app_open.resume` | App Open | Quay lại app | Bật | Bật | 1 |
| `interstitial.lesson_done` | Interstitial | Xong bài | Bật | Bật | 1 |
| `native.result` | Native (nhỏ) | Màn kết quả | Bật | Bật | 1 |
| `banner.list` | Banner neo đáy | MỌI màn trừ lúc làm bài / splash / onboarding / bàn phím mở | Bật | Bật | 1 |
| `interstitial.open_content` | Interstitial | Mở học phần (bảng kana, kanji, phát âm, chủ đề, câu, ngữ pháp, hội thoại, cặp âm, động từ bất quy tắc) | Bật | Bật | 2 |
| `rewarded.streak_freeze` | Rewarded | Thẻ "Cứu chuỗi" ở Home khi lỡ đúng 1 ngày (≤ 1 lần / 7 ngày) | Bật | Bật | 2 |
| `native.list` | Native (nhỏ) | Danh sách từ / câu / ngữ pháp / hội thoại (sau mục 3, rồi mỗi 8 mục) + sau nhóm đầu ở Khoá học | Bật | Bật | 2 |
| `native.home` | Native (vừa) | Home, trước Thống kê | Bật | Bật | 2 |
| `native.onboarding` | Native (nhỏ) | Dưới danh sách khoá ở Onboarding | Bật | Bật | 2 |
| `native.after_interstitial` | Native toàn màn | Sau `lesson_done` | Tắt | Bật | 3 |

---

## 4b. Nạp sẵn (preload) — để quảng cáo hiện ngay, không bắt chờ

| Vị trí | Cách nạp | Gọi ở đâu |
|---|---|---|
| `app_open.splash`, `app_open.resume` | Tự động (`preload: true`) | AdManager nạp lúc mở app, hiện xong tự nạp cái kế |
| `interstitial.lesson_done` | Tự động (`preload: true`) **+** gọi tay cho chắc | `useEffect` của mọi màn làm bài: `ads.preload(AdType.interstitial, InterstitialPlacement.lessonDone)` |
| `rewarded.streak_freeze` | Gọi tay (`preload: false`) | Lúc Home hiện thẻ "giữ chuỗi" (chỉ khi lỡ 1 ngày) → `ads.preload(AdType.rewarded, RewardedPlacement.streakFreeze)` |
| `native.after_interstitial` | Tự động khi interstitial bắt đầu hiện | Có sẵn trong `showInterstitial` |
| `native.result`, `native.home`, `native.onboarding`, `banner.list` | Không cần | Tự tải khi widget hiện ra |

- Gọi `preload` nhiều lần không sao (đã có sẵn thì bỏ qua); không cần huỷ khi rời màn (tự hết hạn ~1 giờ).
- Premium / tạm tắt ads / chưa đồng ý quảng cáo → `preload` tự không làm gì.
- Không nạp kịp → lúc hiện tự tải tại chỗ, có lớp phủ "Đang tải quảng cáo…" 1–3 giây.

## 5. Tần suất

| Luật | Tự nhiên (`ad_config`) | Mua về (`ad_config_paid`) |
|---|---|---|
| `interstitial_interval` (chung `lesson_done` + `open_content`) | 45s | 30s |
| `max_interstitial_per_session` | 5 | 8 |
| `app_open_interval` | 120s | 60s |
| `max_app_open_per_session` | 3 | 4 |
| `rewarded_interval` / max | 0 / 0 (người dùng tự chọn) | như tự nhiên |
| `native_full_interval` / max | — (tắt) | 90s / 2 |

---

## 6. Remote Config

### `ad_config` (mọi người dùng) — ID thật thay `ca-app-pub-xxx/...`
```json
{
  "show_all_ads": true,
  "preload": true,
  "enable_interstitial": true,
  "enable_app_open": true,
  "enable_rewarded": true,
  "enable_rewarded_interstitial": false,
  "enable_native": true,
  "enable_banner": true,
  "enable_native_full_after_interstitial": false,
  "rules": {
    "interstitial_interval": 60, "max_interstitial_per_session": 3,
    "app_open_interval": 120, "max_app_open_per_session": 3,
    "rewarded_interval": 0, "max_rewarded_per_session": 0,
    "rewarded_interstitial_interval": 60, "max_rewarded_interstitial_per_session": 0,
    "native_full_interval": 90, "max_native_full_per_session": 0
  },
  "ad_units": {
    "app_open": {
      "splash": { "id": "ca-app-pub-xxx/APP_OPEN", "fallback_ids": [], "enable": true, "preload": true },
      "resume": { "id": "ca-app-pub-xxx/APP_OPEN", "fallback_ids": [], "enable": true, "preload": true }
    },
    "interstitial": {
      "lesson_done": { "id": "ca-app-pub-xxx/INTER", "fallback_ids": [], "enable": true, "preload": true, "native_full_after": false }
    },
    "rewarded": {
      "streak_freeze": { "id": "ca-app-pub-xxx/REWARDED", "fallback_ids": [], "enable": false, "preload": false }
    },
    "native": {
      "result": { "id": "ca-app-pub-xxx/NATIVE", "fallback_ids": [], "enable": true, "preload": false },
      "home": { "id": "ca-app-pub-xxx/NATIVE", "fallback_ids": [], "enable": false, "preload": false },
      "onboarding": { "id": "ca-app-pub-xxx/NATIVE", "fallback_ids": [], "enable": false, "preload": false },
      "after_interstitial": { "id": "ca-app-pub-xxx/NATIVE", "fallback_ids": [], "enable": false, "preload": false }
    },
    "banner": {
      "list": { "id": "ca-app-pub-xxx/BANNER", "fallback_ids": [], "enable": true, "preload": false }
    }
  }
}
```
- Một ad unit dùng chung cho nhiều vị trí cùng loại (vd 1 ID native cho `result`, `home`, `onboarding`) — đỡ tạo nhiều ad unit; tách khi cần xem doanh thu riêng.
- Mỗi ad unit bật **giá sàn tự động (Google optimized floor)** trên AdMob.
- iOS: thêm giá trị điều kiện iOS với ID iOS.

### `ad_config_paid` (chỉ người dùng mua về — giai đoạn 3)
```json
{
  "enable_native_full_after_interstitial": true,
  "rules": {
    "interstitial_interval": 45, "max_interstitial_per_session": 6,
    "app_open_interval": 60, "max_app_open_per_session": 4,
    "native_full_interval": 90, "max_native_full_per_session": 2
  },
  "ad_units": {
    "interstitial": { "lesson_done": { "native_full_after": true } },
    "native": {
      "home": { "enable": true },
      "onboarding": { "enable": true },
      "after_interstitial": { "enable": true }
    }
  }
}
```

---

## 7. Lộ trình bật dần

| Giai đoạn | Khi nào | Bật | Theo dõi |
|---|---|---|---|
| **1 — Lên chợ** | Bản đầu | App Open (lần 2+ / quay lại), interstitial xong bài, native kết quả, banner danh sách | AdMob duyệt app, eCPM, crash |
| **2 — Có số liệu** | Sau 2–4 tuần, giữ chân D1 ≥ 25% | Rewarded giữ chuỗi (cần làm tính năng), native Home / onboarding — thử trên 20% người dùng trước | D1/D7 có giảm không, doanh thu / người dùng |
| **3 — Mua người dùng** | Khi chạy quảng cáo kéo cài + Adjust | `ad_config_paid`, native toàn màn sau interstitial cho người dùng mua về | ROAS D7 / D30 trên Adjust |

**Điểm dừng:** bật thêm gì mà giữ chân D1 hoặc D7 giảm > 10% so với trước → tắt lại (sửa Remote Config, áp dụng ngay).

---

## 8. Đo lường

- Firebase: `practice_completed` (số bài xong — nguồn lượt interstitial), `ad_impression_custom` (theo vị trí), `ad_impression` (doanh thu, tự ghi khi liên kết AdMob ↔ Firebase), giữ chân D1/D7.
- AdMob: eCPM, tỉ lệ có ad (match rate), doanh thu theo ad unit.
- Chỉ số mục tiêu: doanh thu / người dùng / ngày (ARPDAU), số quảng cáo toàn màn / người / ngày ≤ 4.

---

## 9. Việc code cần làm

**Giai đoạn 1 — ✅ ĐÃ LÀM (30/10/2026)**, chỉ còn mục 6 (ID thật, app-ads.txt, privacy policy) — banner nay là `AdBannerHost` toàn app (xem giai đoạn 2).
1. Đổi hằng vị trí trong `lib/modules/ads/ad_config.dart` theo bảng mục 4 (`InterstitialPlacement.lessonDone`, `NativePlacement.result`, `BannerPlacement.list`…) + cấu hình dev.
2. Gọi `await ads.showInterstitial(InterstitialPlacement.lessonDone)` ở 5 chỗ đang ghi `practice_completed` (quiz, exercise quiz, nghe chép / luyện nói, cặp âm, động từ bất quy tắc), bỏ qua bài < 5 câu.
3. Đặt `NativeAdWidget(placement: NativePlacement.result)` ở màn kết quả các bài.
4. Đặt `AdBannerWidget(placement: BannerPlacement.list)` neo đáy các màn danh sách (bảng 3.4).
5. App Open: không hiện ở lần mở đầu tiên (đếm số lần mở).
6. AdMob App ID thật + ad unit thật trên Remote Config; `app-ads.txt`; privacy policy.

**Giai đoạn 2 — ✅ ĐÃ LÀM (30/10/2026)**, bật sẵn cho cả người dùng tự nhiên
7. "Cứu chuỗi": `LearnerNotifier.restorableStreak` / `restoreStreak()` + `StreakRestoreCard` ở Home (premium giữ miễn phí, hiện thẻ là nạp sẵn rewarded).
8. Native: Home, Onboarding, Khoá học, 4 danh sách bài (`withNativeAds`).
8b. Banner chuyển thành `AdBannerHost` toàn app (ở `app.dart`, theo `ScreenTracker.route`), interstitial `open_content` qua `AdRouteObserver`.

**Giai đoạn 3**
9. Điền token Adjust (code + `attribution_config`), tạo `ad_config_paid`.
