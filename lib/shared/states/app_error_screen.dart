import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lingua/gen/l10n/app_localizations.dart';
import 'package:lingua/routes/app_router.dart';
import 'package:lingua/shared/states/state_view.dart';

/// Thay `ErrorWidget.builder` mặc định (màn đỏ debug / ô xám release): debug hiện nội dung lỗi,
/// release hiện câu chung + nút về màn đầu. Chỗ hẹp (1 ô nhỏ bị lỗi) tự rút gọn chỉ còn icon.
///
/// Không được tự lỗi (nếu lỗi → Flutter lại dựng màn này → lặp vô hạn): không đọc provider,
/// thiếu theme / ngôn ngữ thì dùng mặc định.
class AppErrorScreen extends StatelessWidget {
  const AppErrorScreen({required this.details, super.key});

  final FlutterErrorDetails details;

  @override
  Widget build(BuildContext context) {
    final l10n =
        Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        lookupAppLocalizations(const Locale('en'));
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: StateView(
          icon: Icons.error_outline_rounded,
          tone: StateTone.error,
          title: l10n.common_error,
          message: l10n.error_unexpected,
          details: kDebugMode ? details.exceptionAsString() : null,
          action: FilledButton.icon(
            onPressed: () => appRouter.replaceAll([const SplashRoute()]),
            icon: const Icon(Icons.home_rounded),
            label: Text(l10n.error_backHome),
          ),
        ),
      ),
    );
  }
}
