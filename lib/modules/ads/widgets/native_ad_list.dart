import 'package:flutter/widgets.dart';
import 'package:lingua/modules/ads/widgets/native_ad_widget.dart';

/// Chèn native vào danh sách: sau mục thứ [first], rồi cứ [every] mục một cái. Native chỉ tải
/// khi cuộn tới (ListView dựng lười) → không phí lượt xin; chưa có ad thì chiếm 0px.
List<Widget> withNativeAds(
  List<Widget> items,
  String placement, {
  int first = 3,
  int every = 8,
}) => [
  for (final (i, item) in items.indexed) ...[
    item,
    if (i + 1 == first || (i + 1 > first && (i + 1 - first) % every == 0))
      NativeAdWidget(
        placement: placement,
        size: NativeAdSize.small,
        padding: const EdgeInsets.only(bottom: 8),
      ),
  ],
];
