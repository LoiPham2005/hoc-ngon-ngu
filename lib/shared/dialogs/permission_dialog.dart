import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingua/core/services/permission_service.dart';
import 'package:lingua/design/l10n/l10n_extensions.dart';
import 'package:lingua/shared/dialogs/app_confirmation_dialog.dart';

/// Xin [permission] kèm giải thích: có → `true`; chưa có → hộp thoại lý do + nút "Mở cài đặt"
/// (thông báo trên Android mở thẳng trang Thông báo của app).
Future<bool> ensurePermission(
  BuildContext context,
  WidgetRef ref,
  AppPermission permission,
) async {
  final service = ref.read(permissionServiceProvider);
  final l10n = context.l10n;
  final (title, reason) = permissionText(context, permission);
  final result = await service.request(permission);
  if (result == PermissionResult.granted) return true;
  if (!context.mounted) return false;
  // Từ chối / bị chặn: hệ thống thường không hỏi lại nữa → mời bật trong Cài đặt.
  final open = await AppConfirmationDialog.show(
    context,
    title: title,
    message: '$reason\n\n${l10n.permission_blocked}',
    confirmText: l10n.permission_openSettings,
    cancelText: l10n.permission_later,
  );
  if (open) await service.openSettings(permission);
  return false;
}

/// Tiêu đề + lý do xin từng quyền (hiện cho người dùng) — sửa câu chữ trong file ARB.
(String, String) permissionText(BuildContext context, AppPermission p) {
  final l10n = context.l10n;
  return switch (p) {
    AppPermission.camera => (
      l10n.permission_camera_title,
      l10n.permission_camera_reason,
    ),
    AppPermission.photos => (
      l10n.permission_photos_title,
      l10n.permission_photos_reason,
    ),
    AppPermission.microphone || AppPermission.speechRecognition => (
      l10n.permission_microphone_title,
      l10n.permission_microphone_reason,
    ),
    AppPermission.location || AppPermission.locationAlways => (
      l10n.permission_location_title,
      l10n.permission_location_reason,
    ),
    AppPermission.notification => (
      l10n.permission_notification_title,
      l10n.permission_notification_reason,
    ),
    AppPermission.contacts => (
      l10n.permission_contacts_title,
      l10n.permission_contacts_reason,
    ),
    AppPermission.calendar => (
      l10n.permission_calendar_title,
      l10n.permission_calendar_reason,
    ),
    AppPermission.bluetooth => (
      l10n.permission_bluetooth_title,
      l10n.permission_bluetooth_reason,
    ),
    AppPermission.activityRecognition => (
      l10n.permission_activity_title,
      l10n.permission_activity_reason,
    ),
  };
}
