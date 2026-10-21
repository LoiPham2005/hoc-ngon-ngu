import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lingua/config/app_info.dart';
import 'package:lingua/core/network/dio_provider.dart';
import 'package:lingua/core/services/app_version_api.dart';
import 'package:lingua/core/utils/logger.dart';
import 'package:lingua/design/l10n/l10n_extensions.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:url_launcher/url_launcher.dart';

part 'app_version_service.g.dart';

/// Check version qua backend `GET /app-version/check` rồi hiện dialog update.
/// Mọi lỗi → bỏ qua (fail-open, không chặn user).
class AppVersionService {
  AppVersionService(this._api);

  final AppVersionApi _api;

  /// Trả `false` khi bắt buộc update (splash dừng lại), còn lại `true`.
  Future<bool> checkAndPrompt(BuildContext context) async {
    final AppVersionCheckResponse res;
    final PackageInfo pkg;
    try {
      pkg = await PackageInfo.fromPlatform();
      res = await _api.checkVersion(
        Platform.isAndroid ? 'android' : 'ios',
        pkg.version,
        pkg.buildNumber,
      );
    } catch (e, s) {
      talker.error('[APP-VERSION] check failed', e, s);
      return true;
    }
    final force = res.status == 'force';
    if (!context.mounted || (!force && res.status != 'optional')) return true;

    // Ưu tiên link backend trả về, không có thì dùng link store cố định.
    final storeUrl = res.storeUrl?.isNotEmpty == true
        ? res.storeUrl!
        : Platform.isAndroid
        ? AppInfo.playStoreUrl
        : AppInfo.appStoreUrl;
    final l10n = context.l10n;
    await showDialog<void>(
      context: context,
      barrierDismissible: !force,
      builder: (ctx) => PopScope(
        canPop:
            !force, // force: không đóng được, không `exit()` (tránh bị store reject)
        child: AlertDialog(
          title: Text(
            force ? l10n.update_forceTitle : l10n.update_optionalTitle,
          ),
          content: Text(
            '${res.message?.isNotEmpty == true
                ? res.message
                : force
                ? l10n.update_forceMessage
                : l10n.update_optionalMessage}'
            '\n\n${pkg.version} → ${res.latestVersion}',
          ),
          actions: [
            if (!force)
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l10n.update_later),
              ),
            FilledButton(
              onPressed: storeUrl.isEmpty
                  ? null
                  : () => launchUrl(
                      Uri.parse(storeUrl),
                      mode: LaunchMode.externalApplication,
                    ),
              child: Text(l10n.update_now),
            ),
          ],
        ),
      ),
    );
    return !force;
  }
}

@Riverpod(keepAlive: true)
AppVersionService appVersionService(Ref ref) =>
    AppVersionService(AppVersionApi(ref.dio));
