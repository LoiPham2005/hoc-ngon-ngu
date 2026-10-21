import 'package:lingua/core/network/api_response.dart';
import 'package:lingua/core/riverpod/base_notifier.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

/// Mixin phan trang danh sach (Infinite-scroll / Load-more).
///
/// Cung cap san toan bo tinh nang cua [BaseNotifier] + phan trang, giup ban chi can mixin 1 lan duy nhat:
/// `dart
/// @riverpod
/// class ProductNotifier extends _$ProductNotifier with BaseNotifier<List<Product>>, PaginatedNotifier<Product> {
///   @override
///   Future<List<Product>> build() => loadFirstPage();
///
///   @override
///   Future<PaginatedResponse<Product>> fetchPage(int page) => ...;
/// }
/// `// ignore: invalid_use_of_internal_member
mixin PaginatedNotifier<E> on BaseNotifier<List<E>> {
  int _page = 1;
  bool _hasMore = true;
  bool _loadingMore = false;

  /// Bump mỗi khi bắt đầu lại từ trang 1 — [loadMore] tự bỏ kết quả lỗi thời
  /// nếu refresh chen ngang lúc đang tải trang kế.
  int _epoch = 0;

  int get currentPage => _page;
  bool get hasMore => _hasMore;
  bool get isLoadingMore => _loadingMore;

  /// Goi API lay du lieu 1 trang.
  Future<PaginatedResponse<E>> fetchPage(int page);

  /// Load trang dau tien (thuong goi trong ham build() cua Notifier).
  Future<List<E>> loadFirstPage() async {
    _epoch++;
    _page = 1;
    final res = await fetchPage(1);
    _hasMore = res.hasMore;
    return res.items;
  }

  /// Pull-to-refresh danh sach (giu du lieu cu tren UI trong luc tai).
  Future<void> refresh() {
    _epoch++;
    _page = 1;
    return run(() async {
      final res = await fetchPage(1);
      _hasMore = res.hasMore;
      return res.items;
    });
  }

  /// Tai va noi tiep trang tiep theo vao cuoi danh sach.
  Future<void> loadMore() async {
    if (_loadingMore || !_hasMore || state.isLoading || !state.hasValue) return;
    _loadingMore = true;
    final next = _page + 1;
    final epoch = _epoch;
    try {
      await run(
        () => fetchPage(next),
        silent: true, // footer spinner đọc isLoadingMore, khỏi cần top bar
        apply: (current, res) {
          if (epoch != _epoch) return current; // đã bị refresh chen ngang
          _page = next;
          _hasMore = res.hasMore;
          return [...current, ...res.items];
        },
      );
    } finally {
      _loadingMore = false;
    }
  }
}
