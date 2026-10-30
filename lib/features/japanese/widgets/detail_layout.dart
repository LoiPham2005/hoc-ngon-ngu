import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingua/design/l10n/l10n_extensions.dart';
import 'package:lingua/design/theme/app_colors.dart';
import 'package:lingua/features/course/providers/learner_notifier.dart';
import 'package:lingua/features/japanese/widgets/writing_box.dart';
import 'package:lingua/modules/ads/ad_config.dart';
import 'package:lingua/modules/ads/widgets/native_ad_widget.dart';
import 'package:lingua/shared/base/app_ui.dart';
import 'package:lingua/shared/base/speak_button.dart';

/// Bố cục chung màn chi tiết Kana / Kanji:
/// thẻ chữ lớn + thông tin → nút "Đã thuộc" → thứ tự nét / tập viết → chữ trước / sau.
class DetailLayout extends ConsumerWidget {
  const DetailLayout({
    required this.title,
    required this.char,
    required this.color,
    required this.info,
    required this.chars,
    required this.onOpen,
    required this.speech,
    super.key,
  });

  final String title;
  final String char;
  final Color color;

  /// Thông tin bên phải chữ (cách đọc, nghĩa…).
  final Widget info;

  /// Các chữ cùng học phần (để chuyển trước / sau).
  final List<String> chars;
  final void Function(String char) onOpen;

  /// Nội dung đọc khi bấm 🔊 (Kana: chính chữ; Kanji: các âm On/Kun).
  final String speech;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final learned = ref.watch(
      learnerProvider.select((l) => l.learned.contains(char)),
    );
    final colors = context.colors;
    final l10n = context.l10n;
    final index = chars.indexOf(char);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      GlyphBadge(char, color: color, size: 92),
                      const SizedBox(width: 16),
                      Expanded(child: info),
                      SpeakButton(speech),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: () =>
                    ref.read(learnerProvider.notifier).toggleLearned(char),
                style: learned
                    ? FilledButton.styleFrom(
                        backgroundColor: colors.successSoft,
                        foregroundColor: colors.success,
                      )
                    : null,
                icon: Icon(
                  learned ? Icons.check_circle_rounded : Icons.add_task_rounded,
                ),
                label: Text(
                  learned ? l10n.detail_learned : l10n.detail_markLearned,
                ),
              ),
              const SizedBox(height: 14),
              Expanded(child: WritingPanel(char: char)),
              if (chars.length > 1)
                Row(
                  children: [
                    IconButton.filledTonal(
                      onPressed: index > 0
                          ? () => onOpen(chars[index - 1])
                          : null,
                      icon: const Icon(Icons.chevron_left_rounded),
                    ),
                    Expanded(
                      child: Text(
                        '${index + 1} / ${chars.length}',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    IconButton.filledTonal(
                      onPressed: index >= 0 && index < chars.length - 1
                          ? () => onOpen(chars[index + 1])
                          : null,
                      icon: const Icon(Icons.chevron_right_rounded),
                    ),
                  ],
                ),
              // Nhỏ: bảng viết (Expanded) phía trên vẫn đủ chỗ.
              const NativeAdWidget(
                placement: NativePlacement.detail,
                size: NativeAdSize.small,
                padding: EdgeInsets.only(top: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
