import 'dart:async';

import 'package:lingua/core/errors/error_handler.dart';
import 'package:lingua/core/errors/failures.dart';
import 'package:lingua/core/utils/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

/// Mixin cho AsyncNotifier: mọi thao tác async (tải, tìm, tạo/sửa/xoá) đi qua 1 hàm [run].
///
/// ```dart
/// Future<void> refresh() => run(_fetch);                       // kết quả kiểu T → thay state
/// Future<void> search(String q) => run(() => _search(q), cancelPrevious: true);
/// Future<void> delete(String id) => run(
///   () => _api.delete(id),
///   apply: (list, _) => list.where((e) => e.id != id).toList(), // sửa state tại chỗ
///   successMessage: 'Đã xoá',
/// );
/// ```
// ignore: invalid_use_of_internal_member
mixin BaseNotifier<T> on $AsyncNotifier<T> {
  // KHÔNG đóng ở `ref.onDispose`: Riverpod 3 giữ nguyên notifier khi provider build lại
  // (invalidate / dependency đổi) nhưng vẫn gọi onDispose → đóng là mất mọi toast về sau.
  // Broadcast không người nghe thì không tốn gì, được thu gom cùng notifier.
  final _messages = StreamController<RunMessage>.broadcast();
  int _busy = 0;
  int _seq = 0;
  int _latest = 0;

  /// Toast 1 lần (thành công / lỗi khi vẫn giữ data). `AsyncView` tự lắng nghe.
  Stream<RunMessage> get messages => _messages.stream;

  /// Đang có [run] chạy.
  bool get isBusy => _busy > 0;

  /// Chạy [action] và cập nhật state:
  /// - Thành công: có [apply] → `state = apply(state, kết quả)`; không có mà kết quả
  ///   cùng kiểu `T` → thay state; còn lại giữ nguyên state.
  /// - Lỗi: đang có data → giữ data + toast lỗi; chưa có data → `AsyncError` (màn lỗi).
  ///
  /// [silent]: không đẩy trạng thái loading (load-more, việc chạy nền).
  /// [cancelPrevious]: bỏ kết quả lần gọi trước (search/filter gõ liên tục).
  /// [dropIfBusy]: đang chạy thì bỏ qua lần gọi mới (chống bấm 2 lần).
  ///
  /// Trả `true` khi thành công (vd: đóng màn sau khi lưu).
  Future<bool> run<R>(
    Future<R> Function() action, {
    T Function(T current, R result)? apply,
    bool silent = false,
    bool cancelPrevious = false,
    bool dropIfBusy = false,
    String? successMessage,
    String? errorMessage,
  }) async {
    if (dropIfBusy && isBusy) return false;
    final id = ++_seq;
    if (cancelPrevious) _latest = id;
    final previous = state;
    if (!silent) {
      // ignore: invalid_use_of_internal_member
      state = AsyncValue<T>.loading().copyWithPrevious(previous);
    }

    _busy++;
    try {
      final result = await action();
      if (!ref.mounted || (cancelPrevious && id != _latest)) return false;
      var updated = false;
      if (apply != null) {
        if (state.hasValue) {
          final current = state.requireValue;
          final next = apply(current, result);
          if (!silent || !identical(next, current)) state = AsyncData(next);
          updated = true;
        }
      } else if (result is T) {
        state = AsyncData(result as T);
        updated = true;
      }
      // Không có gì để cập nhật (kết quả khác kiểu / chưa có data để apply) → bỏ loading,
      // trả về trạng thái trước (kể cả đang lỗi) thay vì kẹt loading mãi.
      if (!updated && !silent) state = previous;
      if (successMessage != null) _emit(RunMessage(successMessage));
      return true;
    } catch (e, s) {
      if (!ref.mounted || (cancelPrevious && id != _latest)) return false;
      final failure = ErrorHandler.handle(e);
      talker.error('run failed', e, s);
      final text = errorMessage == null
          ? failure.message
          : '$errorMessage: ${failure.message}';
      if (previous.hasValue) {
        if (!silent) state = AsyncData(previous.requireValue);
        _emit(RunMessage(text, failure: failure));
      } else {
        state = AsyncError(failure, s);
      }
      return false;
    } finally {
      _busy--;
    }
  }

  void _emit(RunMessage m) {
    if (!_messages.isClosed) _messages.add(m);
  }
}

/// Thông báo 1 lần từ [BaseNotifier.run]. `failure != null` = lỗi.
class RunMessage {
  const RunMessage(this.text, {this.failure});
  final String text;
  final Failure? failure;
  bool get isError => failure != null;
}
