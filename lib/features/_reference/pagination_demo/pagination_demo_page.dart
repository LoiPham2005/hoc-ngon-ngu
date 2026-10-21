import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingua/features/_reference/pagination_demo/models/item_model.dart';
import 'package:lingua/features/_reference/pagination_demo/providers/pagination_demo_notifier.dart';
import 'package:lingua/shared/states/async_view.dart';

@RoutePage()
class PaginationDemoPage extends HookConsumerWidget {
  const PaginationDemoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(paginationDemoProvider);
    final notifier = ref.read(paginationDemoProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Phân trang Infinite Scroll'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: notifier.refresh,
          ),
        ],
      ),
      body: AsyncView<List<ItemModel>>(
        state: state,
        notifier: notifier,
        onRefresh: notifier.refresh,
        onRetry: notifier.refresh,
        builder: (context, items) {
          return NotificationListener<ScrollNotification>(
            onNotification: (scrollInfo) {
              // Khi cuộn gần đến đáy (cách 150px) -> tự động load trang tiếp theo
              if (scrollInfo.metrics.pixels >=
                  scrollInfo.metrics.maxScrollExtent - 150) {
                notifier.loadMore();
              }
              return false;
            },
            child: ListView.separated(
              itemCount: items.length + (notifier.isLoadingMore ? 1 : 0),
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                // Item cuối cùng: Hiện spinner loading khi đang load thêm trang
                if (index == items.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  );
                }

                final item = items[index];
                return ListTile(
                  leading: CircleAvatar(child: Text(item.id)),
                  title: Text(
                    item.title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(item.description),
                  trailing: const Text(
                    ' đ',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
