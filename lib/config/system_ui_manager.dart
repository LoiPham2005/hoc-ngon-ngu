import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:lingua/design/theme/app_palette.dart';

/// Status bar luôn hiện, nav bar Android luôn ẩn (tự ẩn lại sau 3s nếu user vuốt hiện).
/// iOS dùng edgeToEdge. `applyUiMode` được gọi lại khi app resume (xem `app.dart`).
abstract class SystemUIManager {
  static bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static Future<void> setup() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: AppPalette.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: AppPalette.lightSurface,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
    if (_isAndroid) {
      await SystemChrome.setSystemUIChangeCallback((overlaysVisible) async {
        if (!overlaysVisible) return;
        await Future<void>.delayed(const Duration(seconds: 3));
        await applyUiMode();
      });
    }
    await applyUiMode();
  }

  static Future<void> applyUiMode() => _isAndroid
      ? SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.manual,
          overlays: const [SystemUiOverlay.top],
        )
      : SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
}
