import 'package:flutter/material.dart';
import 'package:lingua/core/di/global_providers.dart';
import 'package:lingua/design/theme/app_palette.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'theme_notifier.g.dart';

/// Giao diện người dùng chọn: sáng / tối / theo hệ thống + màu chủ đạo.
class ThemeSettings {
  const ThemeSettings({
    this.mode = ThemeMode.system,
    this.accent = AppAccent.indigo,
  });

  final ThemeMode mode;
  final AppAccent accent;
}

@Riverpod(keepAlive: true)
class ThemeNotifier extends _$ThemeNotifier {
  static const _modeKey = 'theme_mode';
  static const _accentKey = 'theme_accent';

  @override
  ThemeSettings build() {
    final prefs = ref.read(sharedPrefsProvider);
    return ThemeSettings(
      mode:
          ThemeMode.values.asNameMap()[prefs.getString(_modeKey)] ??
          ThemeMode.system,
      accent:
          AppAccent.values.asNameMap()[prefs.getString(_accentKey)] ??
          AppAccent.indigo,
    );
  }

  Future<void> setMode(ThemeMode mode) async {
    state = ThemeSettings(mode: mode, accent: state.accent);
    await ref.read(sharedPrefsProvider).setString(_modeKey, mode.name);
  }

  Future<void> setAccent(AppAccent accent) async {
    state = ThemeSettings(mode: state.mode, accent: accent);
    await ref.read(sharedPrefsProvider).setString(_accentKey, accent.name);
  }
}
