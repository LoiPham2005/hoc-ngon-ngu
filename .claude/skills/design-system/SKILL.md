---
name: design-system
description: Theme (AppColorTokens theme_tailor, AppTheme, AppDimensions, AppTextStyles, ThemeNotifier), đa ngôn ngữ (ARB + context.l10n + LocaleNotifier + l10n-sync), asset sinh bằng flutter_gen, và catalog widget dùng chung còn tồn tại trong lib/shared (AppScaffold, AppButton, AppTextField, AppConfirmationDialog, AsyncView, Loading/Empty/ErrorRetry, AppErrorScreen, ConnectivityBanner) + toast. Đọc khi dựng UI, đổi màu/kích thước, thêm theme, dịch text, thêm ảnh, hoặc muốn biết có widget gì sẵn.
---

# Design system & UI dùng chung

## Màu — AppColorTokens

`lib/design/theme/styles/app_color_tokens.dart` — `@TailorMixin() class AppColorTokens extends ThemeExtension<AppColorTokens>`. Field: `primary, onPrimary, secondary, onSecondary, surface, onSurface, surfaceVariant, background, onBackground, error, onError, success, warning, info, outline, shadow, textPrimary, textSecondary, textTertiary, divider, disabled, red, green`. Preset: `AppColorTokens.light()`, `.dark()`, `.green()`.

Đọc trong widget:
```dart
final t = Theme.of(context).extension<AppColorTokens>()!;
Text('OK', style: TextStyle(color: t.success));
// màu Material chuẩn thì dùng colorScheme (đã map từ tokens)
final cs = Theme.of(context).colorScheme;
```
Không hard-code `Color(0x...)`/`Colors.xxx` trong feature — thêm token nếu thiếu.

Thêm token: thêm field + `required this.x` + giá trị ở mọi factory → `make gen` (sinh `app_color_tokens.tailor.dart`).

## Theme

- `AppTheme.fromVariant(AppThemeVariant)` (lib/design/theme/app_theme.dart): Material 3, `colorScheme: t.toColorScheme(brightness)`, `textTheme: AppTextStyles.theme(t)`, `extensions: [t]`, rồi `AppComponentThemes.apply` (AppBar, Card, các Button, Input, Divider, BottomNav, Dialog, SnackBar).
- `AppTheme.light()` / `AppTheme.dark()` — dùng trong test (`pumpApp`).
- `themeProvider` (lib/design/theme/theme_notifier.dart): state `AppThemeVariant { light, dark, green }` (có `label`), lưu prefs key `theme_variant`. Đổi: `ref.read(themeProvider.notifier).set(AppThemeVariant.dark)`.
- Thêm theme: thêm giá trị enum `AppThemeVariant` + factory `AppColorTokens.xxx()` + nhánh trong `AppTheme.fromVariant`.

## Kích thước & chữ

- `AppDimensions` (styles/app_dimensions.dart): `space0..space64` (2,4,8,12,16,20,24,32,40,48,56,64), `radiusXs/Sm/Md/Lg/Xl/Full`, `buttonHeightSm/Md/Lg`, `inputHeight`, `appBarHeight`, `tabBarHeight`, `iconXs..iconXl`, `elevation0..8`.
  ```dart
  const EdgeInsets.all(AppDimensions.space16)
  const SizedBox(height: AppDimensions.space12)
  ```
- Chữ: `Theme.of(context).textTheme.titleMedium` ... (`AppTextStyles.theme` định nghĩa đủ bộ TextTheme M3, màu theo tokens). Font mặc định của hệ thống (chưa nhúng font riêng).
- Kích thước là số logic thường, không có lib scale màn hình.

## Đa ngôn ngữ

