import 'package:lingua/core/di/global_providers.dart';
import 'package:lingua/core/utils/logger.dart';
import 'package:local_auth/local_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'biometric_notifier.g.dart';

/// Mở app bằng vân tay / Face ID. Chỉ "mở khoá" token đã lưu trong secure storage —
/// KHÔNG lưu mật khẩu. state = người dùng đã bật hay chưa.
///
/// - Splash: đã đăng nhập + bật → quét; sai/huỷ → màn Login (có nút quét lại hoặc nhập mật khẩu).
/// - Login: đăng nhập mật khẩu xong → `shouldOffer()` → hỏi bật (mỗi máy hỏi 1 lần).
/// - Settings: công tắc `setEnabled`.
@Riverpod(keepAlive: true)
class BiometricNotifier extends _$BiometricNotifier {
  static const _enabledKey = 'biometric_enabled';
  static const _offeredKey = 'biometric_offered';
  static final _auth = LocalAuthentication();

  @override
  bool build() => ref.read(sharedPrefsProvider).getBool(_enabledKey) ?? false;

  /// Máy có cảm biến và đã cài vân tay / khuôn mặt.
  Future<bool> isAvailable() async {
    try {
      return await _auth.isDeviceSupported() &&
          (await _auth.getAvailableBiometrics()).isNotEmpty;
    } on Object {
      return false;
    }
  }

  /// Hiện hộp quét. `true` = đúng chủ máy; huỷ / sai / lỗi → `false`.
  Future<bool> authenticate(String reason) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } on LocalAuthException catch (e) {
      // Huỷ, khoá tạm do sai nhiều lần, chưa cài vân tay… — chuyện bình thường, không phải lỗi app.
      talker.info('[Biometric] ${e.code.name}');
      return false;
    } on Object catch (e, s) {
      talker.error('[Biometric] authenticate failed', e, s);
      return false;
    }
  }

  /// Bật phải quét đúng 1 lần (xác nhận chính chủ). Trả `true` nếu đổi được.
  Future<bool> setEnabled(bool value, {required String reason}) async {
    if (value && !await authenticate(reason)) return false;
    await ref.read(sharedPrefsProvider).setBool(_enabledKey, value);
    state = value;
    return true;
  }

  /// Nên hỏi bật sau khi đăng nhập không: máy hỗ trợ, chưa bật, chưa từng hỏi.
  /// Gọi là tính đã hỏi — user từ chối thì không hỏi lại (vẫn bật được ở Cài đặt).
  Future<bool> shouldOffer() async {
    final prefs = ref.read(sharedPrefsProvider);
    if (state ||
        (prefs.getBool(_offeredKey) ?? false) ||
        !await isAvailable()) {
      return false;
    }
    await prefs.setBool(_offeredKey, true);
    return true;
  }
}
