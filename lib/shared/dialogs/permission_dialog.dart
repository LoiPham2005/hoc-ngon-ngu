import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingua/core/services/permission_service.dart';
import 'package:lingua/core/utils/toast.dart';
import 'package:lingua/design/l10n/l10n_extensions.dart';
import 'package:lingua/shared/dialogs/app_confirmation_dialog.dart';

/// Xin [permission] kèm giải thích cho người dùng: có → `true`;
/// từ chối → toast; bị chặn hẳn → hộp thoại mời mở Cài đặt của máy.
Future<bool> ensurePermission(
  BuildContext context,
  WidgetRef ref,
  AppPermission permission,
) async {
  final service = ref.read(permissionServiceProvider);
  final l10n = context.l10n;
  final (title, reason) = permissionText(context, permission);
  switch (await service.request(permission)) {
    case PermissionResult.granted:
      return true;
    case PermissionResult.denied:
      toast.warning(reason, title: title);
      return false;
    case PermissionResult.blocked:
      if (!context.mounted) return false;
      final open = await AppConfirmationDialog.show(
        context,
        title: title,
        message: '$reason\n\n${l10n.permission_blocked}',
        confirmText: l10n.permission_openSettings,
      );
      if (open) await service.openSettings();
      return false;
  }
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
