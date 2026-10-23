import 'dart:async';
import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:lingua/core/utils/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

part 'notification_service.g.dart';

/// 🔔 Local Notification Service
class NotificationService {
  static const String _tag = 'NOTIFICATION';

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Channel constants
  static const String _channelId = 'app_notification_channel';
  static const String _channelName = 'General Notifications';
  static const String _channelDescription =
      'This channel is used for general app notifications.';

  /// ⚡ Callback khi user tap notification. Caller (AppInitializer hoặc 1 service
  /// routing layer) set, tránh hardcode route ở đây.
  void Function(String? payload)? onTap;

  /// 🚀 Initialize Notification Service
  Future<void> initialize() async {
    try {
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );

      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
      );

      await _notificationsPlugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      if (Platform.isAndroid) {
        await _createAndroidChannel();
      }
    } catch (e, stack) {
      talker.error(
        '[$_tag] Failed to initialize Notification Service',
        e,
        stack,
      );
    }
  }

  /// 🛠️ Create high importance channel for Android
  Future<void> _createAndroidChannel() async {
    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(androidChannel);
  }

  /// 📲 Show a local notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    Importance importance = Importance.max,
    Priority priority = Priority.high,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: importance,
      priority: priority,
      ticker: 'ticker',
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    await _notificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );
  }

  /// Xin quyền hiện thông báo (Android 13+, iOS). `false` = người dùng từ chối.
  Future<bool> requestPermission() async {
    if (Platform.isAndroid) {
      return await _notificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.requestNotificationsPermission() ??
          false;
    }
    return await _notificationsPlugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true, badge: true, sound: true) ??
        false;
  }

  /// ⏰ Thông báo lặp lại mỗi ngày lúc [hour]:[minute] (giờ máy). Gọi lại với cùng [id] để đổi giờ / nội dung.
  /// Không cần quyền báo thức chính xác: Android có thể lệch vài phút để tiết kiệm pin.
  Future<void> scheduleDaily({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    String? payload,
  }) async {
    await _initTimeZone();
    final now = tz.TZDateTime.now(tz.local);
    var at = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!at.isAfter(now)) at = at.add(const Duration(days: 1));
    await _notificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      payload: payload,
      scheduledDate: at,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  bool _timeZoneReady = false;

  Future<void> _initTimeZone() async {
    if (_timeZoneReady) return;
    tz_data.initializeTimeZones();
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
    } on Object catch (e, s) {
      talker.error('[$_tag] local timezone not found → UTC', e, s);
    }
    _timeZoneReady = true;
  }

  /// 🗑️ Cancel notification
  Future<void> cancel(int id) async => _notificationsPlugin.cancel(id: id);

  /// 🧹 Cancel all
  Future<void> cancelAll() async => _notificationsPlugin.cancelAll();

  /// 🖱️ Handle notification tap — forward payload cho caller xử lý routing.
  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    onTap?.call(payload);
  }
}

@Riverpod(keepAlive: true)
NotificationService notificationService(Ref ref) => NotificationService();
