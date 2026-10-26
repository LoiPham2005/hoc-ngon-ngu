import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingua/core/di/global_providers.dart';
import 'package:lingua/design/l10n/l10n_extensions.dart';
import 'package:lingua/modules/app_config/app_config.dart';
import 'package:url_launcher/url_launcher.dart';

const _seenKey = 'notice_seen_v1';

/// Thông báo lúc mở app (`notice_*` trong Remote Config `app_config`): mỗi nội dung hiện 1 lần,
/// sửa chữ trên Firebase → hiện lại cho mọi người. Có `notice_url` → thêm nút "Xem chi tiết".
Future<void> showAppNotice(BuildContext context, WidgetRef ref) async {
  final config = ref.read(appConfigProvider);
  final prefs = ref.read(sharedPrefsProvider);
  if (!config.hasNotice || prefs.getString(_seenKey) == config.noticeId) return;
  await prefs.setString(_seenKey, config.noticeId);
  if (!context.mounted) return;
  final l10n = context.l10n;
  final open = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      actionsOverflowButtonSpacing: 4,
      icon: const Icon(Icons.campaign_rounded, size: 40),
      title: Text(config.noticeTitle, textAlign: TextAlign.center),
      content: config.noticeBody.isEmpty
          ? null
          : Text(config.noticeBody, textAlign: TextAlign.center),
      actions: [
        if (config.noticeUrl.isNotEmpty)
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.notice_open),
            ),
          ),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.common_close),
          ),
        ),
      ],
    ),
  );
  if (open ?? false) {
    await launchUrl(
      Uri.parse(config.noticeUrl),
      mode: LaunchMode.externalApplication,
    );
  }
}
