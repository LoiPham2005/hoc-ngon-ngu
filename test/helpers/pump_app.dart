import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingua/core/di/global_providers.dart';
import 'package:lingua/design/l10n/locale_notifier.dart';
import 'package:lingua/design/theme/app_palette.dart';
import 'package:lingua/design/theme/app_theme.dart';
import 'package:lingua/gen/l10n/app_localizations.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pump widget với ProviderScope (SharedPreferences giả) + MaterialApp (theme + l10n).
///
/// [settle]: `false` khi màn có animation vô hạn (spinner) — `pumpAndSettle` sẽ timeout.
/// [prefs]: giá trị SharedPreferences ban đầu (vd tiến độ học).
Future<void> pumpApp(
  WidgetTester tester,
  Widget child, {
  List<Override> overrides = const [],
  ThemeMode themeMode = ThemeMode.light,
  Locale locale = const Locale('vi'),
  Map<String, Object> prefs = const {},
  bool settle = true,
}) async {
  // rootBundle giữ Future đọc asset của test trước (vùng giờ giả đã chết) → xoá để đọc lại.
  rootBundle.clear();
  SharedPreferences.setMockInitialValues({
    'app_locale': locale.languageCode,
    ...prefs,
  });
  final sharedPrefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(sharedPrefs),
        ...overrides,
      ],
      child: Consumer(
        builder: (context, ref, _) => MaterialApp(
          theme: AppTheme.build(AppAccent.indigo, Brightness.light),
          darkTheme: AppTheme.build(AppAccent.indigo, Brightness.dark),
          themeMode: themeMode,
          locale: ref.watch(localeProvider),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: child,
        ),
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

/// Chờ 1 provider đọc asset (I/O thật — giờ giả lập của widget test không tự chạy nó).
Future<void> loadAsset(
  WidgetTester tester,
  Future<Object?> Function(ProviderContainer container) read,
) async {
  final container = ProviderScope.containerOf(
    tester.element(find.byType(MaterialApp)),
  );
  // Future do màn tạo trong vùng giờ giả → phải xen kẽ chờ I/O thật (runAsync) và pump
  // để chạy tiếp callback của nó; chỉ `runAsync(read)` thì treo mãi.
  var done = false;
  unawaited(
    read(
      container,
    ).then<void>((_) => done = true, onError: (Object _) => done = true),
  );
  for (var i = 0; i < 200 && !done; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump();
  }
}
