import 'package:flutter_test/flutter_test.dart';
import 'package:lingua/core/network/api_response.dart';

/// Đúng dạng response của backend (giống model sinh trong `api_client`).
void main() {
  test('ApiResponse: { "data": {...} }', () {
    final res = ApiResponse<Map<String, dynamic>>.fromJson({
      'data': {'id': '1', 'fullName': 'A'},
    }, (j) => j! as Map<String, dynamic>);
    expect(res.data['fullName'], 'A');
  });

  test(
    'PaginatedResponse: { "data": { "items", "meta" } } — key camelCase',
    () {
      final res = ApiResponse<PaginatedResponse<String>>.fromJson(
        {
          'data': {
            'items': ['a', 'b'],
            'meta': {
              'page': 2,
              'limit': 20,
              'total': 45,
              'totalPages': 3,
              'hasNext': true,
            },
          },
        },
        (j) => PaginatedResponse<String>.fromJson(
          j! as Map<String, dynamic>,
          (e) => e! as String,
        ),
      );
      expect(res.data.items, ['a', 'b']);
      expect(res.data.meta.totalPages, 3);
      expect(res.data.hasMore, isTrue);
    },
  );
}
