import 'package:api_client/api_client.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingua/features/_reference/openapi_user/providers/openapi_user_notifier.dart';
import 'package:lingua/shared/base/app_scaffold.dart';
import 'package:lingua/shared/states/async_view.dart';

/// Reference OpenAPI list page — pattern chuẩn để follow theo.
@RoutePage()
class OpenapiUserListPage extends HookConsumerWidget {
  const OpenapiUserListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(openapiUserProvider);
    final notifier = ref.read(openapiUserProvider.notifier);

    return AppScaffold(
      appBar: AppBar(title: const Text('Users (OpenAPI)')),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Theme.of(
              context,
            ).colorScheme.primaryContainer.withValues(alpha: 0.4),
            child: const Text(
              '🔌  openapi_retrofit_generator — types sinh từ openapi.json\n'
              '✓ Dùng chung Dio của app (token, log, base URL)\n'
              '✓ Đổi spec → chạy lại generator → compile error chỗ sai',
              style: TextStyle(fontSize: 12),
            ),
          ),
          Expanded(
            // Có mutation (xoá / đổi trạng thái) → truyền notifier vào để
            // AsyncView bắn toast kết quả một lần.
            child: AsyncView<List<User>>(
              state: state,
              notifier: notifier,
              onRetry: notifier.refresh,
              onRefresh: notifier.refresh,
              emptyTitle: 'Chưa có người dùng nào',
              builder: (context, list) => _DanhSach(
                list: list,
                isLoadingMore: notifier.isLoadingMore,
                onLoadMore: notifier.loadMore,
                onDelete: notifier.delete,
                onToggle: notifier.setStatus,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DanhSach extends StatelessWidget {
  const _DanhSach({
    required this.list,
    required this.isLoadingMore,
    required this.onLoadMore,
    required this.onDelete,
    required this.onToggle,
  });

  final List<User> list;
  final bool isLoadingMore;
  final Future<void> Function() onLoadMore;
  final Future<void> Function(String id) onDelete;
  final Future<void> Function(String id, UserStatusStatus hienTai) onToggle;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        // Gần chạm đáy thì xin thêm trang. loadMore() tự bỏ qua khi hết trang
        // hoặc khi đang có mutation chạy (dropIfBusy), nên gọi thừa vô hại.
        if (n.metrics.pixels >= n.metrics.maxScrollExtent - 200) onLoadMore();
        return false;
      },
      child: ListView.separated(
        itemCount: list.length + (isLoadingMore ? 1 : 0),
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, i) {
          if (i == list.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
            );
          }

          final u = list[i];
          final dangHoatDong = u.status == UserStatusStatus.active;

          return ListTile(
            title: Text(u.fullName ?? u.username ?? u.email ?? u.phone ?? u.id),
            subtitle: Text(
              '${u.email ?? u.phone ?? '-'} · ${u.roles.join(', ')}',
            ),
            leading: CircleAvatar(
              backgroundColor: dangHoatDong
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(context).colorScheme.errorContainer,
              child: Icon(dangHoatDong ? Icons.person : Icons.lock_outline),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: dangHoatDong ? 'Khoá tài khoản' : 'Mở khoá',
                  icon: Icon(dangHoatDong ? Icons.lock : Icons.lock_open),
                  onPressed: () => onToggle(u.id, u.status),
                ),
                IconButton(
                  tooltip: 'Xoá',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => onDelete(u.id),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
