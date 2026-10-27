import 'dart:async';
import 'dart:convert';

import 'package:adjust_sdk/adjust.dart';
import 'package:adjust_sdk/adjust_ad_revenue.dart';
import 'package:adjust_sdk/adjust_attribution.dart';
import 'package:adjust_sdk/adjust_config.dart';
import 'package:adjust_sdk/adjust_event.dart';
import 'package:flutter/foundation.dart';
import 'package:lingua/config/flavor_config.dart';
import 'package:lingua/core/di/global_providers.dart';
import 'package:lingua/core/utils/logger.dart';
import 'package:lingua/modules/attribution/attribution_config.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'attribution_service.g.dart';

/// Đo nguồn cài đặt bằng **Adjust** (MMP): người dùng đến từ chiến dịch quảng cáo trả tiền
/// ([isPaid]) hay tự nhiên, + gửi doanh thu từng lượt hiển thị quảng cáo về Adjust để tính ROAS
/// theo chiến dịch. Chỉ cần khi CHẠY QUẢNG CÁO MUA NGƯỜI DÙNG ở nhiều nền tảng (Meta, TikTok…).
///
/// **App token**: Remote Config `attribution_config.app_token` (đổi không cần ra bản mới) →
/// không có thì [_codeAppToken]. Cả hai trống → tắt hẳn. Lần mở đầu chưa có Remote Config mà
/// token chỉ nằm trên đó → chờ tải xong mới khởi động (Adjust vẫn ghi nhận lượt cài).
/// Người dùng mua về → quảng cáo trộn thêm Remote Config `ad_config_paid` (xem AdManager).
/// iOS: dùng chung hộp thoại ATT của `AdConsent`; Adjust tự chờ người dùng trả lời
/// ([_attWaitSeconds]) rồi mới gửi lượt cài (để có IDFA). SKAdNetwork do SDK tự lo.
class AttributionService {
  AttributionService(
    this._prefs, {
    required AttributionConfig Function() config,
    @visibleForTesting void Function(String appToken)? start,
    @visibleForTesting void Function(String eventToken)? sendEvent,
  }) : _config = config,
       _startHook = start,
       _sendHook = sendEvent;

  /// Adjust dashboard → app → **App token**. Dự phòng khi Remote Config không có.
  static const _codeAppToken = '';
  static const _attWaitSeconds = 30;
  static const _kNetwork = 'attribution_network_v1';
  static const _kRevenue = 'attribution_ad_revenue_v1';
  static const _kImpressions = 'attribution_ad_impressions_v1';
  static const _kSentEvents = 'attribution_sent_events_v1';

  /// Tên `network` Adjust gán cho người dùng TỰ NHIÊN.
  static const _organicNetworks = {'Organic', 'Google Organic Search'};

  /// Chưa rõ nguồn: [AttributionConfig.paidWhenUnknown] quyết định là mua về hay tự nhiên.
  static const _unknownNetworks = {'', 'Unattributed', 'Untrusted Devices'};

  final SharedPreferences _prefs;
  final AttributionConfig Function() _config;
  final void Function(String appToken)? _startHook;
  final void Function(String eventToken)? _sendHook;
  bool _started = false;

  /// Adjust đang chạy (đã có app token và đã khởi động).
  bool get enabled => _started;

  /// Người dùng đến từ chiến dịch trả tiền. Tính lại khi Adjust trả kết quả / cấu hình đổi.
  late final isPaid = ValueNotifier<bool>(_classify());

  String get _appToken {
    final remote = _config().appToken;
    return remote.isNotEmpty ? remote : _codeAppToken;
  }

  Future<void> initialize() async {
    final token = _appToken;
    // Chưa có token (lần mở đầu, Remote Config chưa tải) → chờ [onConfigChanged].
    if (token.isEmpty) return;
    await _start(token);
  }

  /// Remote Config `attribution_config` đổi: có token mới → khởi động (nếu chưa);
  /// chính sách "chưa rõ nguồn" đổi → tính lại [isPaid].
  void onConfigChanged() {
    if (!_started && _appToken.isNotEmpty) unawaited(_start(_appToken));
    isPaid.value = _classify();
  }

