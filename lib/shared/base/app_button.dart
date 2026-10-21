import 'package:flutter/material.dart';
import 'package:lingua/design/theme/styles/app_dimensions.dart';

enum AppButtonVariant { filled, outlined, text }

enum AppButtonSize { sm, md, lg }

class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.variant = AppButtonVariant.filled,
    this.size = AppButtonSize.md,
    this.icon,
    this.isLoading = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? icon;
  final bool isLoading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final height = switch (size) {
      AppButtonSize.sm => AppDimensions.buttonHeightSm,
      AppButtonSize.md => AppDimensions.buttonHeightMd,
      AppButtonSize.lg => AppDimensions.buttonHeightLg,
    };

    final content = isLoading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: AppDimensions.iconMd),
                const SizedBox(width: AppDimensions.space8),
              ],
              Text(label),
            ],
          );

    final disabled = isLoading || onPressed == null;
    final handler = disabled ? null : onPressed;

    final btn = switch (variant) {
      AppButtonVariant.filled => ElevatedButton(
        onPressed: handler,
        style: ElevatedButton.styleFrom(minimumSize: Size.fromHeight(height)),
        child: content,
      ),
      AppButtonVariant.outlined => OutlinedButton(
        onPressed: handler,
        style: OutlinedButton.styleFrom(minimumSize: Size.fromHeight(height)),
        child: content,
      ),
      AppButtonVariant.text => TextButton(
        onPressed: handler,
        style: TextButton.styleFrom(minimumSize: Size.fromHeight(height)),
        child: content,
      ),
    };

    return expand ? SizedBox(width: double.infinity, child: btn) : btn;
  }
}
