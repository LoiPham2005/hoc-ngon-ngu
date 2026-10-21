import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingua/core/services/connectivity_provider.dart';
import 'package:lingua/design/l10n/l10n_extensions.dart';
import 'package:lingua/design/theme/app_colors.dart';

/// Thanh báo mạng ở đầu màn hình, bọc toàn app (`MaterialApp.builder` trong `app.dart`).
/// Mất mạng → thanh đỏ "Không có kết nối mạng"; có lại → thanh xanh "Đã kết nối lại" 2 giây rồi ẩn.
/// Màn đang lỗi mạng vẫn tự có nút "Thử lại" của `AsyncView` — banner chỉ báo trạng thái.
class ConnectivityBanner extends HookConsumerWidget {
  const ConnectivityBanner({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final online = ref.watch(isOnlineProvider).value ?? true;
    final reconnected = useState(false);

    ref.listen(isOnlineProvider, (previous, next) {
      reconnected.value = previous?.value == false && next.value == true;
    });
    useEffect(() {
      if (!reconnected.value) return null;
      final timer = Timer(
        const Duration(seconds: 2),
        () => reconnected.value = false,
      );
      return timer.cancel;
    }, [reconnected.value]);

    final (message, color) = !online
        ? (context.l10n.connectivity_offline, context.colors.error)
        : reconnected.value
        ? (context.l10n.connectivity_online, context.colors.success)
        : (null, null);

    return Column(
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          child: message == null
              ? const SizedBox(width: double.infinity)
              : Material(
                  color: color,
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            online
                                ? Icons.wifi_rounded
                                : Icons.wifi_off_rounded,
                            size: 16,
                            color: context.colors.onPrimary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            message,
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(color: context.colors.onPrimary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
        // Banner đã chiếm phần tai thỏ → bỏ padding trên để AppBar không bị đẩy xuống thêm.
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            removeTop: message != null,
            child: child,
          ),
        ),
      ],
    );
  }
}
