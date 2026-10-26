import 'package:flutter/material.dart';
import 'package:lingua/design/theme/styles/app_dimensions.dart';

enum StateTone { neutral, error }

/// Khung chung cho màn trạng thái (trống / lỗi): icon trong vòng tròn màu nhạt, tiêu đề, mô tả,
/// nút hành động — cùng cỡ, khoảng cách, màu theo theme ở mọi nơi (sáng / tối).
/// Chỗ hẹp (vd 1 ô nhỏ trong danh sách bị lỗi) tự rút gọn chỉ còn icon.
class StateView extends StatelessWidget {
  const StateView({
    required this.icon,
    required this.title,
    super.key,
    this.message,
    this.details,
    this.action,
    this.tone = StateTone.neutral,
  });

  final IconData icon;
  final String title;
  final String? message;

  /// Nội dung kỹ thuật (vd lỗi khi debug): khung chữ đơn cách, chọn / copy được.
  final String? details;
  final Widget? action;
  final StateTone tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final (background, foreground) = switch (tone) {
      StateTone.neutral => (
        scheme.surfaceContainerHighest,
        scheme.onSurfaceVariant,
      ),
      StateTone.error => (scheme.errorContainer, scheme.onErrorContainer),
    };
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 160 || constraints.maxHeight < 160) {
          return Center(
            child: Icon(
              icon,
              color: tone == StateTone.error
                  ? scheme.error
                  : scheme.onSurfaceVariant,
            ),
          );
        }
        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.space24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: background,
                      shape: BoxShape.circle,
                    ),
                    child: SizedBox.square(
                      dimension: 88,
                      child: Icon(icon, size: 40, color: foreground),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space24),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (message case final message?) ...[
                    const SizedBox(height: AppDimensions.space8),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ],
                  if (details case final details?) ...[
                    const SizedBox(height: AppDimensions.space16),
                    Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxHeight: 180),
                      padding: const EdgeInsets.all(AppDimensions.space12),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SingleChildScrollView(
                        child: SelectableText(
                          details,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ],
                  if (action case final action?) ...[
                    const SizedBox(height: AppDimensions.space24),
                    action,
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
