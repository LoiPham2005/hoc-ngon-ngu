import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:lingua/core/services/remote_config_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_config.freezed.dart';
part 'app_config.g.dart';

/// Cấu hình bật/tắt từ xa — Remote Config key `app_config` (JSON), field thiếu dùng mặc định:
/// ```json
/// { "maintenance_mode": false, "maintenance_message": "...",
///   "notice_enabled": true, "notice_title": "...", "notice_body": "...", "notice_url": "...",
///   "policy_url": "...", "terms_url": "..." }
/// ```
@freezed
abstract class AppConfig with _$AppConfig {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory AppConfig({
    @JsonKey(name: 'maintenance_mode') @Default(false) bool isMaintenance,
    @Default('') String maintenanceMessage,
    @Default(false) bool noticeEnabled,
    @Default('') String noticeTitle,
    @Default('') String noticeBody,
    @Default('') String noticeUrl,
    @Default('') String policyUrl,
    @Default('') String termsUrl,
  }) = _AppConfig;

  const AppConfig._();

  factory AppConfig.fromJson(Map<String, dynamic> json) =>
      _$AppConfigFromJson(json);

  bool get hasNotice => noticeEnabled && noticeTitle.isNotEmpty;
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
    } catch (_) {
      return const AppConfig();
    }
  }
}
