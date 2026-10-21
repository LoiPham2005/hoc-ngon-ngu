import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:lingua/modules/ads/ad_manager.dart';

/// Kích thước = factory native đăng ký ở Android (MainActivity) / iOS (AppDelegate).
enum NativeAdSize {
  small('nativeSmall', 100),
  medium('nativeMedium', 360);

  const NativeAdSize(this.factoryId, this.height);
  final String factoryId;
  final double height;
}

/// Native ad nhúng trong màn (list, card). Tự ẩn/hiện khi config đổi; chưa có ad thì 0px.
class NativeAdWidget extends ConsumerStatefulWidget {
  const NativeAdWidget({
    required this.placement,
    super.key,
    this.size = NativeAdSize.medium,
    this.height,
  });

  /// Key trong `ad_units.native` (vd `NativePlacement.home`).
  final String placement;
  final NativeAdSize size;

  /// Ghi đè chiều cao mặc định của [size].
  final double? height;

  @override
  ConsumerState<NativeAdWidget> createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends ConsumerState<NativeAdWidget> {
  late final AdManager _ads = ref.read(adManagerProvider);
  NativeAd? _ad;
  bool _loaded = false;
  String? _id;
  int _retries = 0;

  @override
  void initState() {
    super.initState();
    _ads.config.addListener(_reload);
    _reload();
  }

  void _reload() {
    final id = _ads.nativeUnit(widget.placement)?.id;
    if (id == _id) return;
    _ad?.dispose();
    _ad = null;
    _retries = 0;
    _id = id;
    if (_loaded && mounted) setState(() => _loaded = false);
    if (id != null) _load(id);
  }

  void _load(String id) {
    final ad = _ad = NativeAd(
      adUnitId: id,
      factoryId: widget.size.factoryId,
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (_) {
          _retries = 0;
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, _) {
          ad.dispose();
          if (identical(ad, _ad)) _ad = null;
          if (!mounted || ++_retries > 2) return;
          Timer(Duration(seconds: 2 * _retries), () {
            if (mounted && _ad == null && _id == id) _load(id);
          });
        },
      ),
    );
    unawaited(ad.load());
  }

  @override
  void dispose() {
    _ads.config.removeListener(_reload);
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (!_loaded || ad == null) return const SizedBox.shrink();
    return SizedBox(
      width: double.infinity,
      height: widget.height ?? widget.size.height,
      child: AdWidget(ad: ad),
    );
  }
}
