# iOS Quick Action Icons — Cần thêm 12 PNG file

Plugin `quick_actions` cho iOS yêu cầu PNG template image (đen trắng, alpha mask).
4 shortcuts × 3 scale (1x/2x/3x) = **12 file PNG** cần thêm vào project.

## Danh sách file cần

| Imageset folder | Files (đặt vào trong folder cùng tên) | Size |
|---|---|---|
| `ic_shortcut_search.imageset/`  | `ic_shortcut_search.png` + `@2x.png` + `@3x.png` | 35 / 70 / 105 px |
| `ic_shortcut_logout.imageset/`  | `ic_shortcut_logout.png` + `@2x.png` + `@3x.png` | 35 / 70 / 105 px |
| `ic_shortcut_login.imageset/`   | `ic_shortcut_login.png` + `@2x.png` + `@3x.png`  | 35 / 70 / 105 px |
| `ic_shortcut_scan.imageset/`    | `ic_shortcut_scan.png` + `@2x.png` + `@3x.png`   | 35 / 70 / 105 px |

## Cách tạo nhanh

### Option A — SF Symbols app (Mac) — 5 phút cho cả 4 icons
1. Cài app **SF Symbols** (free từ Mac App Store)
2. Tìm icon tương ứng:
   - `magnifyingglass` → search
   - `rectangle.portrait.and.arrow.right` → logout
   - `arrow.right.to.line` → login
   - `qrcode.viewfinder` → scan
3. File → Export As → PNG, size 35pt
4. Lưu vào folder `<name>.imageset/` đúng tên trên

### Option B — Material Icons (web) — script bash
```bash
# Cài ImageMagick trước: brew install imagemagick
# Download SVG từ https://fonts.google.com/icons rồi:

for size in 35 70 105; do
  suffix=$([ $size -eq 35 ] && echo "" || echo "@${suffix}x")
  convert search.svg -resize ${size}x${size} ic_shortcut_search${suffix}.png
done
```

### Option C — Bỏ qua iOS, chỉ test Android
Tạm thời pass `icon: null` trong `QuickActionItem` → iOS sẽ dùng default icon (chấm xám):

```dart
const QuickActionItem(type: 'search', label: 'Tìm kiếm', icon: null)
```

(Android vẫn dùng vector từ `res/drawable/ic_shortcut_*.xml` đã có sẵn.)

## ⚠️ Lưu ý quan trọng

- **Template rendering**: Đã set `template-rendering-intent: template` trong `Contents.json`.
  → Icon phải là **đen trắng trong suốt** (alpha mask), KHÔNG full-color.
  iOS tự render thành màu phù hợp dark/light theme.

- **Test trong simulator**: Long-press app icon trên home screen sẽ thấy quick actions.

- **Xoá file này** sau khi đã add đủ 12 PNG.
