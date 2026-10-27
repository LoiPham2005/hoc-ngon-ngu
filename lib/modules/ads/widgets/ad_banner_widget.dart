import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:lingua/core/utils/logger.dart';
import 'package:lingua/modules/ads/ad_manager.dart';

/// Collapsible banner: vừa load xong tự bung to đè lên nội dung, user bấm thu về banner thường
/// (CPM cao hơn). Phải đặt SÁT MÉP màn hình (vd `Scaffold.bottomNavigationBar`), không đặt giữa list.
/// Chỉ ad của Google mới bung được; mediation và các lần auto-refresh sau hiện như banner thường.
enum CollapsibleBanner { top, bottom }

/// Banner adaptive theo bề ngang màn hình. Tự ẩn/hiện khi config đổi, tự load lại khi
/// xoay màn hoặc đổi ad id; chưa có ad thì chiếm 0px.
class AdBannerWidget extends ConsumerStatefulWidget {
  const AdBannerWidget({required this.placement, super.key, this.collapsible});

  /// Key trong `ad_units.banner` (vd `BannerPlacement.home`).
  final String placement;

  /// Đặt khi banner nằm sát mép trên/dưới màn hình → bật collapsible banner.
  final CollapsibleBanner? collapsible;

  @override
  ConsumerState<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends ConsumerState<AdBannerWidget> {
  late final AdManager _ads = ref.read(adManagerProvider);
  BannerAd? _ad;
  bool _loaded = false;
  String? _key; // "id,dự phòng@width" của ad hiện tại
  int _width = 0;
  int _retries = 0;

  @override
  void initState() {
    super.initState();
    _ads.config.addListener(_reload);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final width = MediaQuery.sizeOf(context).width.truncate();
    if (width != _width) {
      _width = width;
      _reload();
    }
  }

  void _reload() {
    final unit = _ads.bannerUnit(widget.placement);
    final key = unit == null ? null : '${unit.ids.join(',')}@$_width';
    if (key == _key) return;
    _clear();
    _key = key;
    if (unit != null) _load(unit.ids);
  }

  /// Thử ID thứ [index]; không có ad → ID dự phòng kế tiếp; hết ID → thử lại cả chuỗi (tối đa 2).
  Future<void> _load(List<String> ids, [int index = 0]) async {
    final key = '${ids.join(',')}@$_width';
    final size =
        await AdSize.getLargeAnchoredAdaptiveBannerAdSize(_width) ??
        AdSize.banner;
    if (!mounted || _key != key) return;
    final ad = _ad = BannerAd(
      adUnitId: ids[index],
      size: size,
      request: AdRequest(
        extras: {if (widget.collapsible case final c?) 'collapsible': c.name},
      ),
      listener: BannerAdListener(
        onAdLoaded: (ad) async {
          _retries = 0;
          if (widget.collapsible != null &&
              !await (ad as BannerAd).isCollapsible) {
            talker.debug(
              '[ADS] banner.${widget.placement}: ad trả về không phải collapsible',
            );
          }
          if (mounted) setState(() => _loaded = true);
        },
        onPaidEvent: (ad, valueMicros, _, currency) => _ads.reportPaid(
          ad,
          valueMicros,
          currency,
          'banner.${widget.placement}',
        ),
        onAdFailedToLoad: (ad, _) {
          ad.dispose();
          if (identical(ad, _ad)) _ad = null;
          if (!mounted || _key != key) return;
          if (index + 1 < ids.length) {
            unawaited(_load(ids, index + 1));
            return;
          }
          if (++_retries > 2) return;
          Timer(Duration(seconds: 2 * _retries), () {
            if (mounted && _ad == null && _key == key) _load(ids);
          });
        },
      ),
    );
    unawaited(ad.load());
  }

  void _clear() {
    _ad?.dispose();
    _ad = null;
    _retries = 0;
    if (_loaded && mounted) setState(() => _loaded = false);
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
      width: ad.size.width.toDouble(),
      height: ad.size.height.toDouble(),
      child: AdWidget(ad: ad),
    );
  }
}
