import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:lingua/core/services/app_version_service.dart';
import 'package:lingua/core/services/remote_config_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_config.freezed.dart';
part 'app_config.g.dart';

/// Điều khiển app từ xa không cần phát hành bản mới — Remote Config key `app_config` (JSON).
/// Field thiếu / JSON sai → giá trị mặc định (không chặn gì), nên cấu hình hỏng không khoá app.
/// ```json
/// {
///   "min_version": "1.2.0",          // bản thấp hơn → BẮT BUỘC cập nhật mới dùng được
///   "maintenance": false,            // true → khoá app, hiện màn bảo trì
///   "maintenance_message": "",       // trống → câu mặc định
///   "notice_title": "", "notice_body": "", "notice_url": ""  // thông báo lúc mở app
/// }
/// ```
/// Áp dụng ngay khi đổi trên Firebase Console (realtime), không cần mở lại app — xem `AppGate`.
/// Bản mới KHÔNG bắt buộc: app tự thấy trên store (`AppVersionService`), không cần khai ở đây.
@freezed
abstract class AppConfig with _$AppConfig {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory AppConfig({
    @Default('') String minVersion,
    @Default(false) bool maintenance,
    @Default('') String maintenanceMessage,
    @Default('') String noticeTitle,
    @Default('') String noticeBody,
    @Default('') String noticeUrl,
  }) = _AppConfig;

  const AppConfig._();

  factory AppConfig.fromJson(Map<String, dynamic> json) =>
      _$AppConfigFromJson(json);

  /// Bản [current] thấp hơn [minVersion] → phải cập nhật.
  bool mustUpdate(String current) =>
      minVersion.isNotEmpty && isNewer(minVersion, current);

  /// Có thông báo (để trống tiêu đề = tắt).
  bool get hasNotice => noticeTitle.isNotEmpty;

  /// Mã nội dung thông báo: sửa chữ → coi là thông báo mới, hiện lại cho mọi người.
  /// Ghép thẳng nội dung (không dùng hashCode: đổi giữa các lần mở app → hiện lại mãi).
  String get noticeId => '$noticeTitle|$noticeBody|$noticeUrl';
}

/// `final cfg = ref.watch(appConfigProvider);` — tự cập nhật khi Remote Config đổi.
@Riverpod(keepAlive: true)
AppConfig appConfig(Ref ref) =>
    ref.remoteConfig('app_config', AppConfig.fromJson, const AppConfig());
