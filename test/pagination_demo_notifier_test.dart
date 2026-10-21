import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingua/core/network/dio_provider.dart';
import 'package:lingua/features/_reference/pagination_demo/providers/pagination_demo_notifier.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    // Thay Dio thật (cần FlavorConfig) bằng Dio rỗng — fetchPage của demo không gọi mạng.
    container = ProviderContainer(
      overrides: [dioProvider.overrideWithValue(Dio())],
    );
    // Giữ provider sống (autoDispose) suốt test.
    container.listen(paginationDemoProvider, (_, _) {}, fireImmediately: true);
  });
  tearDown(() => container.dispose());

  test('build() nạp trang đầu', () async {
    final list = await container.read(paginationDemoProvider.future);

    expect(list.length, 10);
    expect(list.first.id, '1');
    expect(container.read(paginationDemoProvider.notifier).hasMore, isTrue);
    expect(container.read(paginationDemoProvider.notifier).currentPage, 1);
  });

  test('loadMore nối trang kế, track hasMore', () async {
    await container.read(paginationDemoProvider.future);
    final notifier = container.read(paginationDemoProvider.notifier);

    await notifier.loadMore();
    expect(container.read(paginationDemoProvider).value?.length, 20);
    expect(notifier.hasMore, isTrue);
    expect(notifier.currentPage, 2);

    await notifier.loadMore();
    await notifier.loadMore(); // trang cuối (trang 4)
    expect(container.read(paginationDemoProvider).value?.length, 40);
    expect(notifier.hasMore, isFalse);
  });

  test('refresh() reset về trang đầu', () async {
    await container.read(paginationDemoProvider.future);
    final notifier = container.read(paginationDemoProvider.notifier);

    await notifier.loadMore();
    expect(container.read(paginationDemoProvider).value?.length, 20);

    await notifier.refresh();
    expect(container.read(paginationDemoProvider).value?.length, 10);
    expect(notifier.currentPage, 1);
    expect(notifier.hasMore, isTrue);
  });

  test('loadMore gọi trùng (double-tap) chỉ nối 1 lần', () async {
    await container.read(paginationDemoProvider.future);
    final notifier = container.read(paginationDemoProvider.notifier);

    // Gọi 2 lần liên tiếp không await — lần 2 phải bị dropIfBusy bỏ qua.
    final f1 = notifier.loadMore();
    final f2 = notifier.loadMore();
    await Future.wait([f1, f2]);

    expect(container.read(paginationDemoProvider).value?.length, 20);
    expect(notifier.currentPage, 2);
  });

  test(
    'refresh() chen ngang lúc loadMore() đang chạy → bỏ kết quả loadMore cũ',
    () async {
      await container.read(paginationDemoProvider.future);
      final notifier = container.read(paginationDemoProvider.notifier);

      final loadMoreFuture = notifier.loadMore(); // đang chờ trang 2 (600ms)
      final refreshFuture = notifier.refresh(); // chen ngang, bump epoch
      await Future.wait([loadMoreFuture, refreshFuture]);

      // Kết quả cuối phải là trang 1 mới refresh (10 item), KHÔNG bị loadMore
      // cũ nối đè thành 20.
      expect(container.read(paginationDemoProvider).value?.length, 10);
      expect(notifier.currentPage, 1);
    },
  );

  test(
    'loadMore không đẩy state.isLoading (busy:false) — chỉ isLoadingMore',
    () async {
      await container.read(paginationDemoProvider.future);
      final notifier = container.read(paginationDemoProvider.notifier);

      final future = notifier.loadMore();
      // Kiểm tra ngay sau khi gọi, trước khi 600ms delay của fetchPage xong.
      expect(container.read(paginationDemoProvider).isLoading, isFalse);
      expect(notifier.isLoadingMore, isTrue);

      await future;
      expect(notifier.isLoadingMore, isFalse);
    },
  );
}
