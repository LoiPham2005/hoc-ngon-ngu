import 'package:lingua/core/network/api_response.dart';
import 'package:lingua/core/network/dio_provider.dart';
import 'package:lingua/core/riverpod/base_notifier.dart';
import 'package:lingua/core/riverpod/paginated_notifier.dart';
import 'package:lingua/features/_reference/pagination_demo/models/item_model.dart';
import 'package:lingua/features/_reference/pagination_demo/services/pagination_demo_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'pagination_demo_notifier.g.dart';

/// Reference chuẩn cho Feature phân trang danh sách (Clean Architecture)
@riverpod
class PaginationDemoNotifier extends _$PaginationDemoNotifier
    with BaseNotifier<List<ItemModel>>, PaginatedNotifier<ItemModel> {
  late final PaginationDemoService _service;

  @override
  Future<List<ItemModel>> build() {
    _service = PaginationDemoService(ref.dio);
    return loadFirstPage();
  }

  @override
  Future<PaginatedResponse<ItemModel>> fetchPage(int page) async {
    // 💡 Trong thực tế gọi API thật:
    // return (await _service.getItems(page: page, limit: 10)).data;

    // ⚡ Giả lập delay và dữ liệu mẫu:
    await Future<void>.delayed(const Duration(milliseconds: 600));
    const totalPages = 4;
    const perPage = 10;

    if (page > totalPages) {
      return PaginatedResponse(
        meta: PageMeta(page: page, totalPages: totalPages),
      );
    }

    final start = (page - 1) * perPage;
    final items = List.generate(
      perPage,
      (i) => ItemModel(
        id: '${start + i + 1}',
        title: 'Sản phẩm mẫu #${start + i + 1}',
        description: 'Mô tả chi tiết cho sản phẩm #${start + i + 1}',
        price: (start + i + 1) * 50000,
      ),
    );

    return PaginatedResponse(
      items: items,
      meta: PageMeta(
        page: page,
        limit: perPage,
        total: totalPages * perPage,
        totalPages: totalPages,
        hasNext: page < totalPages,
      ),
    );
  }
}
