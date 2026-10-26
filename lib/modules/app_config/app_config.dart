import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:lingua/core/services/app_version_service.dart';
import 'package:lingua/core/services/remote_config_service.dart';
import 'package:lingua/core/utils/logger.dart';
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
  String get noticeId =>
      Object.hash(noticeTitle, noticeBody, noticeUrl).toString();
}

/// `final cfg = ref.watch(appConfigProvider);` — tự cập nhật khi Remote Config đổi.
@Riverpod(keepAlive: true)
class AppConfigNotifier extends _$AppConfigNotifier {
  static const _key = 'app_config';

  @override
  AppConfig build() {
    final remote = ref.read(remoteConfigServiceProvider);
    final sub = remote.onUpdated.listen((_) => state = _read(remote));
    ref.onDispose(sub.cancel);
    return _read(remote);
  }

  AppConfig _read(RemoteConfigService remote) {
    final json = remote.json(_key);
    if (json == null) return const AppConfig();
    try {
      return AppConfig.fromJson(json);
    } on Object catch (e) {
      talker.error('[APP-CONFIG] "$_key" sai kiểu dữ liệu → dùng mặc định', e);
      return const AppConfig();
    }
  }
}
