import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingua/core/services/connectivity_provider.dart';
import 'package:lingua/design/theme/app_theme.dart';
import 'package:lingua/gen/l10n/app_localizations.dart';
import 'package:lingua/shared/states/connectivity_banner.dart';

void main() {
  late StreamController<bool> status;

  setUp(() => status = StreamController<bool>());
  tearDown(() => status.close());

  Future<void> pumpBanner(WidgetTester tester) => tester.pumpWidget(
    ProviderScope(
      overrides: [isOnlineProvider.overrideWith((ref) => status.stream)],
      child: MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => ConnectivityBanner(child: child!),
        home: const Scaffold(body: Text('content')),
      ),
    ),
  );

  testWidgets('online from start: no banner', (tester) async {
    await pumpBanner(tester);
    status.add(true);
    await tester.pumpAndSettle();

    expect(find.text('Không có kết nối mạng'), findsNothing);
    expect(find.text('Đã kết nối lại'), findsNothing);
    expect(find.text('content'), findsOneWidget);
  });

  testWidgets(
    'offline → shows banner; back online → "reconnected" then hides',
    (tester) async {
      await pumpBanner(tester);
      status.add(false);
      await tester.pumpAndSettle();
      expect(find.text('Không có kết nối mạng'), findsOneWidget);

      status.add(true);
      await tester.pumpAndSettle();
      expect(find.text('Không có kết nối mạng'), findsNothing);
      expect(find.text('Đã kết nối lại'), findsOneWidget);

      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(find.text('Đã kết nối lại'), findsNothing);
    },
  );
}
