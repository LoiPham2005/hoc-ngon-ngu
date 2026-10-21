import 'package:api_client/api_client.dart';
import 'package:lingua/core/network/dio_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'api_client_provider.g.dart';

/// `RestClient` (sinh từ `packages/api_client`) dùng chung nhiều feature — tập trung 1 chỗ như
/// [dioProvider]. Đọc nhóm endpoint qua `ref.apiClient.users` (RestClient tự cache), không tạo provider riêng.
@Riverpod(keepAlive: true)
RestClient apiClient(Ref ref) => RestClient(ref.read(dioProvider));

/// Viết tắt của `ref.read(apiClientProvider)` — vẫn đi qua provider gốc nên
/// giữ nguyên singleton (`keepAlive: true`) và override được trong test.
extension RefApiClientX on Ref {
  RestClient get apiClient => read(apiClientProvider);
}

/// Nối `restClientProvider` (provider GET/ghi sinh sẵn trong `packages/api_client` bởi `make gen-api`) về
/// [apiClientProvider] — dùng chung Dio của app. Thêm vào `overrides` của ProviderContainer/ProviderScope gốc.
final apiClientOverrides = [
  restClientProvider.overrideWith((ref) => ref.watch(apiClientProvider)),
];
