# Hướng dẫn: app-ads.txt + trang chính sách bảo mật

Làm **một lần cho mỗi app có quảng cáo**, trước hoặc ngay sau khi lên chợ. Mất khoảng 30 phút, sau đó chờ AdMob xác nhận tối đa 24 giờ.

## Vì sao phải làm

- **app-ads.txt** là file văn bản đặt ở gốc website của bạn, ghi mã nhà xuất bản AdMob. Nhà quảng cáo đọc file này để chắc chắn quảng cáo trong app đúng là do bạn bán (chống giả mạo).
  Thiếu file này thì nhiều nhà quảng cáo không mua, nên **ít quảng cáo hơn và giá thấp hơn**, và AdMob báo lỗi "app-ads.txt not found".
- **Chính sách bảo mật**: Google Play và App Store đều bắt buộc có link chính sách bảo mật, và App Store còn bắt buộc có link này **trong app**. Đặt chung một website với app-ads.txt.

## Cần chuẩn bị

- App đã được thêm trên AdMob.
- Một website mà bạn đặt được file ở **gốc tên miền** (`https://<tên-miền>/app-ads.txt`). Hướng dẫn dưới dùng **Firebase Hosting**: miễn phí, có HTTPS, và dự án vốn đã dùng Firebase.
- Quyền sửa trang app trên Google Play Console / App Store Connect.

---

## Bước 1 — Lấy dòng app-ads.txt từ AdMob

AdMob → **Apps** → **View all apps** → tab **app-ads.txt** → **How to set up app-ads.txt** → copy đoạn mã. Đoạn mã có dạng:

```
google.com, pub-1234567890123456, DIRECT, f08c47fec0942fa0
```

> Copy đúng đoạn AdMob đưa, đừng tự gõ: sai một chữ số `pub-` là không xác nhận được.

## Bước 2 — Tạo website bằng Firebase Hosting

Tạo thư mục `site/` ở gốc dự án (tách khỏi thư mục `web/` của Flutter):

```bash
npm install -g firebase-tools     # cài 1 lần
firebase login
mkdir site && cd site
firebase init hosting
#  - Chọn project Firebase của bản PROD
#  - Public directory: public
#  - Configure as a single-page app: No
#  - Set up automatic builds with GitHub: No
```

Đặt 3 file vào `site/public/`:

```
site/public/
├── app-ads.txt          ← dòng đã copy ở bước 1
├── privacy-policy.html  ← chính sách bảo mật (mẫu ở cuối tài liệu)
└── index.html           ← trang giới thiệu ngắn: tên app + link tải + link chính sách
```

Đưa lên mạng:

```bash
firebase deploy --only hosting
```

Website sẽ có địa chỉ dạng `https://<project-id>.web.app`. Muốn dùng tên miền riêng (vd `lingua.app`) thì vào Firebase console → **Hosting** → **Add custom domain** và làm theo hướng dẫn trỏ DNS.

## Bước 3 — Kiểm tra bằng trình duyệt

Mở `https://<tên-miền>/app-ads.txt`. Phải thấy **đúng dòng ở bước 1**, dạng chữ thường. Nếu bị chuyển sang trang khác, hiện trang đăng nhập hoặc báo 404 thì AdMob cũng không đọc được.

## Bước 4 — Khai website trên trang app ở chợ

AdMob tìm app-ads.txt **theo tên miền của website khai trên trang app**, không theo link nào khác.

| Chợ | Chỗ điền |
|---|---|
| Google Play | Play Console → **Grow users → Store presence → Store settings** → *Store listing contact details* → **Website** |
| App Store | App Store Connect → app → mục thông tin app → **Marketing URL** (kiểm tra cuối trang app trên App Store có hiện link "Developer Website") |

Chỉ cần điền tên miền, ví dụ `https://lingua.app`, không cần điền cả đường dẫn tới app-ads.txt.

## Bước 5 — Chờ AdMob xác nhận

AdMob → **Apps** → **View all apps** → **app-ads.txt** → mở dòng của app → **Check for updates**.
AdMob cần tới **24 giờ** để quét. Trạng thái đúng là app-ads.txt **found / verified**.

## Bước 6 — Gắn link chính sách vào app và chợ

