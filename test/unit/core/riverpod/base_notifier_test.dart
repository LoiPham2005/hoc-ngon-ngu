import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingua/core/errors/failures.dart';
import 'package:lingua/core/riverpod/base_notifier.dart';

/// Notifier classic (non-codegen) chỉ để test mixin.
class _TestNotifier extends AsyncNotifier<List<int>>
    with BaseNotifier<List<int>> {
  @override
  Future<List<int>> build() async => const [];
}

final _provider = AsyncNotifierProvider<_TestNotifier, List<int>>(
  _TestNotifier.new,
);

void main() {
  late ProviderContainer container;

  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  Future<_TestNotifier> ready() async {
    await container.read(_provider.future);
    return container.read(_provider.notifier);
  }

  List<int>? value() => container.read(_provider).value;

  test('kết quả kiểu T → thay state', () async {
    final n = await ready();
    final r = await n.run(() async => [1, 2, 3]);
    expect(r, true);
    expect(value(), [1, 2, 3]);
  });

  test('kết quả khác kiểu, không apply → giữ state', () async {
    final n = await ready();
    await n.run(() async => [1]);
    final r = await n.run(() async => 'ok');
    expect(r, true);
    expect(value(), [1]);
  });

  test('apply → sửa state tại chỗ', () async {
    final n = await ready();
    await n.run(() async => [1, 2]);
    await n.run(() async => 3, apply: (list, x) => [...list, x]);
    expect(value(), [1, 2, 3]);
  });

  test('đang loading vẫn giữ data cũ (không nháy trắng)', () async {
    final n = await ready();
    await n.run(() async => [1]);
    final c = Completer<List<int>>();
    final f = n.run(() => c.future);
    final loading = container.read(_provider);
    expect(loading.isLoading, true);
    expect(loading.value, [1]);
    c.complete([2]);
    await f;
    expect(value(), [2]);
  });

  test('silent → không đẩy loading', () async {
    final n = await ready();
    final c = Completer<List<int>>();
    final f = n.run(() => c.future, silent: true);
    expect(container.read(_provider).isLoading, false);
    c.complete([1]);
    await f;
  });

  test('lỗi khi đã có data → giữ data + phát RunMessage lỗi', () async {
    final n = await ready();
    await n.run(() async => [5]);
    final msgs = <RunMessage>[];
    final sub = n.messages.listen(msgs.add);
    final r = await n.run(
      () async => throw const SocketException('x'),
      errorMessage: 'Tải lỗi',
    );
    await Future<void>.delayed(Duration.zero);
    expect(r, false);
    expect(container.read(_provider).hasError, false);
    expect(value(), [5]);
    expect(msgs.single.failure, isA<NetworkFailure>());
    expect(msgs.single.text, startsWith('Tải lỗi: '));
    await sub.cancel();
  });

  test('lỗi khi chưa có data → AsyncError(Failure)', () async {
    final n = container.read(_provider.notifier);
    // build() chưa xong → chưa có data
    await n.run(() async => throw const SocketException('x'));
    final s = container.read(_provider);
    expect(s.hasError, true);
    expect(s.error, isA<NetworkFailure>());
  });

  test('successMessage → phát RunMessage thành công', () async {
    final n = await ready();
    final msgs = <RunMessage>[];
    final sub = n.messages.listen(msgs.add);
    await n.run(() async => [1], successMessage: 'Xong');
    await Future<void>.delayed(Duration.zero);
    expect(msgs.single.text, 'Xong');
    expect(msgs.single.isError, false);
    await sub.cancel();
  });

  test('cancelPrevious → bỏ kết quả lần gọi cũ về muộn', () async {
    final n = await ready();
    final c1 = Completer<List<int>>();
    final f1 = n.run(() => c1.future, cancelPrevious: true);
    final c2 = Completer<List<int>>();
    final f2 = n.run(() => c2.future, cancelPrevious: true);
    c2.complete([2]);
    await f2;
    c1.complete([1]);
    expect(await f1, false);
    expect(value(), [2]);
  });

  test('dropIfBusy → bỏ lần gọi khi đang chạy', () async {
    final n = await ready();
    final c = Completer<List<int>>();
    final f = n.run(() => c.future);
    expect(n.isBusy, true);
    expect(await n.run(() async => [9], dropIfBusy: true), false);
    c.complete([1]);
    await f;
    expect(value(), [1]);
    expect(n.isBusy, false);
  });
}
