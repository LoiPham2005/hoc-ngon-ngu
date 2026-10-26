import 'package:flutter/widgets.dart';

abstract class AppDimensions {
  /// Cỡ chữ hệ thống được phép (kẹp 1 chỗ trong `App`): người cần chữ to vẫn to hơn,
  /// nhưng không to tới mức vỡ layout (ô kana/kanji, lưới đáp án…).
  static const double minTextScale = 0.85;
  static const double maxTextScale = 1.3;

  // Spacing
  static const double space0 = 0;
  static const double space2 = 2;
  static const double space4 = 4;
  static const double space8 = 8;
  static const double space12 = 12;
  static const double space16 = 16;
  static const double space20 = 20;
  static const double space24 = 24;
  static const double space32 = 32;
  static const double space40 = 40;
  static const double space48 = 48;
  static const double space56 = 56;
  static const double space64 = 64;

  // Border radius
  static const double radiusXs = 4;
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 24;
  static const double radiusFull = 999;

  // Component heights
  static const double buttonHeightSm = 36;
  static const double buttonHeightMd = 44;
  static const double buttonHeightLg = 52;
  static const double inputHeight = 48;
  static const double appBarHeight = 56;
  static const double tabBarHeight = 64;

  // Icon sizes
  static const double iconXs = 12;
  static const double iconSm = 16;
  static const double iconMd = 20;
  static const double iconLg = 24;
  static const double iconXl = 32;

  // Elevation
  static const double elevation0 = 0;
  static const double elevation1 = 1;
  static const double elevation2 = 2;
  static const double elevation4 = 4;
  static const double elevation8 = 8;
}

// ── Spacing Shortcuts (Constants) ───────────────────────────
const gapH2 = SizedBox(height: AppDimensions.space2);
const gapH4 = SizedBox(height: AppDimensions.space4);
const gapH8 = SizedBox(height: AppDimensions.space8);
const gapH12 = SizedBox(height: AppDimensions.space12);
const gapH16 = SizedBox(height: AppDimensions.space16);
const gapH20 = SizedBox(height: AppDimensions.space20);
const gapH24 = SizedBox(height: AppDimensions.space24);
const gapH32 = SizedBox(height: AppDimensions.space32);
const gapH40 = SizedBox(height: AppDimensions.space40);
const gapH48 = SizedBox(height: AppDimensions.space48);
const gapH56 = SizedBox(height: AppDimensions.space56);
const gapH64 = SizedBox(height: AppDimensions.space64);

const gapW2 = SizedBox(width: AppDimensions.space2);
const gapW4 = SizedBox(width: AppDimensions.space4);
const gapW8 = SizedBox(width: AppDimensions.space8);
const gapW12 = SizedBox(width: AppDimensions.space12);
const gapW16 = SizedBox(width: AppDimensions.space16);
const gapW20 = SizedBox(width: AppDimensions.space20);
const gapW24 = SizedBox(width: AppDimensions.space24);
const gapW32 = SizedBox(width: AppDimensions.space32);
const gapW40 = SizedBox(width: AppDimensions.space40);
const gapW48 = SizedBox(width: AppDimensions.space48);
const gapW56 = SizedBox(width: AppDimensions.space56);
const gapW64 = SizedBox(width: AppDimensions.space64);