- App: điền `privacyPolicyUrl` (và `termsUrl` nếu có) trong `lib/config/app_info.dart`. Màn Cài đặt / Hồ sơ sẽ tự hiện dòng "Chính sách bảo mật".
- Google Play Console: **Policy → App content → Privacy policy**.
- App Store Connect: **App Privacy → Privacy Policy URL**.

---

## Khi bật mediation (AppLovin, Meta, Unity…)

Mỗi mạng có dòng app-ads.txt riêng, lấy trong trang quản trị của mạng đó. **Thêm vào cùng file** (mỗi dòng một mạng), rồi chạy lại `firebase deploy --only hosting`. Không cần sửa gì trên chợ.

## Lỗi thường gặp

| Hiện tượng | Nguyên nhân / cách sửa |
|---|---|
| AdMob báo "not found" dù mở được file | Website khai trên chợ khác tên miền chứa file; hoặc chưa đủ 24 giờ |
| Website khai là `www.ten-mien.com` | AdMob bỏ `www.` và tìm ở `ten-mien.com` → file phải mở được ở `https://ten-mien.com/app-ads.txt` |
| Website là GitHub Pages dạng `user.github.io/ten-repo` | File phải ở gốc host. Dùng repo `user.github.io` hoặc chuyển sang Firebase Hosting |
| Vừa sửa website trên Play Console mà AdMob chưa thấy | Thay đổi trên trang app phải qua duyệt; sau đó AdMob cần thêm tới 24 giờ |
| Có 2 app dùng chung 1 tài khoản AdMob | Dùng chung một file / một website được, dòng `google.com, pub-…` chỉ cần ghi một lần |

---

## Mẫu `privacy-policy.html` (sửa lại cho đúng app)

Liệt kê đúng các dịch vụ app thật sự dùng. Mẫu dưới dành cho app dùng AdMob + Firebase Analytics + Crashlytics + RevenueCat.

```html
<!doctype html>
<html lang="vi">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Chính sách bảo mật — TÊN APP</title>
  <style>body{font-family:system-ui,sans-serif;max-width:720px;margin:2rem auto;padding:0 1rem;line-height:1.6}</style>
</head>
<body>
  <h1>Chính sách bảo mật — TÊN APP</h1>
  <p>Cập nhật: NGÀY/THÁNG/NĂM</p>

  <h2>Dữ liệu chúng tôi thu thập</h2>
  <ul>
    <li><b>Quảng cáo (Google AdMob)</b>: mã quảng cáo của thiết bị, thông tin thiết bị, vị trí gần đúng theo IP để hiển thị và đo lường quảng cáo. Người dùng ở EU/UK được hỏi đồng ý trước khi dùng quảng cáo cá nhân hoá.</li>
    <li><b>Thống kê (Firebase Analytics)</b>: các màn hình đã xem, thao tác trong app, loại thiết bị — để cải thiện app. Không gắn với tên hay email.</li>
    <li><b>Báo lỗi (Firebase Crashlytics)</b>: thông tin kỹ thuật khi app gặp lỗi.</li>
    <li><b>Mua trong app (RevenueCat, Google Play, App Store)</b>: lịch sử mua gói để mở khoá tính năng. Chúng tôi không nhận thông tin thẻ thanh toán.</li>
  </ul>

  <h2>Dữ liệu lưu trên máy</h2>
  <p>Tiến độ học và cài đặt được lưu ngay trên thiết bị của bạn và bị xoá khi gỡ app.</p>

  <h2>Quyền của bạn</h2>
  <ul>
    <li>Tắt quảng cáo cá nhân hoá: trong Cài đặt của app (mục Quyền riêng tư) hoặc trong cài đặt của điện thoại.</li>
    <li>Yêu cầu xoá dữ liệu: gửi email tới địa chỉ bên dưới.</li>
  </ul>

  <h2>Trẻ em</h2>
  <p>App không dành cho trẻ em dưới 13 tuổi và không cố ý thu thập dữ liệu của trẻ em.</p>

  <h2>Liên hệ</h2>
  <p>Email: EMAIL@CUA-BAN.COM</p>
</body>
</html>
```

> Nội dung chính sách phải **khớp với phần "An toàn dữ liệu" (Google Play) và "App Privacy" (App Store)** đã khai. Khi thêm SDK mới (ví dụ mạng mediation) thì cập nhật cả ba chỗ.