- ARB: `lib/design/l10n/translations/app_en.arb` (template) + `app_vi.arb`; output `lib/gen/l10n/` (l10n.yaml, `nullable-getter: false`).
- Dùng: `context.l10n.common_retry` (extension `L10nX` ở lib/design/l10n/l10n_extensions.dart).
- Ngôn ngữ: `localeProvider` (lib/design/l10n/locale_notifier.dart), mặc định `vi`, lưu prefs key `app_locale`. Đổi: `ref.read(localeProvider.notifier).set(const Locale('en'))`.
- Thêm key: thêm vào `app_en.arb` → `make l10n-sync-translate` (dịch key thiếu bằng Google + gen) hoặc dịch tay rồi `make l10n`. Key chưa dịch thì gen-l10n tự dùng tiếng Anh; `make l10n-sync` liệt kê key chưa dịch + xoá key thừa. Chuỗi plural/select luôn dịch tay.
- Thực tế nhiều màn vẫn dùng chuỗi tiếng Việt trực tiếp; chuỗi mới cần đa ngôn ngữ thì đưa vào ARB.

## Asset

Ảnh để ở `assets/images/` hoặc `assets/icons/` (đã khai báo trong pubspec) → `make gen` → dùng `Assets.images.placeholder.image()` / `.path` (lib/gen/assets.gen.dart, flutter_gen). Không viết chuỗi path tay. Ảnh mạng: `Image.network` (không có lib cache ảnh).

## Widget dùng chung (lib/shared)

| Widget | File | Dùng |
|---|---|---|
| `AppScaffold` | base/app_scaffold.dart | Thay `Scaffold`: `body` bắt buộc; `appBar`, `floatingActionButton`, `bottomNavigationBar`, `bottomSheet`, `drawer`, `endDrawer`, `backgroundColor`, `safeArea = true`, `unfocusOnTap = true`, `resizeToAvoidBottomInset` |
| `AppButton` | base/app_button.dart | `label`, `onPressed` bắt buộc; `variant: AppButtonVariant.filled/outlined/text`, `size: AppButtonSize.sm/md/lg`, `icon`, `isLoading`, `expand = true` |
| `AppTextField` | base/app_text_field.dart | `controller`, `label`, `hint`, `helperText`, `errorText`, `prefixIcon`, `suffixIcon`, `obscureText`, `keyboardType`, `textInputAction`, `inputFormatters`, `onChanged`, `onSubmitted`, `validator`, `enabled`, `readOnly`, `maxLines`, `maxLength`, `autofocus` |
| `AppConfirmationDialog` | dialogs/app_confirmation_dialog.dart | `final ok = await AppConfirmationDialog.show(context, title: 'Xoá?', message: '...', destructive: true);` → `bool` |
| `AsyncView<T>` | states/async_view.dart | Body chuẩn cho page: loading/empty/error/data + refresh + toast (chi tiết: skill `state-management`) |
| `LoadingWidget` | states/loading_widget.dart | `LoadingWidget(message: ...)` |
| `EmptyWidget` | states/empty_widget.dart | `title`, `message`, `icon`, `action` |
| `ErrorRetry` | states/error_retry.dart | `message`, `onRetry`, `icon` |
| `AppErrorScreen` | states/app_error_screen.dart | Gắn sẵn vào `ErrorWidget.builder` trong `app.dart` |
| `ConnectivityBanner` | states/connectivity_banner.dart | Gắn sẵn ở `MaterialApp.builder` trong `app.dart` — tự báo mất mạng / đã kết nối lại, không cần gọi |

Ví dụ:
```dart
AppButton(
  label: 'Đăng nhập',
  isLoading: state.isLoading,
  onPressed: submit,
)

AppTextField(
  controller: searchCtl,
  hint: 'Tìm kiếm voucher...',
  prefixIcon: const Icon(Icons.search),
  onChanged: notifier.search,
)
```

Validate form: viết `validator: (v) => (v == null || v.isEmpty) ? 'Bắt buộc' : null` tại chỗ — không có lớp validator dùng chung.

## Toast / loading

`toast.success('Đã lưu')`, `toast.error(msg)`, `toast.warning`, `toast.info` (toastification, góc trên phải, 3s); `toast.loading('Đang xử lý...')` / `toast.stopLoading()` (flutter_smart_dialog). Lỗi/thành công của notifier đã tự toast qua `AsyncView`.

## Quy tắc

- Widget dùng ở ≥ 2 feature mới đưa vào `lib/shared`; còn lại để `features/<name>/widgets/`.
- Màu, khoảng cách, chữ lấy từ tokens/`AppDimensions`/`textTheme`.
- Tách widget con thành class (`_VoucherList`), không viết hàm `Widget _buildXxx()`.
