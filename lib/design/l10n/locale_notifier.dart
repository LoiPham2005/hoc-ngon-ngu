import 'dart:ui';

import 'package:lingua/core/di/global_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'locale_notifier.g.dart';

@Riverpod(keepAlive: true)
class LocaleNotifier extends _$LocaleNotifier {
  static const String defaultLocale = 'vi';
  static const _key = 'app_locale';

  @override
  Locale build() {
    final storage = ref.read(sharedPrefsProvider);
    final raw = storage.getString(_key);
    if (raw != null && raw.isNotEmpty) return Locale(raw);
    return const Locale(defaultLocale);
  }

  Future<void> set(Locale locale) async {
    state = locale;
    final storage = ref.read(sharedPrefsProvider);
    await storage.setString(_key, locale.languageCode);
  }
}
