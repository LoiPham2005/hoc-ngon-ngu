import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingua/core/utils/toast.dart';
import 'package:lingua/modules/ads/ad_config.dart';
import 'package:lingua/modules/ads/ad_manager.dart';
import 'package:lingua/modules/ads/widgets/ad_banner_widget.dart';
import 'package:lingua/modules/ads/widgets/native_ad_widget.dart';
import 'package:lingua/shared/base/app_scaffold.dart';

/// Thử mọi loại ads theo cấu hình hiện tại (dev = Google test ID).
/// Mỗi placement đang bật có 1 nút; tự cập nhật khi Remote Config đổi.
@RoutePage()
class AdsDemoPage extends ConsumerWidget {
  const AdsDemoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ads = ref.read(adManagerProvider);
    return AppScaffold(
      appBar: AppBar(title: const Text('Ads Demo')),
      // Collapsible banner neo đáy màn: vào màn là bung to, bấm mũi tên để thu nhỏ.
      bottomNavigationBar: const SafeArea(
        top: false,
        child: AdBannerWidget(
          placement: BannerPlacement.bottom,
          collapsible: CollapsibleBanner.bottom,
        ),
      ),
      body: ValueListenableBuilder<AdConfig>(
        valueListenable: ads.config,
        builder: (context, cfg, _) {
          Iterable<String> active(AdType type) =>
              cfg.adUnits.of(type).keys.where((p) => cfg.unit(type, p) != null);

          void report(bool shown, String name) {
            if (!shown) {
              toast.warning('$name không hiển thị (giới hạn / chưa tải được)');
            }
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _Controls(ads: ads, cfg: cfg),
              _Section('Interstitial', [
                for (final p in active(AdType.interstitial))
                  _Button(
                    p,
                    () async => report(await ads.showInterstitial(p), p),
                  ),
              ]),
              _Section('App Open', [
                for (final p in active(AdType.appOpen))
                  _Button(p, () async => report(await ads.showAppOpen(p), p)),
              ]),
              _Section('Rewarded', [
                for (final p in active(AdType.rewarded))
                  _Button(
                    p,
                    () async => report(
                      await ads.showRewarded(
                        p,
                        onReward: (r) =>
                            toast.success('🎁 +${r.amount} ${r.type}'),
                      ),
                      p,
                    ),
                  ),
              ]),
              _Section('Rewarded Interstitial', [
                for (final p in active(AdType.rewardedInterstitial))
                  _Button(
                    p,
                    () async => report(
                      await ads.showRewardedInterstitial(
                        p,
                        onReward: (r) =>
                            toast.success('🎁 +${r.amount} ${r.type}'),
                      ),
                      p,
                    ),
                  ),
              ]),
              _Section('Native toàn màn', [
                if (cfg.unit(AdType.native, NativePlacement.full) != null)
                  _Button('showNativeFull', ads.showNativeFull),
              ]),
              _Section('Native trong màn', [
                for (final p in active(AdType.native))
                  if (p != NativePlacement.full &&
                      p != NativePlacement.afterInterstitial)
                    for (final size in NativeAdSize.values)
                      NativeAdWidget(placement: p, size: size),
              ]),
              _Section('Banner', [
                for (final p in active(AdType.banner))
                  if (p != BannerPlacement.bottom) AdBannerWidget(placement: p),
              ]),
            ],
          );
        },
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({required this.ads, required this.cfg});
  final AdManager ads;
  final AdConfig cfg;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        Chip(
          label: Text(switch ((ads.isPremium, ads.adFreeRemaining)) {
            (true, _) => 'Ads TẮT — đang premium (bấm "Huỷ premium")',
            (_, final left?) => 'Ads TẮT — tạm tắt còn ${left.inSeconds}s',
            _ when !cfg.showAllAds =>
              'Ads TẮT — Remote Config show_all_ads = false',
            _ => 'Ads đang BẬT',
          }),
        ),
        OutlinedButton(
          onPressed: () {
            ads.resetSession();
            toast.info('Đã reset giới hạn tần suất');
          },
          child: const Text('Reset session'),
        ),
        OutlinedButton(
          onPressed: () => ads.setPremium(!ads.isPremium),
          child: Text(ads.isPremium ? 'Huỷ premium' : 'Giả lập premium'),
        ),
        OutlinedButton(
          onPressed: () => ads.adFreeRemaining == null
              ? ads.pauseAds(const Duration(seconds: 30))
              : ads.resumeAds(),
          child: Text(
            ads.adFreeRemaining == null ? 'Tắt ads 30s' : 'Bật lại ads',
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title, this.children);
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          if (children.isEmpty)
            const Text('— chưa bật placement nào —')
          else
            ...children,
        ],
      ),
    );
  }
}

class _Button extends StatelessWidget {
  const _Button(this.label, this.onPressed);
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: FilledButton.tonal(onPressed: onPressed, child: Text(label)),
  );
}
