/// Thông tin app trên store (dùng chung mọi flavor). Điền giá trị thật trước khi release.
abstract class AppInfo {
  static const appName = 'Lingua';

  /// Id số trên App Store Connect (vd `1234567890`).
  static const appStoreId = '';

  /// applicationId bản prod trên Google Play (khớp flavor prod trong flavorizr.yaml).
  static const playStoreId = 'com.loipham.lingua';

  /// Rỗng khi chưa điền [appStoreId].
  static const appStoreUrl = appStoreId == ''
      ? ''
      : 'https://apps.apple.com/app/id$appStoreId';
  static const playStoreUrl =
      'https://play.google.com/store/apps/details?id=$playStoreId';

  /// Link chính sách bảo mật / điều khoản (hiện ở Hồ sơ → Thông tin; trống → ẩn).
  /// App Store bắt buộc có link chính sách bảo mật trong app (nhất là app có mua trong app).
  static const privacyPolicyUrl = '';
  static const termsUrl = '';
}
