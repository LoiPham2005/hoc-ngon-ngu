import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';

import 'package:lingua/core/utils/logger.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'permission_service.g.dart';

/// Mọi quyền thường gặp của điện thoại. Dùng:
/// ```dart
/// // Có giao diện: hỏi quyền, bị từ chối → toast, bị chặn hẳn → mời mở Cài đặt.
/// if (!await ensurePermission(context, ref, AppPermission.camera)) return;
/// // Không giao diện (service, notifier):
/// final result = await ref.read(permissionServiceProvider).request(AppPermission.camera);
/// ```
///
/// ⚠️ Dùng quyền nào phải khai báo native cho quyền đó — CHỈ khai báo quyền app thật sự dùng
/// (Google Play / App Store từ chối app khai quyền không dùng tới):
///
/// | Quyền | AndroidManifest `<uses-permission>` | Info.plist (iOS) | Podfile macro (`=1`) |
/// |---|---|---|---|
/// | camera | CAMERA | NSCameraUsageDescription | PERMISSION_CAMERA |
/// | photos | READ_MEDIA_IMAGES (+ READ_EXTERNAL_STORAGE maxSdk 32) | NSPhotoLibraryUsageDescription | PERMISSION_PHOTOS |
/// | microphone | RECORD_AUDIO | NSMicrophoneUsageDescription | PERMISSION_MICROPHONE |
/// | speechRecognition | RECORD_AUDIO | NSMicrophoneUsageDescription + NSSpeechRecognitionUsageDescription | PERMISSION_MICROPHONE, PERMISSION_SPEECH_RECOGNIZER |
/// | location | ACCESS_FINE_LOCATION, ACCESS_COARSE_LOCATION | NSLocationWhenInUseUsageDescription | PERMISSION_LOCATION_WHENINUSE |
/// | locationAlways | + ACCESS_BACKGROUND_LOCATION | + NSLocationAlwaysAndWhenInUseUsageDescription | PERMISSION_LOCATION |
/// | notification | POST_NOTIFICATIONS | — | PERMISSION_NOTIFICATIONS |
/// | contacts | READ_CONTACTS | NSContactsUsageDescription | PERMISSION_CONTACTS |
/// | calendar | READ_CALENDAR, WRITE_CALENDAR | NSCalendarsFullAccessUsageDescription | PERMISSION_EVENTS_FULL_ACCESS |
/// | bluetooth | BLUETOOTH_SCAN, BLUETOOTH_CONNECT | NSBluetoothAlwaysUsageDescription | PERMISSION_BLUETOOTH |
/// | activityRecognition | ACTIVITY_RECOGNITION | NSMotionUsageDescription | PERMISSION_SENSORS |
///
/// Podfile: thêm macro vào `GCC_PREPROCESSOR_DEFINITIONS` trong `post_install` (xem ios/Podfile).
/// Theo dõi quảng cáo (ATT) do module ads lo, không qua đây.
enum AppPermission {
  camera([Permission.camera]),

  /// Ảnh trong thư viện. Android < 13 không có quyền ảnh riêng → dùng quyền bộ nhớ (chỉ cần 1 trong 2).
  photos(
    [Permission.photos],
    android: [Permission.photos, Permission.storage],
    anyOf: true,
  ),
  microphone([Permission.microphone]),

  /// Micro + nhận giọng nói (iOS cần thêm quyền Speech; Android chỉ cần micro).
  speechRecognition(
    [Permission.microphone, Permission.speech],
    android: [Permission.microphone],
  ),
  location([Permission.locationWhenInUse]),

  /// Vị trí cả khi chạy nền: phải có "khi đang dùng" trước rồi mới xin "luôn luôn".
  locationAlways([Permission.locationWhenInUse, Permission.locationAlways]),
  notification([Permission.notification]),
  contacts([Permission.contacts]),
  calendar([Permission.calendarFullAccess]),

  /// Android 12+ tách quyền quét / kết nối.
  bluetooth(
    [Permission.bluetooth],
    android: [Permission.bluetoothScan, Permission.bluetoothConnect],
  ),

