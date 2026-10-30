import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lingua/modules/ads/widgets/ad_banner_widget.dart';

/// Một banner neo đáy cho MỌI màn (đặt trong `MaterialApp.builder`): giữ nguyên khi chuyển màn
/// nên không tải lại mỗi lần mở màn (đỡ phí lượt xin, show rate cao), AdMob tự làm mới.
/// Ẩn ở các route trong [hiddenOn] (đang làm bài, splash…), khi bàn phím đang mở, và khi
/// [suppressed] = true (đang hiện quảng cáo toàn màn vẽ bằng Flutter).
class AdBannerHost extends StatelessWidget {
  const AdBannerHost({
    required this.route,
    required this.placement,
    required this.child,
    this.hiddenOn = const {},
    this.suppressed,
    super.key,
  });

  /// Route đang hiện (vd `ScreenTracker.route`).
  final ValueListenable<String?> route;
  final String placement;
  final Set<String> hiddenOn;
  final ValueListenable<bool>? suppressed;
  final Widget child;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<String?>(
    valueListenable: route,
    builder: (context, current, _) {
      final media = MediaQuery.of(context);
      final show =
          current != null &&
          !hiddenOn.contains(current) &&
          media.viewInsets.bottom == 0;
      if (!show) return child;
      return Column(
        children: [
          // Banner chiếm phần đáy (gồm cả vùng thanh điều hướng của máy) → màn bên trên bỏ
          // khoảng đệm đáy, không bị hở 2 lần.
          Expanded(
            child: MediaQuery.removePadding(
              context: context,
              removeBottom: true,
              child: child,
            ),
          ),
          // Gỡ hẳn chứ không Offstage: banner bị che vẫn tự làm mới và SDK vẫn tính lượt hiển
          // thị (lượt không ai thấy = vi phạm). Hiện lại thì tải banner mới.
          ValueListenableBuilder<bool>(
            valueListenable: suppressed ?? const AlwaysStoppedAnimation(false),
            builder: (context, hide, banner) =>
                hide ? const SizedBox.shrink() : banner!,
            child: ColoredBox(
              color: Theme.of(context).colorScheme.surface,
              child: SafeArea(
                top: false,
                child: AdBannerWidget(placement: placement),
              ),
            ),
          ),
        ],
      );
    },
  );
}
