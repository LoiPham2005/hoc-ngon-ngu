import 'package:flutter/material.dart';
import 'package:lingua/design/l10n/l10n_extensions.dart';
import 'package:lingua/design/theme/styles/app_dimensions.dart';

class ErrorRetry extends StatelessWidget {
  const ErrorRetry({
    super.key,
    this.message,
    this.onRetry,
    this.icon = Icons.error_outline,
  });

  /// `null` → "Đã xảy ra lỗi" theo ngôn ngữ app.
  final String? message;
  final VoidCallback? onRetry;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: t.colorScheme.error),
            const SizedBox(height: AppDimensions.space16),
            Text(
              message ?? context.l10n.common_error,
              textAlign: TextAlign.center,
              style: t.textTheme.bodyMedium,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppDimensions.space16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(context.l10n.common_retry),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
