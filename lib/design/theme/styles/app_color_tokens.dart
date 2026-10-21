import 'package:flutter/material.dart';
import 'package:theme_tailor_annotation/theme_tailor_annotation.dart';

part 'app_color_tokens.tailor.dart';

@TailorMixin()
class AppColorTokens extends ThemeExtension<AppColorTokens>
    with _$AppColorTokensTailorMixin {
  const AppColorTokens({
    required this.primary,
    required this.onPrimary,
    required this.secondary,
    required this.onSecondary,
    required this.surface,
    required this.onSurface,
    required this.surfaceVariant,
    required this.background,
    required this.onBackground,
    required this.error,
    required this.onError,
    required this.success,
    required this.warning,
    required this.info,
    required this.outline,
    required this.shadow,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.divider,
    required this.disabled,
    required this.red,
    required this.green,
  });

  factory AppColorTokens.light() => const AppColorTokens(
    primary: Color(0xFF6750A4),
    onPrimary: Color(0xFFFFFFFF),
    secondary: Color(0xFF625B71),
    onSecondary: Color(0xFFFFFFFF),
    surface: Color(0xFFFFFBFE),
    onSurface: Color(0xFF1C1B1F),
    surfaceVariant: Color(0xFFE7E0EC),
    background: Color(0xFFFFFBFE),
    onBackground: Color(0xFF1C1B1F),
    error: Color(0xFFB3261E),
    onError: Color(0xFFFFFFFF),
    success: Color(0xFF1B873F),
    warning: Color(0xFFD97706),
    info: Color(0xFF2563EB),
    outline: Color(0xFF79747E),
    shadow: Color(0xFF000000),
    textPrimary: Color(0xFF1C1B1F),
    textSecondary: Color(0xFF49454F),
    textTertiary: Color(0xFF79747E),
    divider: Color(0xFFE7E0EC),
    disabled: Color(0xFFC4C7C5),
    red: Color(0xFFDC2626),
    green: Color(0xFF16A34A),
  );

  /// 🌿 Green theme — primary xanh lá
  factory AppColorTokens.green() => const AppColorTokens(
    primary: Color(0xFF16A34A),
    onPrimary: Color(0xFFFFFFFF),
    secondary: Color(0xFF22C55E),
    onSecondary: Color(0xFFFFFFFF),
    surface: Color(0xFFF0FFF4),
    onSurface: Color(0xFF1C1B1F),
    surfaceVariant: Color(0xFFDCFCE7),
    background: Color(0xFFF0FFF4),
    onBackground: Color(0xFF1C1B1F),
    error: Color(0xFFB3261E),
    onError: Color(0xFFFFFFFF),
    success: Color(0xFF1B873F),
    warning: Color(0xFFD97706),
    info: Color(0xFF2563EB),
    outline: Color(0xFF86EFAC),
    shadow: Color(0xFF000000),
    textPrimary: Color(0xFF1C1B1F),
    textSecondary: Color(0xFF49454F),
    textTertiary: Color(0xFF79747E),
    divider: Color(0xFFBBF7D0),
    disabled: Color(0xFFC4C7C5),
    red: Color(0xFFDC2626),
    green: Color(0xFF16A34A),
  );

  factory AppColorTokens.dark() => const AppColorTokens(
    primary: Color(0xFFD0BCFF),
    onPrimary: Color(0xFF381E72),
    secondary: Color(0xFFCCC2DC),
    onSecondary: Color(0xFF332D41),
    surface: Color(0xFF1C1B1F),
    onSurface: Color(0xFFE6E1E5),
    surfaceVariant: Color(0xFF49454F),
    background: Color(0xFF1C1B1F),
    onBackground: Color(0xFFE6E1E5),
    error: Color(0xFFF2B8B5),
    onError: Color(0xFF601410),
    success: Color(0xFF4CAF50),
    warning: Color(0xFFFFA726),
    info: Color(0xFF42A5F5),
    outline: Color(0xFF938F99),
    shadow: Color(0xFF000000),
    textPrimary: Color(0xFFE6E1E5),
    textSecondary: Color(0xFFCAC4D0),
    textTertiary: Color(0xFF938F99),
    divider: Color(0xFF49454F),
    disabled: Color(0xFF4A4458),
    red: Color(0xFFF87171),
    green: Color(0xFF4ADE80),
  );

  @override
  final Color primary;
  @override
  final Color onPrimary;
  @override
  final Color secondary;
  @override
  final Color onSecondary;
  @override
  final Color surface;
  @override
  final Color onSurface;
  @override
  final Color surfaceVariant;
  @override
  final Color background;
  @override
  final Color onBackground;
  @override
  final Color error;
  @override
  final Color onError;
  @override
  final Color success;
  @override
  final Color warning;
  @override
  final Color info;
  @override
  final Color outline;
  @override
  final Color shadow;
  @override
  final Color textPrimary;
  @override
  final Color textSecondary;
  @override
  final Color textTertiary;
  @override
  final Color divider;
  @override
  final Color disabled;
  @override
  final Color red;
  @override
  final Color green;

  ColorScheme toColorScheme(Brightness brightness) => ColorScheme(
    brightness: brightness,
    primary: primary,
    onPrimary: onPrimary,
    secondary: secondary,
    onSecondary: onSecondary,
    error: error,
    onError: onError,
    surface: surface,
    onSurface: onSurface,
    outline: outline,
    shadow: shadow,
  );
}
