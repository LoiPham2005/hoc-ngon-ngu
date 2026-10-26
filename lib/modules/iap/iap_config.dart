import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:lingua/core/services/remote_config_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'iap_config.freezed.dart';
part 'iap_config.g.dart';

/// Bật/tắt mua hàng từ xa — Remote Config key `iap_config` (JSON), áp dụng ngay (realtime):
/// ```json
/// { "purchase_enabled": true, "premium_for_all": false }
/// ```
/// - `purchase_enabled: false` → ngừng bán: không còn gói nào để mua. Người đã mua VẪN giữ
///   premium, "Khôi phục giao dịch" vẫn chạy.
/// - `premium_for_all: true` → ai cũng là premium: dùng khi khẩn cấp (store / màn mua lỗi)
///   hoặc khi bỏ tính năng trả phí mà người cũ không bị thiệt.
///
/// Cố ý KHÔNG có cờ tước premium của người đã trả tiền (vi phạm chính sách App Store / Google Play).
/// Đổi giá / gói / tặng premium cho từng người: làm trên RevenueCat, không cần ở đây.
@freezed
abstract class IapConfig with _$IapConfig {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory IapConfig({
    @Default(true) bool purchaseEnabled,
    @Default(false) bool premiumForAll,
  }) = _IapConfig;

  factory IapConfig.fromJson(Map<String, dynamic> json) =>
      _$IapConfigFromJson(json);
}

@Riverpod(keepAlive: true)
IapConfig iapConfig(Ref ref) =>
    ref.remoteConfig('iap_config', IapConfig.fromJson, const IapConfig());
