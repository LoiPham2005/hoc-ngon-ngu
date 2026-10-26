import 'package:flutter/material.dart';
import 'package:lingua/design/l10n/l10n_extensions.dart';
import 'package:lingua/routes/app_router.dart';

/// Lớp phủ "Đang tải quảng cáo…" khi ad toàn màn chưa có sẵn, phải tải tại chỗ.
/// Chặn chạm trong lúc chờ: không có nó, ad bật lên đột ngột giữa lúc user đang bấm → bấm nhầm
/// vào ad (AdMob phạt "quảng cáo xen kẽ bất ngờ / click nhầm", nặng thì giới hạn tài khoản).
/// Gắn thẳng vào Overlay của Navigator (không phải route) → không ảnh hưởng điều hướng.
class AdLoadingOverlay {
  OverlayEntry? _entry;

  void show() {
    final overlay = appRouter.navigatorKey.currentState?.overlay;
    if (overlay == null || _entry != null) return;
    final entry = _entry = OverlayEntry(builder: (_) => const _LoadingView());
    overlay.insert(entry);
  }

  void hide() {
    _entry?.remove();
    _entry = null;
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      children: [
        const ModalBarrier(dismissible: false, color: Colors.black54),
        Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox.square(
                    dimension: 24,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    context.l10n.ads_loading,
                    style: theme.textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
