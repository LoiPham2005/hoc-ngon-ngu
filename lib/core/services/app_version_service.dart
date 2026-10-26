import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:lingua/config/app_info.dart';
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
  const StoreUpdate({required this.version, this.currentVersion});

  /// Mã bản mới để nhớ "Để sau": tên phiên bản (iOS) hoặc versionCode (Android).
  final String version;
  final String? currentVersion;
}

/// Phiên bản app đang chạy (đọc 1 lần).
@Riverpod(keepAlive: true)
Future<PackageInfo> packageInfo(Ref ref) => PackageInfo.fromPlatform();

/// Cập nhật app qua store (không cần server riêng):
/// - [checkAndPrompt] — bản mới KHÔNG bắt buộc: lúc mở app hỏi "Cập nhật ngay / Để sau"
///   (bấm "Để sau" → 3 ngày sau mới hỏi lại bản đó).
///   Android: Google Play In-App Updates; iOS: API tra cứu công khai `itunes.apple.com/lookup`.
/// - [openStore] — mở cập nhật (Android: màn cập nhật của Google Play ngay trong app).
///
/// BẮT BUỘC cập nhật không làm ở đây: đặt `min_version` trong Remote Config `app_config`
/// → `AppGate` khoá app (áp dụng cho cả Android lẫn iOS, đổi được bất cứ lúc nào).
/// Mọi lỗi (không có mạng, app không cài từ store…) → bỏ qua, không chặn người dùng.
class AppVersionService {
  AppVersionService(this._prefs, {Dio? dio}) : _dio = dio ?? Dio();

  final SharedPreferences _prefs;
  final Dio _dio;

  static const _snoozeKey = 'update_snooze_v1';

  /// Giả lập có bản mới để xem hộp thoại (chỉ khi build kèm cờ, bản phát hành không có):
  /// `flutter run --flavor dev --dart-define=MOCK_UPDATE=true`.
  static const _mock = bool.fromEnvironment('MOCK_UPDATE');
  static const remindAfter = Duration(days: 3);

  Future<void> checkAndPrompt(BuildContext context) async {
    final StoreUpdate? update;
    try {
      update = _mock
          ? StoreUpdate(
              version: '9.9.9',
              currentVersion: (await PackageInfo.fromPlatform()).version,
            )
          : Platform.isAndroid
          ? await _checkPlay()
          : await _checkAppStore();
    } on Object catch (e, s) {
      talker.warning('[APP-VERSION] store check skipped: $e', s);
      return;
    }
    if (update == null || !context.mounted) return;
    if (!_mock && isSnoozed(update.version)) return;
    if (await _ask(context, update)) {
      await openStore();
    } else {
      await snooze(update.version);
    }
  }

  Future<StoreUpdate?> _checkPlay() async {
    final info = await InAppUpdate.checkForUpdate();
    if (info.updateAvailability != UpdateAvailability.updateAvailable) {
      return null;
    }
    return StoreUpdate(version: '${info.availableVersionCode ?? ''}');
  }

  Future<StoreUpdate?> _checkAppStore() async {
    final pkg = await PackageInfo.fromPlatform();
    final store = await _lookupAppStore(pkg.packageName);
    if (store == null || !isNewer(store.version, pkg.version)) return null;
    return StoreUpdate(version: store.version, currentVersion: pkg.version);
  }

  Future<({String version, String url})?> _lookupAppStore(
    String bundleId,
  ) async {
    final res = await _dio.get<Map<String, dynamic>>(
      'https://itunes.apple.com/lookup',
      queryParameters: {
        'bundleId': bundleId,
        // Thêm tham số thời gian để không nhận kết quả cũ trong bộ nhớ đệm của Apple.
        't': DateTime.now().millisecondsSinceEpoch,
      },
    );
    return parseAppStoreLookup(res.data);
  }

  Future<bool> _ask(BuildContext context, StoreUpdate update) async {
    final l10n = context.l10n;
    final versions = update.currentVersion == null
        ? ''
        : '\n\n${update.currentVersion} → ${update.version}';
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        actionsOverflowButtonSpacing: 4,
        icon: const Icon(Icons.system_update_rounded, size: 40),
        title: Text(l10n.update_optionalTitle, textAlign: TextAlign.center),
        content: Text(
          '${l10n.update_optionalMessage}$versions',
          textAlign: TextAlign.center,
        ),
        actions: [
          // Nút chính rộng hết khung, "Để sau" là chữ nhỏ bên dưới (chữ dài không gãy dòng).
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.update_now),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.update_later),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Mở cập nhật: Android → màn cập nhật của Google Play ngay trong app (không được thì mở
  /// trang app trên Google Play); iOS → trang app trên App Store.
  Future<void> openStore() async {
    try {
      if (Platform.isAndroid) {
        final info = await InAppUpdate.checkForUpdate();
        if (info.updateAvailability == UpdateAvailability.updateAvailable &&
            info.immediateUpdateAllowed) {
          await InAppUpdate.performImmediateUpdate();
          return;
        }
        await _open(AppInfo.playStoreUrl);
        return;
      }
      final pkg = await PackageInfo.fromPlatform();
      final url = AppInfo.appStoreUrl.isNotEmpty
          ? AppInfo.appStoreUrl
          : (await _lookupAppStore(pkg.packageName))?.url;
      if (url != null) await _open(url);
    } on Object catch (e, s) {
      talker.error('[APP-VERSION] open store failed', e, s);
      await _open(
        Platform.isAndroid ? AppInfo.playStoreUrl : AppInfo.appStoreUrl,
      );
    }
  }

  Future<void> _open(String url) async {
    if (url.isEmpty) return;
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

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
