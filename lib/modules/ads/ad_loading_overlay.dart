import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lingua/design/l10n/l10n_extensions.dart';
import 'package:lingua/design/theme/app_colors.dart';
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

/// Phủ kín màn (như các app công ty): giữa là 3 ô chữ "A · あ · 文" nảy lần lượt, dưới là chữ
/// "Đang tải quảng cáo…". Vẽ bằng Flutter, không cần file Lottie / GIF; theo màu chủ đạo + sáng/tối.
class _LoadingView extends HookWidget {
  const _LoadingView();

  static const _glyphs = ['A', 'あ', '文'];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final controller = useAnimationController(
      duration: const Duration(milliseconds: 1200),
    );
    useEffect(() {
      controller.repeat();
      return null;
    }, const []);

    return Stack(
      children: [
        // Chặn chạm + che màn bên dưới (không lộ nội dung giật cục khi ad bật lên).
        ModalBarrier(dismissible: false, color: colors.background),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: controller,
                builder: (context, _) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final (i, glyph) in _glyphs.indexed)
                      _BouncingTile(
                        glyph: glyph,
                        // Mỗi ô trễ 1/6 vòng → sóng nảy từ trái sang phải.
                        t: (controller.value - i / 6) % 1,
                        color: colors.primary,
                        soft: colors.primarySoft,
                        onColor: colors.onPrimary,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Text(
                context.l10n.ads_loading,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BouncingTile extends StatelessWidget {
  const _BouncingTile({
    required this.glyph,
    required this.t,
    required this.color,
    required this.soft,
    required this.onColor,
  });

  final String glyph;

  /// Vị trí trong vòng lặp (0..1): nảy ở nửa đầu, nằm yên nửa sau.
  final double t;
  final Color color;
  final Color soft;
  final Color onColor;

  @override
  Widget build(BuildContext context) {
    final up = t < 0.5
        ? Curves.easeInOut.transform(sin(t * 2 * pi).abs())
        : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Transform.translate(
        offset: Offset(0, -22 * up),
        child: Transform.scale(
          scale: 1 + 0.08 * up,
          child: Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Color.lerp(soft, color, up),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.25 * up),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Text(
              glyph,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: Color.lerp(color, onColor, up),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
