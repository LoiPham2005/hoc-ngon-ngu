import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingua/core/di/global_providers.dart';
import 'package:lingua/core/services/biometric_notifier.dart';
import 'package:local_auth_platform_interface/local_auth_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Giả lập cảm biến: [result] = kết quả quét; `null` = user bấm huỷ.
class _FakeAuth extends LocalAuthPlatform {
  _FakeAuth({this.enrolled = true});

  final bool enrolled;
  bool? result = true;
  int calls = 0;

  @override
  Future<bool> authenticate({
    required String localizedReason,
    required Iterable<AuthMessages> authMessages,
    AuthenticationOptions options = const AuthenticationOptions(),
  }) async {
    calls++;
    if (result == null) {
      throw const LocalAuthException(code: LocalAuthExceptionCode.userCanceled);
    }
    return result!;
  }

  @override
  Future<bool> isDeviceSupported() async => true;

  @override
  Future<bool> deviceSupportsBiometrics() async => true;

  @override
  Future<List<BiometricType>> getEnrolledBiometrics() async =>
      enrolled ? [BiometricType.fingerprint] : [];
}

void main() {
  late _FakeAuth auth;
  late ProviderContainer container;

  Future<void> setUpWith(_FakeAuth fake) async {
    auth = fake;
    LocalAuthPlatform.instance = fake;
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    container = ProviderContainer(
      overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
  }

  BiometricNotifier notifier() => container.read(biometricProvider.notifier);

  test('enable only after a successful scan', () async {
    await setUpWith(_FakeAuth());
    auth.result = false;
    expect(await notifier().setEnabled(true, reason: 'x'), isFalse);
    expect(container.read(biometricProvider), isFalse);

    auth.result = true;
    expect(await notifier().setEnabled(true, reason: 'x'), isTrue);
    expect(container.read(biometricProvider), isTrue);
  });

  test('disable does not require a scan', () async {
    await setUpWith(_FakeAuth());
    await notifier().setEnabled(true, reason: 'x');
    auth.calls = 0;

    expect(await notifier().setEnabled(false, reason: 'x'), isTrue);
    expect(container.read(biometricProvider), isFalse);
    expect(auth.calls, 0);
  });

  test('cancel → false, no throw', () async {
    await setUpWith(_FakeAuth()..result = null);
    expect(await notifier().authenticate('x'), isFalse);
  });

  test('shouldOffer: only once, only when enrolled', () async {
    await setUpWith(_FakeAuth());
    expect(await notifier().shouldOffer(), isTrue);
    expect(await notifier().shouldOffer(), isFalse);

    await setUpWith(_FakeAuth(enrolled: false));
    expect(await notifier().shouldOffer(), isFalse);
  });
}
