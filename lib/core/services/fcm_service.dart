import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:lingua/core/services/notification_service.dart';
import 'package:lingua/core/utils/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'fcm_service.g.dart';

class FcmService {
  FcmService(this._local);

  static const String _tag = 'FCM';

  final NotificationService _local;

  bool _initialized = false;

  /// Callback khi user tap 1 push notification (foreground/background/terminated).
  /// Set 1 lần ở AppInitializer hoặc App widget — không hardcode route ở đây.
  void Function(Map<String, dynamic> data)? onMessageTap;

  /// Init permission + listeners. Idempotent (gọi nhiều lần OK).
  Future<void> init() async {
    if (_initialized) return;
    try {
      final messaging = FirebaseMessaging.instance;

      // Request permission — iOS bắt buộc, Android 13+ cũng cần
      await messaging.requestPermission(alert: true, badge: true, sound: true);

      // Foreground: FCM không tự show, phải dùng LocalNotificationService
      FirebaseMessaging.onMessage.listen(_onForegroundMessage);

      // Background: app đang mở nhưng không focus → user tap notification
      FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpened);

      // Terminated: app bị kill → user tap notification → mở app từ tray
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        _onMessageOpened(initialMessage);
      }

      _initialized = true;
    } catch (e, st) {
      talker.error('[$_tag] FCM init failed', e, st);
      // Best-effort — không break app boot
    }
  }

  /// Lấy FCM token hiện tại — gọi sau khi login để register với backend.
  /// Null nếu permission denied hoặc Firebase chưa init.
  Future<String?> getToken() async {
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (e) {
      talker.warning('[$_tag] getToken failed: $e');
      return null;
    }
  }

  /// Xoá token — gọi khi logout. Backend cũng cần DELETE /devices/:id riêng.
  Future<void> deleteToken() async {
    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (e) {
      talker.warning('[$_tag] deleteToken failed: $e');
    }
  }

  /// Platform string khớp Prisma enum: IOS | ANDROID | WEB.
  String currentPlatform() {
    if (Platform.isIOS) return 'IOS';
    if (Platform.isAndroid) return 'ANDROID';
    return 'WEB';
  }

  // ─── Internal handlers ──────────────────────────────────────

  void _onForegroundMessage(RemoteMessage message) {
    final notif = message.notification;
    if (notif == null) return;
    // Show qua local notification (FCM không auto-show foreground).
    // payload = JSON string để NotificationService.onTap parse lại được data.
    _local.showNotification(
      id: message.hashCode & 0x7FFFFFFF, // ép dương — hashCode có thể âm
      title: notif.title ?? 'Thông báo mới',
      body: notif.body ?? '',
      payload: jsonEncode(message.data),
    );
  }

  void _onMessageOpened(RemoteMessage message) {
    talker.info('[$_tag] Notification tapped: ${message.data}');
    onMessageTap?.call(message.data);
  }
}

@Riverpod(keepAlive: true)
FcmService fcmService(Ref ref) =>
    FcmService(ref.read(notificationServiceProvider));
