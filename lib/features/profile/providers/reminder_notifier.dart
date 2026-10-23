import 'dart:convert';

import 'package:lingua/core/di/global_providers.dart';
import 'package:lingua/core/services/notification_service.dart';
import 'package:lingua/core/utils/logger.dart';
import 'package:lingua/design/l10n/locale_notifier.dart';
import 'package:lingua/gen/l10n/app_localizations.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'reminder_notifier.g.dart';

/// Nhắc học hằng ngày: bật/tắt + giờ nhắc (giờ máy).
class Reminder {
  const Reminder({this.enabled = false, this.hour = 20, this.minute = 0});

  factory Reminder.fromJson(Map<String, dynamic> json) => Reminder(
    enabled: json['enabled'] as bool? ?? false,
    hour: json['hour'] as int? ?? 20,
    minute: json['minute'] as int? ?? 0,
  );

  final bool enabled;
  final int hour;
  final int minute;

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'hour': hour,
    'minute': minute,
  };
}

@Riverpod(keepAlive: true)
class ReminderNotifier extends _$ReminderNotifier {
  static const _key = 'reminder_v1';
  static const _notificationId = 1001;

  @override
  Reminder build() {
    final raw = ref.read(sharedPrefsProvider).getString(_key);
    if (raw == null) return const Reminder();
    try {
      return Reminder.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on Object {
      return const Reminder();
    }
  }

  /// Bật cần quyền thông báo — bị từ chối → `false`, vẫn tắt.
  Future<bool> setEnabled({required bool enabled}) async {
    if (enabled &&
        !await ref.read(notificationServiceProvider).requestPermission()) {
      return false;
    }
    await _save(
      Reminder(enabled: enabled, hour: state.hour, minute: state.minute),
    );
    return true;
  }

  Future<void> setTime(int hour, int minute) =>
      _save(Reminder(enabled: state.enabled, hour: hour, minute: minute));

  /// Đặt lại lịch theo cài đặt + ngôn ngữ app hiện tại (lúc mở app, khi đổi ngôn ngữ).
  /// Lỗi đặt lịch (máy chặn thông báo…) chỉ ghi log, không làm hỏng thao tác đang làm.
  Future<void> sync() async {
    final notifications = ref.read(notificationServiceProvider);
    try {
      if (!state.enabled) return await notifications.cancel(_notificationId);
      final l10n = lookupAppLocalizations(ref.read(localeProvider));
      await notifications.scheduleDaily(
        id: _notificationId,
        title: l10n.reminder_notificationTitle,
        body: l10n.reminder_notificationBody,
        hour: state.hour,
        minute: state.minute,
      );
    } on Object catch (e, s) {
      talker.error('[REMINDER] sync failed', e, s);
    }
  }

  Future<void> _save(Reminder next) async {
    state = next;
    await ref
        .read(sharedPrefsProvider)
        .setString(_key, jsonEncode(next.toJson()));
    await sync();
  }
}
