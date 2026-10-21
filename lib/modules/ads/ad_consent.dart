import 'dart:async';
import 'dart:io';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:lingua/core/utils/logger.dart';

/// Consent BẮT BUỘC trước khi load ads: ATT (iOS 14.5+, không xin → CPM iOS tụt mạnh)
/// rồi UMP (GDPR/CCPA — thiếu là AdMob flag account). Gọi trước `MobileAds.initialize()`.
class AdConsent {
  ConsentStatus? _status;
  bool _requested = false;

  /// `true` khi được phép request ads (chưa cần consent hoặc user đã đồng ý).
  bool get canRequestAds =>
      _status == null ||
      _status == ConsentStatus.notRequired ||
      _status == ConsentStatus.obtained;

  Future<void> request() async {
    if (_requested) return;
    _requested = true;
    await _requestAtt();
    try {
      await _callback(
        (done) => ConsentInformation.instance.requestConsentInfoUpdate(
          ConsentRequestParameters(),
          () => done(null),
          (e) => done('${e.errorCode} ${e.message}'),
        ),
      );
      await _callback(
        (done) => ConsentForm.loadAndShowConsentFormIfRequired(
          (e) => done(e == null ? null : '${e.errorCode} ${e.message}'),
        ),
      );
    } catch (e, s) {
      talker.error('[ADS] UMP failed', e, s);
    }
    _status = await ConsentInformation.instance.getConsentStatus();
  }

  /// Màn chọn lại quyền riêng tư (đặt ở Settings khi [isPrivacyOptionsRequired]).
  Future<void> showPrivacyOptions() async {
    await _callback(
      (done) => ConsentForm.showPrivacyOptionsForm(
        (e) => done(e == null ? null : '${e.errorCode} ${e.message}'),
      ),
    );
    _status = await ConsentInformation.instance.getConsentStatus();
  }

  Future<bool> get isPrivacyOptionsRequired async =>
      await ConsentInformation.instance.getPrivacyOptionsRequirementStatus() ==
      PrivacyOptionsRequirementStatus.required;

  Future<void> _requestAtt() async {
    if (!Platform.isIOS) return;
    try {
      if (await AppTrackingTransparency.trackingAuthorizationStatus ==
          TrackingStatus.notDetermined) {
        // Đợi chút để dialog hệ thống không đè splash (Apple khuyến nghị).
        await Future<void>.delayed(const Duration(milliseconds: 200));
        await AppTrackingTransparency.requestTrackingAuthorization();
      }
    } catch (e, s) {
      talker.error('[ADS] ATT failed', e, s);
    }
  }

  /// Bọc API callback của UMP thành Future. `done(lỗi)` — null = thành công.
  Future<void> _callback(void Function(void Function(String? error) done) run) {
    final c = Completer<void>();
    run((error) {
      if (error != null) talker.warning('[ADS] UMP: $error');
      if (!c.isCompleted) c.complete();
    });
    return c.future;
  }
}
