import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:lingua/core/utils/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Số liệu 1 vị trí quảng cáo — cùng cột với báo cáo AdMob (Requests, Matched, Show rate,
/// Impressions, Clicks, CTR) + [skipped]: lần định hiện mà không hiện, theo lý do.
@immutable
class AdStatRow {
  const AdStatRow({
    this.requests = 0,
    this.matched = 0,
    this.impressions = 0,
    this.clicks = 0,
    this.revenue = 0,
    this.currency = '',
    this.skipped = const {},
  });

  factory AdStatRow.fromJson(Map<String, dynamic> json) => AdStatRow(
    requests: json['requests'] as int? ?? 0,
    matched: json['matched'] as int? ?? 0,
    impressions: json['impressions'] as int? ?? 0,
    clicks: json['clicks'] as int? ?? 0,
    revenue: (json['revenue'] as num?)?.toDouble() ?? 0,
    currency: json['currency'] as String? ?? '',
    skipped: (json['skipped'] as Map<String, dynamic>? ?? {}).map(
      (k, v) => MapEntry(k, v as int),
    ),
  );

  /// Lượt xin ad đã có kết quả (có ad + không có ad).
  final int requests;

  /// Lượt xin có ad trả về.
  final int matched;
  final int impressions;
  final int clicks;

  /// Doanh thu ước tính (AdMob `onPaidEvent`); ad test luôn 0.
  final double revenue;
  final String currency;

  /// Lý do (`interval`, `session_cap`, `busy`, `not_ready`, `show_failed`, `cooldown`) → số lần.
  final Map<String, int> skipped;

  double get matchRate => requests == 0 ? 0 : matched / requests;

  /// Có ad về mà không hiện (preload hết hạn, rời màn trước khi ad lên…) → kéo tụt chỉ số này.
  double get showRate => matched == 0 ? 0 : impressions / matched;
  double get ctr => impressions == 0 ? 0 : clicks / impressions;
  double get ecpm => impressions == 0 ? 0 : revenue / impressions * 1000;
  int get skippedTotal => skipped.values.fold(0, (a, b) => a + b);

  AdStatRow copyWith({
    int? requests,
    int? matched,
    int? impressions,
    int? clicks,
    double? revenue,
    String? currency,
    Map<String, int>? skipped,
  }) => AdStatRow(
    requests: requests ?? this.requests,
    matched: matched ?? this.matched,
    impressions: impressions ?? this.impressions,
    clicks: clicks ?? this.clicks,
    revenue: revenue ?? this.revenue,
    currency: currency ?? this.currency,
    skipped: skipped ?? this.skipped,
  );

  Map<String, dynamic> toJson() => {
    'requests': requests,
    'matched': matched,
    'impressions': impressions,
    'clicks': clicks,
    'revenue': revenue,
    'currency': currency,
    'skipped': skipped,
  };
}

/// Đếm theo vị trí (`interstitial.lesson_done`, `native.list`…) trên MÁY NÀY, lưu qua các lần
/// mở app. Mỗi sự kiện in 1 dòng `[ADS] ...`; [logSummary] in cả bảng (tự gọi khi app ra nền ở
/// bản dev/stg) — để biết vị trí nào có ad mà không hiện, bị chặn vì lý do gì.
/// Số liệu toàn bộ người dùng: báo cáo AdMob (mỗi vị trí 1 ad unit riêng).
class AdStats {
  AdStats(this._prefs) {
    final raw = _prefs.getString(_key);
    if (raw == null) return;
    try {
      rows.value = (jsonDecode(raw) as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, AdStatRow.fromJson(v as Map<String, dynamic>)),
      );
    } on Object {
      unawaited(_prefs.remove(_key));
    }
  }

  static const _key = 'ad_stats_v1';
  final SharedPreferences _prefs;
  final rows = ValueNotifier<Map<String, AdStatRow>>({});

  /// 1 lượt xin ad có kết quả: [matched] = có ad về.
  void request(String key, {required bool matched}) => _update(
    key,
    matched ? 'matched' : 'no fill',
    (r) => r.copyWith(
      requests: r.requests + 1,
      matched: r.matched + (matched ? 1 : 0),
    ),
  );

  void impression(String key) => _update(
    key,
    'impression',
    (r) => r.copyWith(impressions: r.impressions + 1),
  );

  void click(String key) =>
      _update(key, 'click', (r) => r.copyWith(clicks: r.clicks + 1));

  void paid(String key, double valueMicros, String currency) => _update(
    key,
    'paid $valueMicros $currency',
    (r) => r.copyWith(
      revenue: r.revenue + valueMicros / 1000000,
      currency: currency,
    ),
  );

  void skip(String key, String reason) => _update(
    key,
    'skipped: $reason',
    (r) => r.copyWith(
      skipped: {...r.skipped, reason: (r.skipped[reason] ?? 0) + 1},
    ),
  );

  /// In bảng giống báo cáo AdMob ra Debug Console, vị trí nhiều request nhất lên đầu.
  void logSummary() {
    final sorted = rows.value.entries.toList()
      ..sort((a, b) => b.value.requests.compareTo(a.value.requests));
    if (sorted.isEmpty) return;
    String pct(double v) => '${(v * 100).toStringAsFixed(1)}%';
    String cell(Object v, int w) => '$v'.padLeft(w);
    final lines = [
      '${'Ad'.padRight(30)}${cell('Req', 6)}${cell('Match', 7)}${cell('Match%', 8)}'
          '${cell('Impr', 6)}${cell('Show%', 8)}${cell('Click', 7)}${cell('CTR', 8)}'
          '${cell('Rev', 10)}  Bỏ lỡ',
      for (final MapEntry(key: name, value: r) in sorted)
        '${name.padRight(30)}${cell(r.requests, 6)}${cell(r.matched, 7)}'
            '${cell(pct(r.matchRate), 8)}${cell(r.impressions, 6)}'
            '${cell(pct(r.showRate), 8)}${cell(r.clicks, 7)}${cell(pct(r.ctr), 8)}'
            '${cell(r.revenue.toStringAsFixed(4), 10)}  '
            '${r.skippedTotal}${r.skipped.isEmpty ? '' : ' ${r.skipped}'}',
    ];
    talker.info('[ADS] Thống kê quảng cáo (máy này)\n${lines.join('\n')}');
  }

  void _update(String key, String event, AdStatRow Function(AdStatRow) f) {
    talker.debug('[ADS] $key $event');
    rows.value = {...rows.value, key: f(rows.value[key] ?? const AdStatRow())};
    unawaited(
      _prefs.setString(
        _key,
        jsonEncode(rows.value.map((k, v) => MapEntry(k, v.toJson()))),
      ),
    );
  }
}
