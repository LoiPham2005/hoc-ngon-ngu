import 'package:flutter/material.dart';
import 'package:lingua/design/l10n/l10n_extensions.dart';
import 'package:lingua/shared/states/state_view.dart';

/// Không có dữ liệu (danh sách rỗng, tìm không thấy…).
class EmptyWidget extends StatelessWidget {
  const EmptyWidget({
    super.key,
    this.title,
    this.message,
    this.icon = Icons.inbox_outlined,
    this.action,
  });

  /// `null` → "Không có dữ liệu" theo ngôn ngữ app.
  final String? title;
  final String? message;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) => StateView(
    icon: icon,
    title: title ?? context.l10n.common_empty,
    message: message,
    action: action,
  );
}
