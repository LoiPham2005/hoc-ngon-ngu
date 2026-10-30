import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingua/core/utils/toast.dart';
import 'package:lingua/design/l10n/l10n_extensions.dart';
import 'package:lingua/design/theme/app_colors.dart';
import 'package:lingua/features/course/providers/learner_notifier.dart';
import 'package:lingua/modules/ads/ad_config.dart';
import 'package:lingua/modules/ads/ad_manager.dart';
import 'package:lingua/modules/iap/iap_service.dart';

/// Chuỗi vừa đứt 1 ngày → mời xem rewarded để giữ chuỗi (premium: giữ miễn phí).
/// Không cứu được / tắt ad rewarded → không hiện gì. Thẻ hiện là nạp sẵn ad để bấm là có.
class StreakRestoreCard extends HookConsumerWidget {
  const StreakRestoreCard({super.key});

  static const _placement = RewardedPlacement.streakFreeze;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(learnerProvider);
    final notifier = ref.read(learnerProvider.notifier);
    final premium = ref.watch(isPremiumProvider);
    final ads = ref.read(adManagerProvider);
    final config = useValueListenable(ads.config);
    final busy = useState(false);
    final days = notifier.restorableStreak;
    final canWatch = config.unit(AdType.rewarded, _placement) != null;
    final visible = days > 0 && (premium || canWatch);

    useEffect(() {
      if (visible && !premium) ads.preload(AdType.rewarded, _placement);
      return null;
    }, [visible, premium]);

    if (!visible) return const SizedBox.shrink();

    final l10n = context.l10n;
    final colors = context.colors;
    final theme = Theme.of(context);

    Future<void> restore() async {
      busy.value = true;
      var rewarded = premium;
      if (!premium) {
        await ads.showRewarded(_placement, onReward: (_) => rewarded = true);
      }
      if (rewarded) {
        await notifier.restoreStreak();
        toast.success(l10n.home_streakRestoreDone);
      } else {
        toast.error(l10n.home_streakRestoreFailed);
      }
      if (context.mounted) busy.value = false;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          child: Row(
            children: [
              const Text('🧊', style: TextStyle(fontSize: 30)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.home_streakRestoreTitle(days),
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.home_streakRestoreBody,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: busy.value ? null : restore,
                icon: Icon(
                  premium ? Icons.favorite_rounded : Icons.play_circle_rounded,
                ),
                label: Text(
                  premium
                      ? l10n.home_streakRestoreFree
                      : l10n.home_streakRestoreWatch,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
