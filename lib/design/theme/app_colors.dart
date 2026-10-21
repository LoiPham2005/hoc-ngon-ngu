import 'package:flutter/material.dart';
import 'package:lingua/design/theme/app_palette.dart';

/// Bộ màu theo theme hiện tại (màu chủ đạo + sáng/tối). Đọc: `context.colors.primary`.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.primary,
    required this.primarySoft,
    required this.onPrimary,
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.border,
    required this.text,
    required this.textMuted,
    required this.success,
    required this.successSoft,
    required this.error,
    required this.errorSoft,
    required this.warning,
    required this.streak,
  });

  factory AppColors.of(AppAccent accent, Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final primary = dark ? accent.dark : accent.light;
    final surface = dark ? AppPalette.darkSurface : AppPalette.lightSurface;
    Color soft(Color c) => Color.alphaBlend(c.withValues(alpha: 0.14), surface);
    return AppColors(
      primary: primary,
      primarySoft: soft(primary),
      onPrimary: AppPalette.onAccent,
      background: dark ? AppPalette.darkBackground : AppPalette.lightBackground,
      surface: surface,
      surfaceAlt: dark ? AppPalette.darkSurfaceAlt : AppPalette.lightSurfaceAlt,
      border: dark ? AppPalette.darkBorder : AppPalette.lightBorder,
      text: dark ? AppPalette.darkText : AppPalette.lightText,
      textMuted: dark ? AppPalette.darkTextMuted : AppPalette.lightTextMuted,
      success: AppPalette.success,
      successSoft: soft(AppPalette.success),
      error: AppPalette.error,
      errorSoft: soft(AppPalette.error),
      warning: AppPalette.warning,
      streak: AppPalette.streak,
    );
  }

  final Color primary;

  /// Nền nhạt của màu chủ đạo (chip, ô đã thuộc, thẻ được chọn).
  final Color primarySoft;
  final Color onPrimary;
  final Color background;
  final Color surface;
  final Color surfaceAlt;
  final Color border;
  final Color text;
  final Color textMuted;
  final Color success;
  final Color successSoft;
  final Color error;
  final Color errorSoft;
  final Color warning;
  final Color streak;

  @override
  AppColors copyWith() => this;

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      primary: l(primary, other.primary),
      primarySoft: l(primarySoft, other.primarySoft),
      onPrimary: l(onPrimary, other.onPrimary),
      background: l(background, other.background),
      surface: l(surface, other.surface),
      surfaceAlt: l(surfaceAlt, other.surfaceAlt),
      border: l(border, other.border),
      text: l(text, other.text),
      textMuted: l(textMuted, other.textMuted),
      success: l(success, other.success),
      successSoft: l(successSoft, other.successSoft),
      error: l(error, other.error),
      errorSoft: l(errorSoft, other.errorSoft),
      warning: l(warning, other.warning),
      streak: l(streak, other.streak),
    );
  }
}

extension AppColorsX on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}
