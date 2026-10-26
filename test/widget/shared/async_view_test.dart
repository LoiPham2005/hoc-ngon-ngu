import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingua/gen/l10n/app_localizations.dart';
import 'package:lingua/shared/states/async_view.dart';
import 'package:lingua/shared/states/empty_widget.dart';
import 'package:lingua/shared/states/error_retry.dart';
import 'package:lingua/shared/states/loading_widget.dart';

Widget _host(
  AsyncValue<List<String>> state, {
  VoidCallback? onRetry,
  Future<void> Function()? onRefresh,
}) {
  return MaterialApp(
    locale: const Locale('vi'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: AsyncView<List<String>>(
        state: state,
        onRetry: onRetry,
        onRefresh: onRefresh,
        emptyTitle: 'Trống',
        builder: (context, list) =>
            ListView(children: [for (final s in list) Text(s)]),
      ),
    ),
  );
}

void main() {
  testWidgets('loading → LoadingWidget', (tester) async {
    await tester.pumpWidget(_host(const AsyncLoading<List<String>>()));
    expect(find.byType(LoadingWidget), findsOneWidget);
  });

  testWidgets('data → builder', (tester) async {
    await tester.pumpWidget(_host(const AsyncData<List<String>>(['a', 'b'])));
    expect(find.text('a'), findsOneWidget);
    expect(find.text('b'), findsOneWidget);
  });

  testWidgets('empty list → EmptyWidget', (tester) async {
    await tester.pumpWidget(_host(const AsyncData<List<String>>([])));
    expect(find.byType(EmptyWidget), findsOneWidget);
    expect(find.text('Trống'), findsOneWidget);
  });

  testWidgets('error → ErrorRetry, nút Thử lại gọi onRetry', (tester) async {
    var retried = false;
    await tester.pumpWidget(
      _host(
        AsyncError<List<String>>('boom', StackTrace.current),
        onRetry: () => retried = true,
      ),
    );
    expect(find.byType(ErrorRetry), findsOneWidget);
    expect(find.text('boom'), findsOneWidget);

    await tester.tap(find.text('Thử lại'));
    expect(retried, isTrue);
  });

  testWidgets('retrying after an error → spinner on a locked retry button', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      _host(
        // ignore: invalid_use_of_internal_member
        const AsyncLoading<List<String>>().copyWithPrevious(
          const AsyncError<List<String>>('boom', StackTrace.empty),
        ),
        onRetry: () => taps++,
      ),
    );
    expect(find.byType(ErrorRetry), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(FilledButton),
        matching: find.byType(CircularProgressIndicator),
      ),
      findsOneWidget,
    );
    await tester.tap(find.byType(FilledButton));
    expect(taps, 0);
  });

  testWidgets('onRefresh bọc RefreshIndicator', (tester) async {
    await tester.pumpWidget(
      _host(const AsyncData<List<String>>(['a']), onRefresh: () async {}),
    );
    expect(find.byType(RefreshIndicator), findsOneWidget);
  });

  testWidgets('không onRefresh → không có RefreshIndicator', (tester) async {
    await tester.pumpWidget(_host(const AsyncData<List<String>>(['a'])));
    expect(find.byType(RefreshIndicator), findsNothing);
  });
}
