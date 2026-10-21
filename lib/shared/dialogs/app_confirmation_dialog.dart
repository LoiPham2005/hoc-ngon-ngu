import 'package:flutter/material.dart';

class AppConfirmationDialog extends StatelessWidget {
  const AppConfirmationDialog({
    required this.title,
    super.key,
    this.message,
    this.confirmText = 'Đồng ý',
    this.cancelText = 'Huỷ',
    this.destructive = false,
  });

  final String title;
  final String? message;
  final String confirmText;
  final String cancelText;
  final bool destructive;

  static Future<bool> show(
    BuildContext context, {
    required String title,
    String? message,
    String confirmText = 'Đồng ý',
    String cancelText = 'Huỷ',
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
          child: Text(cancelText),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: color == null
              ? null
              : FilledButton.styleFrom(backgroundColor: color),
          child: Text(confirmText),
        ),
      ],
    );
  }
}
