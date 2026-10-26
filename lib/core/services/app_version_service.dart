import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:lingua/core/di/global_providers.dart';
import 'package:lingua/core/utils/logger.dart';
import 'package:lingua/design/l10n/l10n_extensions.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

part 'app_version_service.g.dart';

/// Bản mới trên store.
class StoreUpdate {
  const StoreUpdate({
    required this.version,
    required this.force,
    this.currentVersion,
    this.storeUrl,
    this.android,
  });

  /// Mã bản mới để nhớ "Để sau": tên phiên bản (iOS) hoặc versionCode (Android).
  final String version;

  /// Bắt buộc cập nhật (Android: bản phát hành đặt độ ưu tiên ≥ 4 trên Play Console).
  final bool force;
  final String? currentVersion;

  /// iOS: trang App Store của app.
  final String? storeUrl;

  /// Android: thông tin của Google Play để mở màn cập nhật trong app.
  final AppUpdateInfo? android;
}

/// Kiểm tra bản mới NGAY TRÊN STORE khi mở app (không cần server riêng):
/// - Android: Google Play In-App Updates — cập nhật ngay trong app (màn của Google Play).
/// - iOS: API tra cứu công khai của Apple (`itunes.apple.com/lookup`) → mở App Store.
///
/// Bắt buộc cập nhật: đặt "update priority" 4–5 khi phát hành trên Play Console
/// (iOS không có khái niệm này → luôn là gợi ý). Bấm "Để sau" → 3 ngày sau mới hỏi lại bản đó.
/// Mọi lỗi (không có mạng, app không cài từ store…) → bỏ qua, không chặn người dùng.
class AppVersionService {
  AppVersionService(this._prefs, {Dio? dio}) : _dio = dio ?? Dio();

  final SharedPreferences _prefs;
  final Dio _dio;

  static const _snoozeKey = 'update_snooze_v1';
  static const remindAfter = Duration(days: 3);

  /// Trả `false` khi bắt buộc cập nhật (splash dừng lại), còn lại `true`.
  Future<bool> checkAndPrompt(BuildContext context) async {
    final StoreUpdate? update;
    try {
      update = Platform.isAndroid ? await _checkPlay() : await _checkAppStore();
    } on Object catch (e, s) {
      talker.warning('[APP-VERSION] store check skipped: $e', s);
      return true;
    }
    if (update == null || !context.mounted) return true;
    if (!update.force && isSnoozed(update.version)) return true;

    final now = await _ask(context, update);
    if (now) {
      await _install(update);
    } else {
      await snooze(update.version);
    }
    return !update.force;
  }

  Future<StoreUpdate?> _checkPlay() async {
    final info = await InAppUpdate.checkForUpdate();
    if (info.updateAvailability != UpdateAvailability.updateAvailable) {
      return null;
    }
    return StoreUpdate(
      version: '${info.availableVersionCode ?? ''}',
      force: info.updatePriority >= 4 && info.immediateUpdateAllowed,
      android: info,
    );
  }

  Future<StoreUpdate?> _checkAppStore() async {
    final pkg = await PackageInfo.fromPlatform();
    final res = await _dio.get<Map<String, dynamic>>(
      'https://itunes.apple.com/lookup',
      queryParameters: {
        'bundleId': pkg.packageName,
        // Thêm tham số thời gian để không nhận kết quả cũ trong bộ nhớ đệm của Apple.
        't': DateTime.now().millisecondsSinceEpoch,
      },
    );
    final store = parseAppStoreLookup(res.data);
    if (store == null || !isNewer(store.version, pkg.version)) return null;
    return StoreUpdate(
      version: store.version,
      currentVersion: pkg.version,
      force: false,
      storeUrl: store.url,
    );
  }

  Future<bool> _ask(BuildContext context, StoreUpdate update) async {
    final l10n = context.l10n;
    final versions = update.currentVersion == null
        ? ''
        : '\n\n${update.currentVersion} → ${update.version}';
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: !update.force,
      builder: (ctx) => PopScope(
        // Bắt buộc: không đóng được, cũng không tự thoát app (store không cho phép).
        canPop: !update.force,
        child: AlertDialog(
          title: Text(
            update.force ? l10n.update_forceTitle : l10n.update_optionalTitle,
          ),
          content: Text(
            '${update.force ? l10n.update_forceMessage : l10n.update_optionalMessage}'
            '$versions',
          ),
          actions: [
            if (!update.force)
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.update_later),
              ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.update_now),
            ),
          ],
        ),
      ),
    );
    return result ?? false;
  }

  Future<void> _install(StoreUpdate update) async {
    try {
      final info = update.android;
      if (info != null) {
        // Màn cập nhật của Google Play ngay trong app; không được phép → mở CH Play.
        if (info.immediateUpdateAllowed) {
          await InAppUpdate.performImmediateUpdate();
          return;
        }
        final pkg = await PackageInfo.fromPlatform();
        await _open(
          'https://play.google.com/store/apps/details?id=${pkg.packageName}',
        );
        return;
      }
      if (update.storeUrl case final url?) await _open(url);
    } on Object catch (e, s) {
      talker.error('[APP-VERSION] install failed', e, s);
    }
  }

  Future<void> _open(String url) =>
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

  /// Đã bấm "Để sau" cho bản [version] trong [remindAfter] vừa qua.
  bool isSnoozed(String version, {DateTime? now}) {
    final saved = _prefs.getString(_snoozeKey)?.split('|');
    if (saved == null || saved.length != 2 || saved[0] != version) return false;
    final at = DateTime.fromMillisecondsSinceEpoch(int.tryParse(saved[1]) ?? 0);
    return (now ?? DateTime.now()).difference(at) < remindAfter;
  }

  Future<void> snooze(String version, {DateTime? now}) => _prefs.setString(
    _snoozeKey,
    '$version|${(now ?? DateTime.now()).millisecondsSinceEpoch}',
  );
}

/// Phiên bản + link App Store từ kết quả `itunes.apple.com/lookup` (không có app → `null`).
({String version, String url})? parseAppStoreLookup(
  Map<String, dynamic>? json,
) {
  final results = json?['results'];
  if (results is! List || results.isEmpty) return null;
  final app = results.first as Map<String, dynamic>;
  final version = app['version'] as String?;
  final url = app['trackViewUrl'] as String?;
  return version == null || url == null ? null : (version: version, url: url);
}

/// [store] mới hơn [current] (so từng số: 1.10.0 > 1.9.3; thiếu số coi là 0).
bool isNewer(String store, String current) {
  List<int> parts(String v) => [
    for (final p in v.split('+').first.split('.')) int.tryParse(p) ?? 0,
  ];
  final a = parts(store), b = parts(current);
  for (var i = 0; i < (a.length > b.length ? a.length : b.length); i++) {
    final x = i < a.length ? a[i] : 0, y = i < b.length ? b[i] : 0;
    if (x != y) return x > y;
  }
  return false;
}

@Riverpod(keepAlive: true)
AppVersionService appVersionService(Ref ref) =>
    AppVersionService(ref.read(sharedPrefsProvider));
