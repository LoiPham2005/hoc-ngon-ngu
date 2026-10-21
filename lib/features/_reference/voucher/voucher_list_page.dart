import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingua/features/_reference/voucher/models/voucher_model.dart';
import 'package:lingua/features/_reference/voucher/providers/voucher_notifier.dart';
import 'package:lingua/shared/base/app_scaffold.dart';
import 'package:lingua/shared/base/app_text_field.dart';
import 'package:lingua/shared/states/async_view.dart';

/// Reference page — pattern chuẩn để follow theo
@RoutePage()
class VoucherListPage extends HookConsumerWidget {
  const VoucherListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchCtl = useTextEditingController();
    final state = ref.watch(voucherProvider);
    final notifier = ref.read(voucherProvider.notifier);

    return AppScaffold(
      appBar: AppBar(title: const Text('Voucher')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: AppTextField(
              controller: searchCtl,
              hint: 'Tìm kiếm voucher...',
              prefixIcon: const Icon(Icons.search),
              onChanged: notifier.search,
            ),
          ),
          Expanded(
            // Render + toast (query & mutation) + pull-to-refresh trong 1 widget.
            // Đang chạy run() → giữ list + thanh tiến trình.
            child: AsyncView<List<VoucherModel>>(
              state: state,
              notifier: notifier,
              onRetry: notifier.refresh,
              onRefresh: notifier.refresh,
              emptyTitle: 'Không có voucher nào',
              builder: (context, list) =>
                  _VoucherList(list, onDelete: notifier.delete),
            ),
          ),
        ],
      ),
    );
  }
}

class _VoucherList extends StatelessWidget {
  const _VoucherList(this.items, {required this.onDelete});
  final List<VoucherModel> items;
  final void Function(String id) onDelete;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final v = items[i];
        return Card(
          child: ListTile(
            title: Text(v.title),
            subtitle: v.description == null ? null : Text(v.description!),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${v.discountPercent}%'),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => onDelete(v.id),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
