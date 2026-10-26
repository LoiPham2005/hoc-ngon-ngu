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

  /// Các lần chạy KHÔNG silent đang chờ: id → (ref của lần build, có cancelPrevious không).
  /// Còn lần khác chưa xong thì giữ cờ loading (thanh tiến trình không tắt sớm).
  final _pending = <int, ({Object owner, bool cancel})>{};

  /// Toast 1 lần (thành công / lỗi khi vẫn giữ data). `AsyncView` tự lắng nghe.
  Stream<RunMessage> get messages => _messages.stream;

  /// Đang có [run] chạy.
  bool get isBusy => _busy > 0;

  /// Chạy [action] và cập nhật state:
  /// - Thành công: có [apply] → `state = apply(state, kết quả)`; không có mà kết quả
  ///   cùng kiểu `T` → thay state; còn lại (vd việc trả `void`) giữ nguyên state.
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
    // Ref của lần build hiện tại: provider build lại / bị huỷ trong lúc chờ → ref này hết
    // hiệu lực → bỏ kết quả (không ghi đè dữ liệu của lần build mới, vd vừa đổi bộ lọc).
    final owner = ref;
    final previous = state;
    if (!silent) {
      _pending[id] = (owner: owner, cancel: cancelPrevious);
      // ignore: invalid_use_of_internal_member
      state = AsyncValue<T>.loading().copyWithPrevious(previous);
    }
    void set(AsyncValue<T> value) => state = _othersPending(id, owner)
        // ignore: invalid_use_of_internal_member
        ? AsyncValue<T>.loading().copyWithPrevious(value)
        : value;

    _busy++;
    try {
      final result = await action();
      if (!owner.mounted || (cancelPrevious && id != _latest)) return false;
      var updated = false;
      if (apply != null) {
        if (state.hasValue) {
          final current = state.requireValue;
          final next = apply(current, result);
          if (!silent || !identical(next, current)) set(AsyncData(next));
          updated = true;
        }
      } else if (_replaces(result)) {
        set(AsyncData(result as T));
        updated = true;
      }
      // Không có gì để cập nhật (kết quả khác kiểu / chưa có data để apply) → bỏ loading
      // (kể cả đang lỗi) thay vì kẹt loading mãi.
      if (!updated && !silent) set(_settled(previous));
      if (successMessage != null) _emit(RunMessage(successMessage));
      return true;
    } catch (e, s) {
      if (!owner.mounted || (cancelPrevious && id != _latest)) return false;
      final failure = ErrorHandler.handle(e);
      // Lỗi đoán trước (mất mạng, hết phiên, nhập sai, 4xx) chỉ ghi vết; lỗi lạ / server 5xx
      // mới báo Crashlytics + Sentry như lỗi app.
      if (_isExpected(failure)) {
        talker.warning('run failed: ${failure.message}');
      } else {
        talker.error('run failed', e, s);
      }
      final text = errorMessage == null
          ? failure.message
          : '$errorMessage: ${failure.message}';
      // Còn data (của lúc bắt đầu hoặc do lần chạy khác vừa cập nhật) → giữ data + toast lỗi.
      if (state.hasValue) {
        if (!silent) set(_settled(previous));
        _emit(RunMessage(text, failure: failure));
      } else {
        set(AsyncError(failure, s));
      }
      return false;
    } finally {
      _busy--;
      _pending.remove(id);
      // Lần chạy giữ cờ loading cho mình đã bị bỏ (cancelPrevious / build lại) → khi không còn
      // lần nào chờ thì tắt cờ, tránh kẹt thanh tiến trình. Không động vào build() đang chạy.
      if (!silent &&
          owner.mounted &&
          state.isLoading &&
          (state.hasValue || state.hasError) &&
          !_othersPending(id, owner)) {
        state = _settled(previous);
      }
    }
  }

  /// Còn lần chạy khác (cùng lần build, chưa bị lần mới hơn thay thế) đang chờ.
  bool _othersPending(int id, Object owner) => _pending.entries.any(
    (e) =>
        e.key != id &&
        identical(e.value.owner, owner) &&
        !(e.value.cancel && e.key != _latest),
  );

  void _emit(RunMessage m) => _messages.add(m);

  /// Kết quả thay được state: cùng kiểu `T`. Riêng `null` chỉ thay khi [action] KHAI BÁO trả về
  /// kiểu của state — notifier `T?` (vd `User?`) gọi việc trả `void` (đổi mật khẩu, gửi mail…)
  /// ra `null` lúc chạy, không được xoá mất state.
  bool _replaces<R>(R result) =>
      result is T && (result != null || <R>[] is List<T>);

  /// Bỏ cờ loading [run] đã đặt, giữ data / lỗi HIỆN TẠI — có thể đã đổi bởi 1 lần chạy khác
  /// trong lúc chờ (không trả về bản chụp cũ, tránh đè mất dữ liệu mới).
  AsyncValue<T> _settled(AsyncValue<T> previous) {
    final now = state;
    if (now.hasValue) return AsyncData(now.requireValue);
    if (now.error case final error?) {
      return AsyncError(error, now.stackTrace ?? StackTrace.current);
    }
    return previous;
  }

  static bool _isExpected(Failure f) => switch (f) {
    NetworkFailure() || UnauthorizedFailure() || ValidationFailure() => true,
    ServerFailure(:final code) => code != null && code < 500,
    _ => false,
  };
}

/// Thông báo 1 lần từ [BaseNotifier.run]. `failure != null` = lỗi.
class RunMessage {
  const RunMessage(this.text, {this.failure});
  final String text;
  final Failure? failure;
  bool get isError => failure != null;
}
