import 'package:flutter/material.dart';
import 'package:lingua/design/theme/app_component_themes.dart';
import 'package:lingua/design/theme/styles/app_color_tokens.dart';
import 'package:lingua/design/theme/styles/app_text_styles.dart';
import 'package:lingua/design/theme/theme_notifier.dart';

abstract class AppTheme {
  /// Resolve theme từ variant (light/dark/red/green/...).
  static ThemeData fromVariant(AppThemeVariant variant) {
    final tokens = switch (variant) {
      AppThemeVariant.light => AppColorTokens.light(),
      AppThemeVariant.dark => AppColorTokens.dark(),
      AppThemeVariant.green => AppColorTokens.green(),
    };
    final brightness = variant == AppThemeVariant.dark
        ? Brightness.dark
        : Brightness.light;
    return _build(tokens, brightness);
  }

  static ThemeData light([AppColorTokens? tokens]) =>
      _build(tokens ?? AppColorTokens.light(), Brightness.light);

  static ThemeData dark([AppColorTokens? tokens]) =>
      _build(tokens ?? AppColorTokens.dark(), Brightness.dark);

  static ThemeData _build(AppColorTokens t, Brightness brightness) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: t.toColorScheme(brightness),
      textTheme: AppTextStyles.theme(t),
      extensions: [t],
    );
    return AppComponentThemes.apply(base, t);
  }
}
