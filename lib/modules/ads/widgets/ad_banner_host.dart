import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lingua/modules/ads/widgets/ad_banner_widget.dart';

/// Một banner neo đáy cho MỌI màn (đặt trong `MaterialApp.builder`): giữ nguyên khi chuyển màn
/// nên không tải lại mỗi lần mở màn (đỡ phí lượt xin, show rate cao), AdMob tự làm mới.
/// Ẩn ở các route trong [hiddenOn] (đang làm bài, splash…) và khi bàn phím đang mở.
class AdBannerHost extends StatelessWidget {
  const AdBannerHost({
    required this.route,
    required this.placement,
    required this.child,
    this.hiddenOn = const {},
    super.key,
  });

  /// Route đang hiện (vd `ScreenTracker.route`).
  final ValueListenable<String?> route;
  final String placement;
  final Set<String> hiddenOn;
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
          ColoredBox(
            color: Theme.of(context).colorScheme.surface,
            child: SafeArea(
              top: false,
              child: AdBannerWidget(placement: placement),
            ),
          ),
        ],
      );
    },
  );
}
