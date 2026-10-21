// GENERATED CODE - DO NOT MODIFY BY HAND
// Sinh bởi gen_api.dart — chạy lại `make gen-api` là bị ghi đè.
// ignore_for_file: type=lint

import 'dart:async';

import 'package:api_client/api_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'devices_providers.g.dart';

/// Thiết bị đang nhận push.
@riverpod
Future<DevicesListResponse> getDevices(Ref ref) =>
    ref.watch(restClientProvider).devices.getDevices();

/// Thao tác GHI nhóm `devices`. State = đang chạy / lỗi của lần gọi gần nhất; lỗi được NÉM LẠI cho
/// nơi gọi. Thành công thì làm mới mọi provider GET của nhóm.
///
/// `await ref.read(devicesActionsProvider.notifier).<method>(...)`
@Riverpod(keepAlive: true)
class DevicesActions extends _$DevicesActions {
  @override
  FutureOr<void> build() {}

  DevicesClient get _api => ref.read(restClientProvider).devices;

  Future<R> _run<R>(Future<R> Function() call) async {
    state = const AsyncLoading();
    try {
      final result = await call();
      if (ref.mounted) {
        state = const AsyncData(null);
        ref.invalidate(getDevicesProvider);
      }
      return result;
    } catch (e, st) {
      if (ref.mounted) state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Đăng ký thiết bị nhận push. `fcmToken` UNIQUE toàn bảng: cùng một máy có thể được hai người đăng nhập lần lượt và FCM cấp lại đúng token đó.
  Future<EmptyResponse> postDevices({required RegisterDeviceRequest body}) =>
      _run(() => _api.postDevices(body: body));

  /// Gỡ thiết bị khỏi danh sách nhận push — gọi lúc đăng xuất trên máy đó.
  Future<EmptyResponse> deleteDevices() => _run(() => _api.deleteDevices());
}
