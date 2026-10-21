import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingua/core/network/api_client_provider.dart';
import 'package:lingua/design/theme/app_theme.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

/// Pump a widget với ProviderScope + Material wrapper.
/// Override providers qua `overrides`.
///
/// [settle]: mặc định `true` → `pumpAndSettle()` đợi mọi animation xong.
/// Đặt `false` khi widget có **animation vô hạn** (spinner/loading indicator) —
/// `pumpAndSettle` sẽ timeout vì không bao giờ settle; dùng 1 `pump()` thay thế.
Future<void> pumpApp(
  WidgetTester tester,
  Widget child, {
  List<Override> overrides = const [],
  ThemeMode themeMode = ThemeMode.light,
  bool settle = true,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [...apiClientOverrides, ...overrides],
      child: MaterialApp(
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: themeMode,
        home: child,
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}
