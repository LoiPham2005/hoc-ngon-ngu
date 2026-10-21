// GENERATED CODE - DO NOT MODIFY BY HAND
// Sinh bởi gen_api.dart — chạy lại `make gen-api` là bị ghi đè.
// ignore_for_file: type=lint

import 'dart:async';

import 'package:api_client/api_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'notifications_providers.g.dart';

/// Hộp thư của CHÍNH mình — userId lấy từ token, không từ tham số.
@riverpod
Future<NotificationsListResponse> getNotifications(
  Ref ref, {
  int? page = 1,
  int? limit = 20,
  bool? unreadOnly = false,
}) => ref
    .watch(restClientProvider)
    .notifications
    .getNotifications(page: page, limit: limit, unreadOnly: unreadOnly);

/// Số thông báo chưa đọc — cho chấm đỏ trên chuông.
@riverpod
Future<EmptyResponse> getNotificationsUnreadCount(Ref ref) =>
    ref.watch(restClientProvider).notifications.getNotificationsUnreadCount();

/// Thao tác GHI nhóm `notifications`. State = đang chạy / lỗi của lần gọi gần nhất; lỗi được NÉM LẠI cho
/// nơi gọi. Thành công thì làm mới mọi provider GET của nhóm.
///
/// `await ref.read(notificationsActionsProvider.notifier).<method>(...)`
@Riverpod(keepAlive: true)
class NotificationsActions extends _$NotificationsActions {
  @override
  FutureOr<void> build() {}

  NotificationsClient get _api => ref.read(restClientProvider).notifications;

  Future<R> _run<R>(Future<R> Function() call) async {
    state = const AsyncLoading();
    try {
      final result = await call();
      if (ref.mounted) {
        state = const AsyncData(null);
        ref.invalidate(getNotificationsProvider);
        ref.invalidate(getNotificationsUnreadCountProvider);
      }
      return result;
    } catch (e, st) {
      if (ref.mounted) state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Gửi thông báo — cần notification:send.
  Future<EmptyResponse> postNotifications({
    required SendNotificationRequest body,
  }) => _run(() => _api.postNotifications(body: body));

  /// Đánh dấu đã đọc tất cả.
  Future<EmptyResponse> postNotificationsReadAll() =>
      _run(() => _api.postNotificationsReadAll());

  /// Đánh dấu đã đọc MỘT thông báo (id là bản ghi người nhận).
  Future<IdResponse> postNotificationsIdRead({required String id}) =>
      _run(() => _api.postNotificationsIdRead(id: id));
}
