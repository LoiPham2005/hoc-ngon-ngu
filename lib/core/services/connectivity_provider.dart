import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'connectivity_provider.g.dart';

/// `true` = có internet thật (ping được), không chỉ là đang bật wifi/4G.
/// Kiểm tra lại NGAY khi hệ điều hành báo đổi mạng (bật/tắt wifi, 4G — `connectivity_plus`),
/// ngoài ra ping định kỳ 10s (mạng còn bật nhưng mất internet).
/// Đọc ở UI: `ref.watch(isOnlineProvider).value ?? true` (đang kiểm tra → coi như online).
/// Ngoài widget: `globalContainer.listen(isOnlineProvider, ...)`.
@Riverpod(keepAlive: true)
Stream<bool> isOnline(Ref ref) {
  final checker = InternetConnection.createInstance(
    triggerStream: Connectivity().onConnectivityChanged,
  );
  ref.onDispose(checker.dispose);
  return checker.onStatusChange
      .map((status) => status == InternetStatus.connected)
      .distinct();
}
