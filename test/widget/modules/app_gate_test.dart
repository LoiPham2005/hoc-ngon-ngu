import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingua/core/services/app_version_service.dart';
import 'package:lingua/modules/app_config/app_config.dart';
import 'package:lingua/modules/app_config/app_gate.dart';
import 'package:lingua/modules/app_config/app_notice.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../helpers/pump_app.dart';

Future<void> _pumpGate(WidgetTester tester, AppConfig config) => pumpApp(
  tester,
  const AppGate(child: Text('app')),
  overrides: [
    appConfigProvider.overrideWithValue(config),
    packageInfoProvider.overrideWith(
      (ref) async => PackageInfo(
        appName: 'Lingua',
        packageName: 'com.loipham.lingua',
        version: '1.0.0',
        buildNumber: '1',
      ),
    ),
  ],
);

void main() {
  testWidgets('shows the app when nothing is blocking', (tester) async {
    await _pumpGate(tester, const AppConfig(minVersion: '1.0.0'));
    expect(find.text('app'), findsOneWidget);
  });

  testWidgets('maintenance hides the app and shows the message', (
    tester,
  ) async {
    await _pumpGate(
      tester,
      const AppConfig(maintenance: true, maintenanceMessage: 'Back at 10pm'),
    );
    expect(find.text('Back at 10pm'), findsOneWidget);
    expect(find.text('app'), findsNothing);
  });

  testWidgets('version below min_version must update', (tester) async {
    await _pumpGate(tester, const AppConfig(minVersion: '1.1.0'));
    expect(find.byIcon(Icons.system_update_rounded), findsOneWidget);
    expect(find.byType(FilledButton), findsOneWidget);
    expect(find.text('app'), findsNothing);
  });

  testWidgets('notice is shown once per content', (tester) async {
    await pumpApp(
      tester,
      Consumer(
        builder: (context, ref, _) => TextButton(
          onPressed: () => showAppNotice(context, ref),
          child: const Text('open'),
        ),
      ),
      overrides: [
        appConfigProvider.overrideWithValue(
          const AppConfig(noticeTitle: 'Sale'),
        ),
      ],
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Sale'), findsOneWidget);
    await tester.tap(find.byType(TextButton).last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Sale'), findsNothing);
  });
}
