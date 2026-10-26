import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:lingua/config/flavor_config.dart';
import 'package:lingua/core/utils/logger.dart';
import 'package:lingua/modules/iap/iap_config.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'iap_service.g.dart';

enum PurchaseStatus { success, cancelled, failed }

class PurchaseResult {
  const PurchaseResult(this.status, [this.message]);
  final PurchaseStatus status;

  /// Thông báo cho user khi `failed`.
  final String? message;

  bool get isSuccess => status == PurchaseStatus.success;
}

/// Mua hàng qua RevenueCat. Chưa điền API key (vd flavor dev) → chế độ giả lập:
/// không gọi store, `debugSetPremium` để test UI premium.
/// Bật/tắt bán hàng, mở premium cho mọi người từ xa: xem [IapConfig].
///
/// ```dart
/// final iap = ref.read(iapServiceProvider);
/// final packages = await iap.packages();
/// final result = await iap.purchase(packages.first);
/// final isPremium = ref.watch(isPremiumProvider);
/// ```
class IapService {
  IapService({IapConfig Function()? config})
    : _config = config ?? (() => const IapConfig());

  // Lấy tại https://app.revenuecat.com → Project → API keys.
  static const _googleKey = '';
  static const _appleKey = '';
  static const entitlement = 'premium';

  /// Trạng thái premium (entitlement [entitlement] còn hiệu lực).
  final premium = ValueNotifier<bool>(false);

  final IapConfig Function() _config;

  bool _ready = false;
  Future<void>? _init;

  String get _apiKey => Platform.isIOS ? _appleKey : _googleKey;

  /// Chưa có API key → không gọi RevenueCat.
  bool get isMock => _apiKey.isEmpty;

  /// Idempotent. Lỗi → lần gọi sau thử lại.
  Future<void> initialize({String? userId}) =>
      _init ??= _doInit(userId).catchError((Object e, StackTrace s) {
        _init = null;
        talker.error('[IAP] init failed', e, s);
      });

  Future<void> _doInit(String? userId) async {
    if (isMock) {
      talker.warning('[IAP] chưa có RevenueCat API key → chế độ giả lập');
      return;
    }
    if (FlavorConfig.isDev) await Purchases.setLogLevel(LogLevel.debug);
    await Purchases.configure(
      PurchasesConfiguration(_apiKey)..appUserID = userId,
    );
    Purchases.addCustomerInfoUpdateListener(_update);
    _update(await Purchases.getCustomerInfo());
    _ready = true;
  }

  /// Các gói đang bán (offering `current` trên RevenueCat); ngừng bán từ xa → rỗng.
  Future<List<Package>> packages() async {
    if (!_ready || !_config().purchaseEnabled) return const [];
    try {
      return (await Purchases.getOfferings()).current?.availablePackages ??
          const [];
    } catch (e, s) {
      talker.error('[IAP] getOfferings failed', e, s);
      return const [];
    }
  }

  Future<PurchaseResult> purchase(Package package) async {
    if (!_config().purchaseEnabled) {
      return const PurchaseResult(PurchaseStatus.failed, 'Tạm ngừng bán gói');
    }
    return _guard(() async {
      talker.info('[IAP] purchase ${package.identifier}');
      final info = (await Purchases.purchase(
        PurchaseParams.package(package),
      )).customerInfo;
      return _update(info)
          ? const PurchaseResult(PurchaseStatus.success)
          : const PurchaseResult(
              PurchaseStatus.failed,
              'Chưa kích hoạt được gói',
            );
    });
  }

  Future<PurchaseResult> restore() => _guard(() async {
    final ok = _update(await Purchases.restorePurchases());
    talker.info('[IAP] restore → premium=$ok');
    return ok
        ? const PurchaseResult(PurchaseStatus.success)
        : const PurchaseResult(
            PurchaseStatus.failed,
            'Không tìm thấy gói đã mua',
          );
  });

  /// Gắn giao dịch với user của app (gọi sau khi đăng nhập).
  Future<void> logIn(String userId) async {
    if (_ready) _update((await Purchases.logIn(userId)).customerInfo);
  }

  Future<void> logOut() async {
    if (_ready) _update(await Purchases.logOut());
  }

  /// Chỉ chế độ giả lập: bật/tắt premium để test UI.
  void debugSetPremium(bool value) {
    if (isMock) premium.value = value;
  }

  Future<PurchaseResult> _guard(Future<PurchaseResult> Function() run) async {
    if (!_ready) {
      return const PurchaseResult(
        PurchaseStatus.failed,
        'Chưa sẵn sàng mua hàng',
      );
    }
    try {
      return await run();
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        return const PurchaseResult(PurchaseStatus.cancelled);
      }
      talker.warning('[IAP] $code ${e.message}');
      return PurchaseResult(PurchaseStatus.failed, switch (code) {
        PurchasesErrorCode.networkError => 'Lỗi mạng, vui lòng thử lại',
        PurchasesErrorCode.purchaseNotAllowedError =>
          'Thiết bị không cho phép mua hàng',
        PurchasesErrorCode.storeProblemError =>
          'Cửa hàng đang lỗi, thử lại sau',
        _ => 'Giao dịch thất bại',
      });
    } catch (e, s) {
      talker.error('[IAP] failed', e, s);
      return const PurchaseResult(PurchaseStatus.failed, 'Giao dịch thất bại');
    }
  }

  bool _update(CustomerInfo info) {
    final active = info.entitlements.all[entitlement]?.isActive ?? false;
    if (premium.value != active) talker.info('[IAP] premium → $active');
    premium.value = active;
    return active;
  }
}

@Riverpod(keepAlive: true)
IapService iapService(Ref ref) =>
    IapService(config: () => ref.read(iapConfigProvider));

/// `ref.watch(isPremiumProvider)` — tự cập nhật khi mua / hết hạn / restore / bật
/// `premium_for_all` từ xa.
@Riverpod(keepAlive: true)
class IsPremium extends _$IsPremium {
  @override
  bool build() {
    final forAll = ref.watch(iapConfigProvider).premiumForAll;
    final premium = ref.read(iapServiceProvider).premium;
    void listener() => state = forAll || premium.value;
    premium.addListener(listener);
    ref.onDispose(() => premium.removeListener(listener));
    return forAll || premium.value;
  }
}
