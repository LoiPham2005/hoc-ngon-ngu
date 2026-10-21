import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lingua/core/di/global_providers.dart';
import 'package:lingua/design/l10n/locale_notifier.dart';
import 'package:lingua/design/theme/app_palette.dart';
import 'package:lingua/gen/l10n/app_localizations.dart';
import 'package:lingua/routes/app_router.dart';

/// Thay `ErrorWidget.builder` mặc định: debug hiện exception, release hiện thông báo chung.
/// Không dùng `Theme.of` vì có thể lỗi xảy ra trước khi MaterialApp build xong.
class AppErrorScreen extends StatelessWidget {
  const AppErrorScreen({required this.details, super.key});

  final FlutterErrorDetails details;

  @override
  Widget build(BuildContext context) {
    final l10n = lookupAppLocalizations(globalContainer.read(localeProvider));
    return Material(
      color: AppPalette.lightBackground,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: AppPalette.error,
              ),
              const SizedBox(height: 16),
              SelectableText(
                kDebugMode
                    ? details.exceptionAsString()
                    : l10n.error_unexpected,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppPalette.lightText,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => appRouter.replaceAll([const SplashRoute()]),
                icon: const Icon(Icons.refresh_rounded),
                label: Text(l10n.error_backHome),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
