// GENERATED CODE - DO NOT MODIFY BY HAND
// Sinh bởi gen_api.dart — chạy lại `make gen-api` là bị ghi đè.
// ignore_for_file: type=lint

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../rest_client.dart';

part 'rest_client_provider.g.dart';

/// `RestClient` mà mọi provider sinh sẵn dùng. App GHI ĐÈ một lần ở ProviderContainer/ProviderScope gốc,
/// trỏ về Dio của app (base URL, token, interceptor...):
///
/// ```dart
/// overrides: [restClientProvider.overrideWith((ref) => RestClient(ref.read(dioProvider)))]
/// ```
@Riverpod(keepAlive: true)
RestClient restClient(Ref ref) => throw UnimplementedError(
  'Chưa ghi đè restClientProvider — thêm restClientProvider.overrideWith(...) vào ProviderContainer/ProviderScope gốc của app.',
);
