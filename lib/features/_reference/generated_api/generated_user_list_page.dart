import 'package:api_client/api_client.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingua/core/errors/error_handler.dart';
import 'package:lingua/core/utils/toast.dart';
import 'package:lingua/shared/base/app_scaffold.dart';
import 'package:lingua/shared/states/async_view.dart';

/// Mẫu dùng THẲNG provider do `make gen-api` sinh trong `packages/api_client` — không viết notifier nào.
///
/// - Đọc:  `ref.watch(getUsersProvider(page: .., limit: ..))`, `ref.watch(getUsersIdProvider(id: ..))`.
/// - Ghi:  `ref.read(usersActionsProvider.notifier).patchUsersIdStatus(...)` / `.deleteUsersId(...)` —
///         xong tự làm mới mọi provider GET nhóm users, nên danh sách tự tải lại, không cần sửa list tay.
///
/// Hợp với màn đơn giản. Cần cập nhật lạc quan, gộp nhiều API, cuộn vô hạn... thì viết notifier riêng như
/// `_reference/openapi_user` (xem README cạnh file này).
@RoutePage()
class GeneratedUserListPage extends HookConsumerWidget {
  const GeneratedUserListPage({super.key});

  static const _limit = 20;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final page = useState(1);
    final users = ref.watch(getUsersProvider(page: page.value, limit: _limit));
    // State của Actions = đang chạy / lỗi của lần ghi gần nhất — dùng để hiện thanh bận.
    final busy = ref.watch(usersActionsProvider).isLoading;
    final actions = ref.read(usersActionsProvider.notifier);

    // Actions NÉM lỗi ra cho nơi gọi -> bắt ở đây để báo toast.
    Future<void> run(Future<Object?> Function() call, String done) async {
      try {
        await call();
        toast.success(done);
      } catch (e) {
        toast.error(ErrorHandler.handle(e).message);
      }
    }

    return AppScaffold(
      appBar: AppBar(
        title: const Text('Users (provider sinh sẵn)'),
        bottom: busy
            ? const PreferredSize(
                preferredSize: Size.fromHeight(2),
                child: LinearProgressIndicator(minHeight: 2),
              )
            : null,
      ),
      body: AsyncView<UsersListResponse>(
        state: users,
        onRetry: () => ref.invalidate(getUsersProvider),
        onRefresh: () => ref.refresh(
          getUsersProvider(page: page.value, limit: _limit).future,
        ),
        isEmpty: (res) => res.data.items.isEmpty,
        emptyTitle: 'Chưa có người dùng nào',
        builder: (context, res) => Column(
          children: [
            Expanded(
              child: ListView.separated(
                itemCount: res.data.items.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final u = res.data.items[i];
                  final active = u.status == UserStatusStatus.active;
                  return ListTile(
                    title: Text(u.fullName ?? u.username ?? u.email ?? u.id),
                    subtitle: Text(u.email ?? u.phone ?? '-'),
                    leading: Icon(active ? Icons.person : Icons.lock_outline),
                    onTap: () => showDialog<void>(
                      context: context,
                      builder: (_) => _UserDetailDialog(id: u.id),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: active ? 'Khoá tài khoản' : 'Mở khoá',
                          icon: Icon(active ? Icons.lock : Icons.lock_open),
                          onPressed: busy
                              ? null
                              : () => run(
                                  () => actions.patchUsersIdStatus(
                                    id: u.id,
                                    body: UpdateUserStatusRequest(
                                      status: active
                                          ? UpdateUserStatusRequestStatusStatus
                                                .banned
                                          : UpdateUserStatusRequestStatusStatus
                                                .active,
                                    ),
                                  ),
                                  'Đã cập nhật trạng thái',
                                ),
                        ),
                        IconButton(
                          tooltip: 'Xoá',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: busy
                              ? null
                              : () => run(
                                  () => actions.deleteUsersId(id: u.id),
                                  'Đã xoá người dùng',
                                ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            _Pager(meta: res.data.meta, onChanged: (p) => page.value = p),
          ],
        ),
      ),
    );
  }
}

class _Pager extends StatelessWidget {
  const _Pager({required this.meta, required this.onChanged});

  final PaginationMeta meta;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: meta.page > 1 ? () => onChanged(meta.page - 1) : null,
          ),
          Text('Trang ${meta.page}/${meta.totalPages} · ${meta.total} người'),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: meta.hasNext ? () => onChanged(meta.page + 1) : null,
          ),
        ],
      ),
    );
  }
}

/// Provider family theo `id` — mỗi user một cache riêng, đóng dialog là tự huỷ (autoDispose).
class _UserDetailDialog extends ConsumerWidget {
  const _UserDetailDialog({required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(getUsersIdProvider(id: id));
    return AlertDialog(
      title: const Text('Chi tiết'),
      content: switch (detail) {
        AsyncData(:final value) => Text(
          'Tên: ${value.data.user.fullName ?? '-'}\n'
          'Email: ${value.data.user.email ?? '-'}\n'
          'Vai trò: ${value.data.user.roles.join(', ')}\n'
          'Trạng thái: ${value.data.user.status.name}',
        ),
        AsyncError(:final error) => Text(
          ErrorHandler.handle(error).message,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
        _ => const SizedBox(
          height: 48,
          child: Center(child: CircularProgressIndicator()),
        ),
      },
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Đóng'),
        ),
      ],
    );
  }
}
