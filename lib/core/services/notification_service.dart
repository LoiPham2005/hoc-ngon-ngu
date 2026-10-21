import 'dart:async';
import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:lingua/core/utils/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

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
