import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingua/shared/base/app_button.dart';

import '../../../helpers/pump_app.dart';

void main() {
  group('AppButton', () {
    testWidgets('shows label', (tester) async {
      await pumpApp(tester, const AppButton(label: 'Tap me', onPressed: null));
      expect(find.text('Tap me'), findsOneWidget);
    });

    testWidgets('fires onPressed', (tester) async {
      var taps = 0;
      await pumpApp(tester, AppButton(label: 'Tap', onPressed: () => taps++));
      await tester.tap(find.text('Tap'));
      expect(taps, 1);
    });

    testWidgets('shows spinner when isLoading', (tester) async {
      await pumpApp(
        tester,
        const AppButton(label: 'Loading', onPressed: null, isLoading: true),
        settle: false, // spinner animate vô hạn → không pumpAndSettle
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
