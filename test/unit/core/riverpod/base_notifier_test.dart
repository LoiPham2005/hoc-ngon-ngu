import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingua/core/errors/failures.dart';
import 'package:lingua/core/riverpod/base_notifier.dart';
import 'package:lingua/core/utils/logger.dart';
import 'package:talker_flutter/talker_flutter.dart';

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
    // build() không bao giờ xong → suốt lúc chạy vẫn chưa có data
    final pending = AsyncNotifierProvider<_PendingNotifier, List<int>>(
      _PendingNotifier.new,
    );
    final n = container.read(pending.notifier);
    await n.run(() async => throw const SocketException('x'));
    final s = container.read(pending);
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

  test('messages keep working after the provider rebuilds', () async {
    final n = await ready();
    final got = <String>[];
    n.messages.listen((m) => got.add(m.text));
    await n.run(() async => 1, successMessage: 'before');
    container.invalidate(_provider);
    await container.read(_provider.future);
    await container
        .read(_provider.notifier)
        .run(() async => 1, successMessage: 'after');
    await Future<void>.delayed(Duration.zero);
    expect(got, ['before', 'after']);
  });

  test(
    'nothing to update while in error → back to the error, not stuck loading',
    () async {
      final c = ProviderContainer(retry: (_, _) => null);
      addTearDown(c.dispose);
      final p = AsyncNotifierProvider<_FailingNotifier, List<int>>(
        _FailingNotifier.new,
      );
      c.listen(p, (_, _) {});
      await Future<void>.delayed(Duration.zero);
      expect(c.read(p).hasError, isTrue);

      final n = c.read(p.notifier);
      await n.run(() async => 'not a list');
      expect(c.read(p).isLoading, isFalse);
      expect(c.read(p).hasError, isTrue);

      await n.run(() async => 5, apply: (list, r) => [...list, r]);
      expect(c.read(p).isLoading, isFalse);
    },
  );
  test(
    'a failing run does not overwrite data a parallel run just loaded',
    () async {
      final n = await ready();
      final failing = n.run<void>(() async {
        await Future<void>.delayed(const Duration(milliseconds: 30));
        throw Exception('delete failed');
      });
      await n.run(() async => [9]); // làm mới xong trước
      await failing;
      expect(value(), [9]);
      expect(container.read(_provider).isLoading, isFalse);
    },
  );

  test('expected failures are warnings, unexpected ones are errors', () async {
    final n = await ready();
    LogLevel? last() => talker.history.last.logLevel;

    await n.run<void>(() async => throw const NetworkFailure());
    expect(last(), LogLevel.warning);

    await n.run<void>(() async => throw const ServerFailure('boom', code: 500));
    expect(last(), LogLevel.error);
  });

  test(
    'a run started before the provider rebuilt does not overwrite it',
    () async {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final p = AsyncNotifierProvider<_FilteredNotifier, List<int>>(
        _FilteredNotifier.new,
      );
      c.listen(p, (_, _) {});
      await c.read(p.future);
      final stale = c.read(p.notifier).run(() async {
        await Future<void>.delayed(const Duration(milliseconds: 30));
        return [-1]; // kết quả cho bộ lọc cũ
      });
      c.read(_filter.notifier).set(2); // đổi bộ lọc → provider build lại
      await c.read(p.future);

      expect(await stale, isFalse);
      expect(c.read(p).value, [2]);
    },
  );

  test(
    'void action keeps a nullable state; a declared null result clears it',
    () async {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final p = AsyncNotifierProvider<_UserNotifier, String?>(
        _UserNotifier.new,
      );
      await c.read(p.future);
      final n = c.read(p.notifier);

      await n.run<void>(() async {}); // vd đổi mật khẩu
      expect(c.read(p).value, 'user');

      await n.run<String?>(() async => null); // vd /me trả về chưa đăng nhập
      expect(c.read(p).value, isNull);
    },
  );

  test('loading stays on until the last parallel run finishes', () async {
    final n = await ready();
    final slow = n.run(() async {
      await Future<void>.delayed(const Duration(milliseconds: 30));
      return [1];
    });
    await n.run(() async => [2]); // xong trước
    expect(container.read(_provider).isLoading, isTrue);
    expect(value(), [2]);
    await slow;
    expect(container.read(_provider).isLoading, isFalse);
    expect(value(), [1]);
  });

  test('a superseded run finishing last does not leave loading on', () async {
    final n = await ready();
    final old = n.run(() async {
      await Future<void>.delayed(const Duration(milliseconds: 30));
      return [1];
    }, cancelPrevious: true);
    await n.run(() async => [2], cancelPrevious: true);
    expect(container.read(_provider).isLoading, isFalse);
    await old;
    expect(container.read(_provider).isLoading, isFalse);
    expect(value(), [2]);
  });
}

class _FailingNotifier extends AsyncNotifier<List<int>>
    with BaseNotifier<List<int>> {
  @override
  Future<List<int>> build() async => throw Exception('load failed');
}

class _PendingNotifier extends AsyncNotifier<List<int>>
    with BaseNotifier<List<int>> {
  @override
  Future<List<int>> build() => Completer<List<int>>().future;
}

class _Filter extends Notifier<int> {
  @override
  int build() => 1;
  void set(int v) => state = v;
}

final _filter = NotifierProvider<_Filter, int>(_Filter.new);

class _FilteredNotifier extends AsyncNotifier<List<int>>
    with BaseNotifier<List<int>> {
  @override
  Future<List<int>> build() async => [ref.watch(_filter)];
}

class _UserNotifier extends AsyncNotifier<String?> with BaseNotifier<String?> {
  @override
  Future<String?> build() async => 'user';
}
