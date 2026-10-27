import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:lingua/core/services/remote_config_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'attribution_config.freezed.dart';
part 'attribution_config.g.dart';

/// Cài đặt đo nguồn (Adjust) chỉnh từ xa — Remote Config key `attribution_config` (JSON):
/// ```json
/// {
///   "app_token": "",                 // trống → dùng token trong code (AttributionService)
///   "paid_when_unknown": false,      // chưa rõ nguồn (rỗng / Unattributed) → coi là mua về?
///   "value_events": [                // sự kiện "người dùng giá trị", gửi 1 lần / người
///     { "token": "abc123", "ad_revenue": 0.05, "currency": "USD" },
///     { "token": "def456", "ad_impressions": 20 }
///   ]
/// }
/// ```
/// Chỉ để mã KHÔNG bí mật (app token, event token vốn nằm sẵn trong app). KHÔNG để API token
/// của Adjust ở đây — Remote Config ai dịch ngược app cũng đọc được.
@freezed
abstract class AttributionConfig with _$AttributionConfig {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory AttributionConfig({
    @Default('') String appToken,
    @Default(false) bool paidWhenUnknown,
    @Default(<ValueEvent>[]) List<ValueEvent> valueEvents,
  }) = _AttributionConfig;

  factory AttributionConfig.fromJson(Map<String, dynamic> json) =>
      _$AttributionConfigFromJson(json);
}

/// 1 sự kiện mốc: người dùng vượt ngưỡng doanh thu quảng cáo cộng dồn ([adRevenue], theo
/// [currency]) HOẶC số lượt hiển thị quảng cáo ([adImpressions]) → gửi [token] về Adjust 1 lần.
/// Adjust chuyển tiếp cho Google / Meta / TikTok… để chiến dịch tìm thêm người giống vậy.
@freezed
abstract class ValueEvent with _$ValueEvent {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory ValueEvent({
    required String token,
    double? adRevenue,
    @Default('USD') String currency,
    int? adImpressions,
  }) = _ValueEvent;

  factory ValueEvent.fromJson(Map<String, dynamic> json) =>
      _$ValueEventFromJson(json);
}

@Riverpod(keepAlive: true)
AttributionConfig attributionConfig(Ref ref) => ref.remoteConfig(
  'attribution_config',
  AttributionConfig.fromJson,
  const AttributionConfig(),
);
