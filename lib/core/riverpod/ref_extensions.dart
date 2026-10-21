import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tiện ích quản lý vòng đời và cache TTL cho Riverpod Ref.
extension RefCacheX on Ref {
  /// Giữ provider sống thêm [duration] sau khi không còn widget nào lắng nghe,
  /// sau đó mới autoDispose. Nếu có widget lắng nghe lại trong thời gian này,
  /// timer sẽ tự động huỷ và giữ nguyên cache.
  ///
  /// Cách dùng:
  /// `dart
  /// @override
  /// Future<List<Product>> build() {
  ///   ref.cacheFor(const Duration(minutes: 2));
  ///   return _service.getProducts();
  /// }
  /// `
  void cacheFor(Duration duration) {
    final link = keepAlive();
    Timer? timer;
    onDispose(() => timer?.cancel());
    onCancel(() {
      timer?.cancel();
      timer = Timer(duration, link.close);
    });
    onResume(() {
      timer?.cancel();
      timer = null;
    });
  }
}
