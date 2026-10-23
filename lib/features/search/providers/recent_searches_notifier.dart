import 'package:lingua/core/di/global_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'recent_searches_notifier.g.dart';

/// Từ đã tra gần đây (mới nhất trước, tối đa [limit]) — lưu trên máy.
@Riverpod(keepAlive: true)
class RecentSearchesNotifier extends _$RecentSearchesNotifier {
  static const _key = 'search_recent_v1';
  static const limit = 10;

  @override
  List<String> build() =>
      ref.read(sharedPrefsProvider).getStringList(_key) ?? const [];

  /// Ghi lại 1 lần tra (trùng → đưa lên đầu, không phân biệt hoa/thường).
  Future<void> add(String query) {
    final q = query.trim();
    if (q.isEmpty) return Future.value();
    return _save(
      [
        q,
        ...state.where((s) => s.toLowerCase() != q.toLowerCase()),
      ].take(limit).toList(),
    );
  }

  Future<void> clear() => _save(const []);

  Future<void> _save(List<String> next) async {
    state = next;
    await ref.read(sharedPrefsProvider).setStringList(_key, next);
  }
}