  /// Đếm bước / nhận diện hoạt động (iOS: cảm biến chuyển động).
  activityRecognition(
    [Permission.sensors],
    android: [Permission.activityRecognition],
  );

  const AppPermission(
    this._ios, {
    List<Permission>? android,
    this.anyOf = false,
  }) : _android = android;

  final List<Permission> _ios;
  final List<Permission>? _android;

  /// `true` = chỉ cần 1 quyền trong danh sách (thay thế nhau theo đời máy); `false` = cần đủ.
  final bool anyOf;

  /// Quyền hệ thống thật sự cần xin trên máy đang chạy (theo thứ tự xin).
  List<Permission> get permissions =>
      Platform.isAndroid ? (_android ?? _ios) : _ios;
}

/// Kết quả xin quyền.
enum PermissionResult {
  granted,

  /// Người dùng vừa từ chối — lần sau xin lại được.
  denied,

  /// Bị chặn hẳn (từ chối nhiều lần / tắt trong Cài đặt / bị giới hạn) → chỉ bật được trong Cài đặt.
  blocked,
}

/// Xin quyền hệ thống (permission_handler): có rồi → không hỏi lại; chưa có → hộp thoại của máy;
/// bị chặn → [PermissionResult.blocked] để giao diện mời mở Cài đặt ([openSettings]).
class PermissionService {
  /// Trạng thái hiện tại, KHÔNG hiện hộp thoại.
  Future<PermissionResult> status(AppPermission permission) async => _merge(
    permission,
    [for (final p in permission.permissions) await p.status],
  );

  /// Xin quyền (chỉ hỏi những quyền con chưa có, theo đúng thứ tự).
  Future<PermissionResult> request(AppPermission permission) async {
    try {
      final statuses = <PermissionStatus>[];
      for (final p in permission.permissions) {
        final current = await p.status;
        statuses.add(_isGranted(current) ? current : await p.request());
        // Cần đủ mà quyền trước đã bị từ chối → không hỏi tiếp (vd vị trí "luôn luôn").
        if (!permission.anyOf && !_isGranted(statuses.last)) break;
      }
      return _merge(permission, statuses);
    } on Object catch (e, s) {
      talker.error('[PERMISSION] request $permission failed', e, s);
      return PermissionResult.denied;
    }
  }

  /// Mở Cài đặt để người dùng tự bật [permission]. Thông báo trên Android → mở thẳng
  /// trang "Thông báo" của app (1 chạm là bật); còn lại → trang cài đặt của app.
  Future<bool> openSettings([AppPermission? permission]) async {
    if (Platform.isAndroid && permission == AppPermission.notification) {
      try {
        final info = await PackageInfo.fromPlatform();
        await AndroidIntent(
          action: 'android.settings.APP_NOTIFICATION_SETTINGS',
          arguments: {'android.provider.extra.APP_PACKAGE': info.packageName},
          flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
        ).launch();
        return true;
      } on Object catch (e, s) {
        talker.error('[PERMISSION] open notification settings failed', e, s);
      }
    }
    return openAppSettings();
  }

  static bool _isGranted(PermissionStatus s) =>
      s.isGranted || s.isLimited || s.isProvisional;

  PermissionResult _merge(
    AppPermission permission,
    List<PermissionStatus> statuses,
  ) {
    final granted = permission.anyOf
        ? statuses.any(_isGranted)
        : statuses.length == permission.permissions.length &&
              statuses.every(_isGranted);
    if (granted) return PermissionResult.granted;
    bool blocked(PermissionStatus s) => s.isPermanentlyDenied || s.isRestricted;
    final isBlocked = permission.anyOf
        ? statuses.every(blocked)
        : statuses.any(blocked);
    return isBlocked ? PermissionResult.blocked : PermissionResult.denied;
  }
}

@Riverpod(keepAlive: true)
PermissionService permissionService(Ref ref) => PermissionService();
