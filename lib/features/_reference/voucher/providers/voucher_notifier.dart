import 'package:lingua/core/network/dio_provider.dart';
import 'package:lingua/core/riverpod/base_notifier.dart';
import 'package:lingua/features/_reference/voucher/models/voucher_model.dart';
import 'package:lingua/features/_reference/voucher/services/voucher_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'voucher_notifier.g.dart';

/// Reference Notifier — pattern chuẩn để follow theo.
@riverpod
class VoucherNotifier extends _$VoucherNotifier
    with BaseNotifier<List<VoucherModel>> {
  late VoucherService _service;

  @override
  Future<List<VoucherModel>> build() {
    _service = VoucherService(ref.dio);
    return _fetch();
  }

  Future<List<VoucherModel>> _fetch() async =>
      (await _service.getVouchers()).data;

  Future<void> refresh() => run(_fetch);

  Future<void> search(String query) => run(
    () async =>
        query.isEmpty ? _fetch() : (await _service.searchVouchers(query)).data,
    cancelPrevious: true,
  );

  /// Lỗi → giữ list + toast; thành công → gỡ khỏi list tại chỗ.
  Future<void> delete(String id) => run(
    () async => (await _service.deleteVoucher(id)).data,
    apply: (list, _) => list.where((v) => v.id != id).toList(),
    dropIfBusy: true,
    successMessage: 'Đã xoá voucher',
  );
}
