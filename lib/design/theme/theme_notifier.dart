import 'package:lingua/core/di/global_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'theme_notifier.g.dart';

/// Các biến thể theme mà app hỗ trợ.
/// Thêm 1 giá trị mới = thêm 1 theme preset mới.
enum AppThemeVariant {
  light('Sáng'),
  dark('Tối'),
  green('Xanh');

  const AppThemeVariant(this.label);
  final String label;
}

@Riverpod(keepAlive: true)
class ThemeNotifier extends _$ThemeNotifier {
  static const _key = 'theme_variant';

  @override
  AppThemeVariant build() {
    final storage = ref.read(sharedPrefsProvider);
    final raw = storage.getString(_key);
    return AppThemeVariant.values.firstWhere(
      (v) => v.name == raw,
      orElse: () => AppThemeVariant.light,
    );
  }

  Future<void> set(AppThemeVariant variant) async {
    state = variant;
    await ref.read(sharedPrefsProvider).setString(_key, variant.name);
  }
}
