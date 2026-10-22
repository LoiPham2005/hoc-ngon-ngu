import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingua/design/theme/app_colors.dart';
import 'package:lingua/features/course/providers/learner_notifier.dart';

/// Số mục đã thuộc trong [keys].
int learnedCount(WidgetRef ref, Iterable<String> keys) {
  final learned = ref.watch(learnerProvider.select((l) => l.learned));
  return keys.where(learned.contains).length;
}

/// Nút ✓ bật/tắt "đã thuộc" cho 1 mục (từ, câu, âm).
class LearnedToggle extends ConsumerWidget {
  const LearnedToggle(this.learnedKey, {super.key});

  final String learnedKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final learned = ref.watch(
      learnerProvider.select((l) => l.learned.contains(learnedKey)),
    );
    final colors = context.colors;
    return IconButton(
      onPressed: () =>
          ref.read(learnerProvider.notifier).toggleLearned(learnedKey),
      icon: Icon(
        learned ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
        color: learned ? colors.success : colors.border,
      ),
    );
  }
}

/// Nhãn nhỏ bo tròn (loại từ, cấp…).
class Tag extends StatelessWidget {
  const Tag(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: context.colors.primarySoft,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.labelSmall?.copyWith(color: context.colors.primary),
    ),
  );
}
