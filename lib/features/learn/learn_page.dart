import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingua/design/l10n/l10n_extensions.dart';
import 'package:lingua/features/course/models/course_model.dart';
import 'package:lingua/features/course/providers/learner_notifier.dart';
import 'package:lingua/features/course/widgets/module_card.dart';
import 'package:lingua/modules/ads/ad_config.dart';
import 'package:lingua/modules/ads/widgets/native_ad_widget.dart';
import 'package:lingua/routes/app_router.dart';
import 'package:lingua/shared/base/app_ui.dart';

/// Khoá học: các học phần của ngôn ngữ đang học, kèm tiến độ.
@RoutePage()
class LearnPage extends ConsumerWidget {
  const LearnPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final course =
        ref.watch(learnerProvider.select((l) => l.course)) ?? Course.ja;
    final l10n = context.l10n;
    final modules = course.modules;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.learn_title),
        actions: [
          IconButton(
            tooltip: l10n.search_title,
            icon: const Icon(Icons.search_rounded),
            onPressed: () => context.router.push(const SearchRoute()),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Chip(
              avatar: Text(course.flag),
              label: Text(course.title(context)),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          for (final (i, section) in ModuleSection.values.indexed)
            if (modules.where((m) => m.section == section).toList()
                case final group when group.isNotEmpty) ...[
              SectionTitle(section.title(context)),
              for (final m in group) ...[
                ModuleCard(m),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 2),
              if (i == 0)
                const NativeAdWidget(
                  placement: NativePlacement.list,
                  size: NativeAdSize.small,
                  padding: EdgeInsets.only(bottom: 12),
                ),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}
