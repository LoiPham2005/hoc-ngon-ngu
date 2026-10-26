import 'package:flutter/material.dart';
import 'package:lingua/design/l10n/l10n_extensions.dart';
import 'package:lingua/shared/states/state_view.dart';

/// Lỗi tải dữ liệu + nút "Thử lại": tiêu đề chung "Đã xảy ra lỗi", [message] = lý do cụ thể.
class ErrorRetry extends StatelessWidget {
  const ErrorRetry({
    super.key,
    this.message,
    this.onRetry,
    this.icon = Icons.error_outline_rounded,
  });

  final String? message;
  final VoidCallback? onRetry;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return StateView(
      icon: icon,
      tone: StateTone.error,
      title: l10n.common_error,
      message: message,
      action: onRetry == null
          ? null
          : FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(l10n.common_retry),
            ),
    );
  }
}
