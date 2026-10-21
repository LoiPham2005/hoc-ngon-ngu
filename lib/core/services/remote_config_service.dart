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
    try {
      await rc.fetchAndActivate();
    } catch (e) {
      talker.warning('[REMOTE-CONFIG] fetch failed, dùng giá trị đã cache: $e');
    }
    _updated.add(null);
    rc.onConfigUpdated.listen(
      (_) async {
        await rc.activate();
        _updated.add(null);
      },
      onError: (Object e) =>
          talker.warning('[REMOTE-CONFIG] realtime update lỗi: $e'),
    );
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

  bool getBool(String key) => _rc?.getBool(key) ?? false;
  String getString(String key) => _rc?.getString(key) ?? '';
}

@Riverpod(keepAlive: true)
RemoteConfigService remoteConfigService(Ref ref) => RemoteConfigService();
