import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingua/core/riverpod/base_notifier.dart';
import 'package:lingua/core/riverpod/use_run_messages.dart';
import 'package:lingua/shared/states/empty_widget.dart';
import 'package:lingua/shared/states/error_retry.dart';
import 'package:lingua/shared/states/loading_widget.dart';

/// Body chuẩn cho mọi page đọc 1 `AsyncValue`: loading / error / empty / data,
/// giữ data cũ + thanh tiến trình khi refresh, toast thông báo từ `notifier.run`.
///
/// ```dart
/// final state = ref.watch(voucherProvider);
/// final notifier = ref.read(voucherProvider.notifier);
/// return AsyncView<List<VoucherModel>>(
///   state: state,
///   notifier: notifier,          // bật toast của run(); bỏ nếu không cần
///   onRetry: notifier.refresh,
///   onRefresh: notifier.refresh, // pull-to-refresh (tuỳ)
///   emptyTitle: 'Không có voucher',
///   builder: (context, list) => _List(list),
/// );
/// ```
class AsyncView<T> extends HookWidget {
  const AsyncView({
    required this.state,
    required this.builder,
    super.key,
    this.notifier,
    this.onRetry,
    this.onRefresh,
    this.isEmpty,
    this.emptyTitle,
    this.emptyMessage,
    this.showRefreshBar = true,
  });

  final AsyncValue<T> state;

  /// Chỉ gọi khi có data và không rỗng.
  final Widget Function(BuildContext context, T value) builder;

  /// Truyền để hiện toast từ `notifier.run(successMessage:/errorMessage:)`.
  final BaseNotifier<T>? notifier;

  /// Nút "Thử lại" ở màn lỗi.
  final VoidCallback? onRetry;

  /// Có → bọc `RefreshIndicator`.
  final Future<void> Function()? onRefresh;

  /// Điều kiện rỗng. Mặc định: `Iterable`/`Map` rỗng.
  final bool Function(T value)? isEmpty;
  final String? emptyTitle;
  final String? emptyMessage;

  /// Hiện `LinearProgressIndicator` trên data cũ khi đang refresh.
  final bool showRefreshBar;

  bool _blank(T value) =>
      isEmpty?.call(value) ??
      switch (value) {
        Iterable<Object?>(:final isEmpty) => isEmpty,
        Map<Object?, Object?>(:final isEmpty) => isEmpty,
        _ => false,
      };

  Widget _content(BuildContext context, T value) => _blank(value)
      ? EmptyWidget(title: emptyTitle, message: emptyMessage)
      : builder(context, value);

  @override
  Widget build(BuildContext context) {
    useRunMessages(notifier);

    final view = switch (state) {
      AsyncValue(:final value?, isLoading: true) when showRefreshBar => Stack(
        children: [
          _content(context, value),
          const Align(
            alignment: Alignment.topCenter,
            child: LinearProgressIndicator(),
          ),
        ],
      ),
      AsyncValue(:final value?, isLoading: true) => _content(context, value),
      AsyncData(:final value) => _content(context, value),
      // Đang thử lại (bấm "Thử lại" / Riverpod tự retry) → nút hiện vòng xoay + khoá,
      // vẫn giữ màn lỗi (không nháy qua lại lỗi ↔ loading).
      AsyncError(:final error, :final isLoading) => ErrorRetry(
        message: error.toString(),
        onRetry: onRetry,
        retrying: isLoading,
      ),
      _ => const LoadingWidget(),
    };

    final refresh = onRefresh;
    return refresh == null
        ? view
        : RefreshIndicator(onRefresh: refresh, child: view);
  }
}
