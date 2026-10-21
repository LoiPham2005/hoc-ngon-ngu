import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'global_providers.g.dart';

/// ProviderContainer gốc — dùng cho code không có `ref` (interceptor, service,
/// route guard, error zone). Khởi tạo trong `main.dart`.
ProviderContainer globalContainer = ProviderContainer();

/// Override bằng instance thật trong `main()` (cần `await` lúc boot).
@Riverpod(keepAlive: true)
SharedPreferences sharedPrefs(Ref ref) =>
    throw UnimplementedError('Override sharedPrefsProvider trong main()');

@Riverpod(keepAlive: true)
FlutterSecureStorage secureStorage(Ref ref) => const FlutterSecureStorage();
