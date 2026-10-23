import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingua/core/services/permission_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('flutter.baseflow.com/permissions/methods');
  // Giá trị trạng thái của permission_handler: 0 denied, 1 granted, 4 permanentlyDenied.
  late int current;
  late int afterRequest;
  late List<String> calls;

  setUp(() {
    calls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call.method);
          return switch (call.method) {
            'checkPermissionStatus' => current,
            'requestPermissions' => {
              for (final p in call.arguments as List) p as int: afterRequest,
            },
            _ => true,
          };
        });
  });

  test('already granted → no system dialog', () async {
    current = 1;
    expect(
      await PermissionService().request(AppPermission.notification),
      PermissionResult.granted,
    );
    expect(calls, isNot(contains('requestPermissions')));
  });

  test('not yet asked → asks the system, user allows', () async {
    current = 0;
    afterRequest = 1;
    expect(
      await PermissionService().request(AppPermission.microphone),
      PermissionResult.granted,
    );
    expect(calls, contains('requestPermissions'));
  });

  test(
    'user refuses → denied; refused for good → blocked (open Settings)',
    () async {
      current = 0;
      afterRequest = 0;
      expect(
        await PermissionService().request(AppPermission.notification),
        PermissionResult.denied,
      );
      afterRequest = 4;
      expect(
        await PermissionService().request(AppPermission.notification),
        PermissionResult.blocked,
      );
    },
  );

  test('location always: stops if "while using" is refused', () async {
    current = 0;
    afterRequest = 0;
    final requested = <List<int>>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'requestPermissions') {
            requested.add((call.arguments as List).cast<int>());
            return {for (final p in call.arguments as List) p as int: 0};
          }
          return 0;
        });
    expect(
      await PermissionService().request(AppPermission.locationAlways),
      PermissionResult.denied,
    );
    expect(requested, hasLength(1)); // không hỏi tiếp "luôn luôn"
  });
}
