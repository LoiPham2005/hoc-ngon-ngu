import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Native ad toàn màn + nút đóng (AdManager tự mở qua `showNativeFull`).
class NativeAdFullScreen extends StatelessWidget {
  const NativeAdFullScreen({
    required this.ad,
    required this.onClosed,
    super.key,
  });

  final NativeAd ad;
  final VoidCallback onClosed;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: AdWidget(ad: ad)),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 8,
            right: 12,
            child: IconButton.filled(
              style: IconButton.styleFrom(backgroundColor: Colors.black45),
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: onClosed,
            ),
          ),
        ],
      ),
    );
  }
}
