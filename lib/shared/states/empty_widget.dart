import 'package:flutter/material.dart';
import 'package:lingua/design/theme/styles/app_dimensions.dart';

class EmptyWidget extends StatelessWidget {
  const EmptyWidget({
    super.key,
    this.title = 'Không có dữ liệu',
    this.message,
    this.icon = Icons.inbox_outlined,
    this.action,
  });

  final String title;
  final String? message;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: t.colorScheme.outline),
            const SizedBox(height: AppDimensions.space16),
            Text(title, style: t.textTheme.titleMedium),
            if (message != null) ...[
              const SizedBox(height: AppDimensions.space8),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: t.textTheme.bodyMedium?.copyWith(
                  color: t.colorScheme.outline,
                ),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: AppDimensions.space16),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
