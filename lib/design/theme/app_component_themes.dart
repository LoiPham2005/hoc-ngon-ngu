import 'package:flutter/material.dart';
import 'package:lingua/design/theme/styles/app_color_tokens.dart';
import 'package:lingua/design/theme/styles/app_dimensions.dart';

abstract class AppComponentThemes {
  static ThemeData apply(ThemeData base, AppColorTokens t) => base.copyWith(
    appBarTheme: AppBarTheme(
      backgroundColor: t.surface,
      foregroundColor: t.onSurface,
      elevation: AppDimensions.elevation0,
      centerTitle: true,
      titleTextStyle: base.textTheme.titleLarge?.copyWith(color: t.textPrimary),
    ),
    scaffoldBackgroundColor: t.background,
    cardTheme: CardThemeData(
      color: t.surface,
      elevation: AppDimensions.elevation1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
      margin: EdgeInsets.zero,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: t.primary,
        foregroundColor: t.onPrimary,
        minimumSize: const Size.fromHeight(AppDimensions.buttonHeightMd),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        ),
        textStyle: base.textTheme.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: t.primary,
        side: BorderSide(color: t.primary),
        minimumSize: const Size.fromHeight(AppDimensions.buttonHeightMd),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: t.primary),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: t.surfaceVariant.withValues(alpha: 0.3),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space16,
        vertical: AppDimensions.space12,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        borderSide: BorderSide(color: t.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        borderSide: BorderSide(color: t.outline.withValues(alpha: 0.4)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        borderSide: BorderSide(color: t.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        borderSide: BorderSide(color: t.error),
      ),
    ),
    dividerTheme: DividerThemeData(color: t.divider, thickness: 1),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: t.surface,
      selectedItemColor: t.primary,
      unselectedItemColor: t.textTertiary,
      type: BottomNavigationBarType.fixed,
      elevation: AppDimensions.elevation4,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: t.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: t.onSurface,
      contentTextStyle: TextStyle(color: t.surface),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
    ),
  );
}