  Future<void> _start(String token) async {
    if (_started) return;
    _started = true;
    if (_startHook case final hook?) return hook(token);
    final config =
        AdjustConfig(
            token,
            FlavorConfig.isProd
                ? AdjustEnvironment.production
                : AdjustEnvironment.sandbox,
          )
          ..logLevel = FlavorConfig.isProd
              ? AdjustLogLevel.suppress
              : AdjustLogLevel.verbose
          ..attConsentWaitingInterval = _attWaitSeconds
          ..attributionCallback = _onAttribution;
    Adjust.initSdk(config);
    // Đã có kết quả từ lần trước / vừa cài xong → cập nhật ngay, không chờ callback.
    final current = await Adjust.getAttributionWithTimeout(3000);
    if (current != null) _onAttribution(current);
  }

  void _onAttribution(AdjustAttribution attribution) =>
      recordNetwork(attribution.network ?? '');

  /// Lưu `network` Adjust trả về rồi tính lại [isPaid].
  @visibleForTesting
  void recordNetwork(String network) {
    unawaited(_prefs.setString(_kNetwork, network));
    isPaid.value = _classify(network);
    talker.info(
      '[ATTRIBUTION] "$network" → ${isPaid.value ? 'paid' : 'organic'}',
    );
  }

  /// Chưa có kết quả nào (`null`) → tự nhiên; tự nhiên → không; chưa rõ → theo cấu hình;
  /// còn lại (tên mạng quảng cáo) → mua về.
  bool _classify([String? network]) {
    final value = network ?? _prefs.getString(_kNetwork);
    if (value == null || _organicNetworks.contains(value)) return false;
    if (_unknownNetworks.contains(value)) return _config().paidWhenUnknown;
    return true;
  }

  /// Doanh thu 1 lượt hiển thị (AdMob `onPaidEvent`, đơn vị micro) → Adjust tính ROAS,
  /// + cộng dồn để gửi sự kiện "người dùng giá trị" khi vượt ngưỡng.
  void trackAdRevenue({
    required double valueMicros,
    required String currency,
    required String placement,
    String? adSource,
    String? adUnitId,
  }) {
    if (!_started) return;
    // Test (có [_startHook]) không gọi SDK thật, chỉ kiểm phần cộng dồn.
    if (_startHook == null) {
      final revenue = AdjustAdRevenue('admob_sdk')
        ..setRevenue(valueMicros / 1000000, currency)
        ..adRevenuePlacement = placement
        ..adRevenueNetwork = adSource
        ..adRevenueUnit = adUnitId;
      Adjust.trackAdRevenue(revenue);
    }
    _accumulate(valueMicros / 1000000, currency);
  }

  /// Cộng dồn doanh thu (theo từng loại tiền) + số lượt; vượt ngưỡng → gửi sự kiện 1 lần.
  void _accumulate(double value, String currency) {
    final revenue = _revenueByCurrency()
      ..update(currency, (v) => v + value, ifAbsent: () => value);
    final impressions = (_prefs.getInt(_kImpressions) ?? 0) + 1;
    unawaited(_prefs.setString(_kRevenue, jsonEncode(revenue)));
    unawaited(_prefs.setInt(_kImpressions, impressions));

    final sent = _prefs.getStringList(_kSentEvents)?.toSet() ?? <String>{};
    for (final event in _config().valueEvents) {
      if (sent.contains(event.token)) continue;
      final reached =
          (event.adRevenue != null &&
              (revenue[event.currency] ?? 0) >= event.adRevenue!) ||
          (event.adImpressions != null && impressions >= event.adImpressions!);
      if (!reached) continue;
      sent.add(event.token);
      (_sendHook ?? (t) => Adjust.trackEvent(AdjustEvent(t)))(event.token);
      talker.info('[ATTRIBUTION] value event ${event.token} sent');
    }
    unawaited(_prefs.setStringList(_kSentEvents, sent.toList()));
  }

  Map<String, double> _revenueByCurrency() {
    final raw = _prefs.getString(_kRevenue);
    if (raw == null) return {};
    return {
      for (final MapEntry(:key, :value)
          in (jsonDecode(raw) as Map<String, dynamic>).entries)
        key: (value as num).toDouble(),
    };
  }
}

@Riverpod(keepAlive: true)
AttributionService attributionService(Ref ref) {
  final service = AttributionService(
    ref.read(sharedPrefsProvider),
    config: () => ref.read(attributionConfigProvider),
  );
  ref.listen(attributionConfigProvider, (_, _) => service.onConfigChanged());
  return service;
}
