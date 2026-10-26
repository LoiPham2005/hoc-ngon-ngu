import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingua/core/di/global_providers.dart';
import 'package:lingua/core/services/sound_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('every sound effect has a bundled audio file', () {
    for (final sfx in Sfx.values) {
      expect(
        File('assets/sounds/${sfx.name}.wav').existsSync(),
        isTrue,
        reason: sfx.name,
      );
    }
  });

  test(
    'answer sounds are on by default and the choice is remembered',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      ProviderContainer container() {
        final c = ProviderContainer(
          overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
        );
        addTearDown(c.dispose);
        return c;
      }

      final c = container();
      expect(c.read(soundEnabledProvider), isTrue);
      await c.read(soundEnabledProvider.notifier).set(enabled: false);
      expect(container().read(soundEnabledProvider), isFalse);
      // Tắt / môi trường test → phát âm thanh không lỗi, không làm gì.
      await c.read(soundServiceProvider).answer(correct: true);
    },
  );
}
