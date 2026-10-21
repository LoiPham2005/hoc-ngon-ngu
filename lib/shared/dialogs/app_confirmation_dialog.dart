import 'package:flutter/material.dart';
import 'package:lingua/design/l10n/l10n_extensions.dart';

class AppConfirmationDialog extends StatelessWidget {
  const AppConfirmationDialog({
    required this.title,
    super.key,
    this.message,
    this.confirmText,
    this.cancelText,
    this.destructive = false,
  });

  final String title;
  final String? message;

  /// `null` → "Đồng ý" / "Huỷ" theo ngôn ngữ app.
  final String? confirmText;
  final String? cancelText;
  final bool destructive;

  static Future<bool> show(
    BuildContext context, {
    required String title,
    String? message,
    String? confirmText,
    String? cancelText,
    bool destructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AppConfirmationDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        destructive: destructive,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final color = destructive ? Theme.of(context).colorScheme.error : null;
    return AlertDialog(
      title: Text(title),
      content: message == null ? null : Text(message!),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelText ?? context.l10n.common_cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: color == null
              ? null
              : FilledButton.styleFrom(backgroundColor: color),
          child: Text(confirmText ?? context.l10n.common_ok),
        ),
      ],
    );
  }
}
