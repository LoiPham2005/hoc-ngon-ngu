import 'dart:async';
import 'dart:convert';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:lingua/config/flavor_config.dart';
import 'package:lingua/core/utils/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'remote_config_service.g.dart';

/// Firebase Remote Config dùng chung cho cả app. Mỗi module đọc 1 key JSON riêng
/// (`ad_config`, `app_config`...) qua [json] và nghe [onUpdated] để cập nhật realtime.
///
/// Tắt theo flavor (`FlavorConfig.useRemoteConfig`, mặc định dev tắt) → module tự dùng cấu hình local.
class RemoteConfigService {
  FirebaseRemoteConfig? _rc;
  final _updated = StreamController<void>.broadcast();

  bool get enabled => FlavorConfig.current.useRemoteConfig;

  /// Phát mỗi khi có giá trị mới (fetch lần đầu / realtime update).
  Stream<void> get onUpdated => _updated.stream;

  /// Gọi 1 lần sau `Firebase.initializeApp()`.
  Future<void> initialize() async {
    if (!enabled) return;
    final rc = FirebaseRemoteConfig.instance;
    await rc.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: kDebugMode
            ? Duration.zero
            : const Duration(hours: 1),
      ),
    );
    _rc = rc;
    // Dùng ngay giá trị đã tải lần trước, tải bản mới chạy nền → không chờ mạng lúc mở app
    // (mạng chậm / offline vẫn vào ngay). Tải xong → [onUpdated] → module tự cập nhật.
    await rc.activate();
    _updated.add(null);
    unawaited(_fetch(rc));
    rc.onConfigUpdated.listen(
      (_) async {
        await rc.activate();
        _updated.add(null);
      },
      onError: (Object e) =>
          talker.warning('[REMOTE-CONFIG] realtime update lỗi: $e'),
    );
  }

  Future<void> _fetch(FirebaseRemoteConfig rc) async {
    try {
      if (await rc.fetchAndActivate()) _updated.add(null);
    } on Object catch (e) {
      talker.warning('[REMOTE-CONFIG] fetch failed, dùng giá trị đã cache: $e');
    }
  }

  /// Giá trị JSON object của [key]; `null` khi chưa có hoặc JSON sai.
  Map<String, dynamic>? json(String key) {
    final raw = _rc?.getString(key) ?? '';
    if (raw.isEmpty) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (e) {
      talker.error('[REMOTE-CONFIG] JSON của "$key" không hợp lệ', e);
      return null;
    }
  }

  /// Đọc key JSON [key] thành model; chưa có / sai kiểu → [fallback] (cấu hình hỏng không làm sập app).
  T decode<T>(
    String key,
    T Function(Map<String, dynamic>) fromJson,
    T fallback,
  ) {
    final value = json(key);
    if (value == null) return fallback;
    try {
      return fromJson(value);
    } on Object catch (e) {
      talker.error(
        '[REMOTE-CONFIG] "$key" sai kiểu dữ liệu → dùng mặc định',
        e,
      );
      return fallback;
    }
  }

  bool getBool(String key) => _rc?.getBool(key) ?? false;
  String getString(String key) => _rc?.getString(key) ?? '';
}

@Riverpod(keepAlive: true)
RemoteConfigService remoteConfigService(Ref ref) => RemoteConfigService();

extension RemoteConfigRef on Ref {
  /// Model từ key JSON [key] cho provider cấu hình của module — tự build lại khi Remote Config
  /// đổi (realtime). `AppConfig appConfig(Ref ref) => ref.remoteConfig('app_config', ...)`.
  T remoteConfig<T>(
    String key,
    T Function(Map<String, dynamic>) fromJson,
    T fallback,
  ) {
    final remote = read(remoteConfigServiceProvider);
    final sub = remote.onUpdated.listen((_) => invalidateSelf());
    onDispose(sub.cancel);
    return remote.decode(key, fromJson, fallback);
  }
}
