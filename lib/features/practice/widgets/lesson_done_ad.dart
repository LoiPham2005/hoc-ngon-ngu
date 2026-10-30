import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingua/modules/ads/ad_config.dart';
import 'package:lingua/modules/ads/ad_manager.dart';
import 'package:lingua/modules/ads/widgets/native_ad_widget.dart';

/// Bài ngắn hơn ngưỡng này thì không hiện quảng cáo toàn màn (làm 2–3 câu mà gặp ad là bỏ app).
const _minQuestions = 5;

/// Hiện interstitial `lesson_done` đúng 1 lần khi màn kết quả vừa mở — điểm dừng tự nhiên,
/// người học không đang thao tác. Interstitial được nạp sẵn (`preload`) nên thường hiện ngay;
/// giãn cách / số lần mỗi phiên do `rules` trên Remote Config quyết.
void useLessonDoneAd(WidgetRef ref, {required int total}) {
  useEffect(() {
    if (total < _minQuestions) return null;
    // Sau khung hình đầu: màn kết quả đã hiện, ad phủ lên → đóng ad là thấy điểm ngay.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => unawaited(
        ref
            .read(adManagerProvider)
            .showInterstitial(InterstitialPlacement.lessonDone),
      ),
    );
    return null;
  }, const []);
}

/// Native nhỏ dưới điểm số ở màn kết quả (chưa có ad → chiếm 0px).
class ResultNativeAd extends StatelessWidget {
  const ResultNativeAd({super.key});

  @override
  Widget build(BuildContext context) => const NativeAdWidget(
    placement: NativePlacement.result,
    size: NativeAdSize.small,
    padding: EdgeInsets.symmetric(vertical: 12),
  );
}
