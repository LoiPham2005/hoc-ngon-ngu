import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingua/features/practice/practice_page.dart';

import '../../helpers/pump_app.dart';

void main() {
  testWidgets('Luyện tập → Hiragana → chọn Âm cơ bản / Âm đục / Cả hai', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpApp(tester, const PracticePage());

    await tester.tap(find.text('Hiragana'));
    await tester.pumpAndSettle();
    expect(find.text('Luyện phần nào?'), findsOneWidget);
    expect(find.textContaining('46 chữ'), findsOneWidget);
    expect(find.textContaining('25 chữ'), findsOneWidget);
    expect(find.textContaining('71 chữ'), findsOneWidget);

    // Kana tổng hợp = 2 bảng → gấp đôi số chữ.
    await tester.tapAt(const Offset(10, 10)); // đóng sheet
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kana tổng hợp'));
    await tester.pumpAndSettle();
    expect(find.textContaining('142 chữ'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
