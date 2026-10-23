import 'package:flutter/material.dart';

/// ════════════════════════════════════════════════════════════════
/// TẤT CẢ mã màu của app nằm DUY NHẤT ở file này.
/// Widget KHÔNG viết `Color(0x...)` — đọc qua `context.colors` (xem app_colors.dart).
/// Thêm màu chủ đạo: thêm 1 giá trị vào [AppAccent] (+ tên trong ARB `accent_<tên>`).
/// ════════════════════════════════════════════════════════════════

/// Màu chủ đạo người dùng chọn ở Hồ sơ → Giao diện. (light = nền sáng, dark = nền tối)
enum AppAccent {
  indigo(Color(0xFF5B5BD6), Color(0xFF9C9CFF)),
  sakura(Color(0xFFE0457B), Color(0xFFFF85AE)),
  emerald(Color(0xFF0F9D74), Color(0xFF3FD3A4)),
  ocean(Color(0xFF1C7ED6), Color(0xFF6BB4FF)),
  sunset(Color(0xFFEF6C1A), Color(0xFFFFA05A));

  const AppAccent(this.light, this.dark);

  final Color light;
  final Color dark;
}

abstract final class AppPalette {
  // ── Nền & chữ — chế độ sáng ───────────────────────────────────
  static const lightBackground = Color(0xFFF5F6FA);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurfaceAlt = Color(0xFFEEF0F6);
  static const lightBorder = Color(0xFFE1E4ED);
  static const lightText = Color(0xFF181B29);
  static const lightTextMuted = Color(0xFF6A6F86);

  // ── Nền & chữ — chế độ tối ────────────────────────────────────
  static const darkBackground = Color(0xFF0E1016);
  static const darkSurface = Color(0xFF181B25);
  static const darkSurfaceAlt = Color(0xFF232735);
  static const darkBorder = Color(0xFF2D3243);
  static const darkText = Color(0xFFF0F1F6);
  static const darkTextMuted = Color(0xFF9CA1B8);

  // ── Ngữ nghĩa ─────────────────────────────────────────────────
  static const success = Color(0xFF1FA463);
  static const error = Color(0xFFE5484D);
  static const warning = Color(0xFFF2A516);
  static const streak = Color(0xFFFF8A00); // ngọn lửa chuỗi ngày học

  /// Chữ / icon trên nền màu chủ đạo hoặc màu học phần.
  static const onAccent = Color(0xFFFFFFFF);

  /// Status bar trong suốt.
  static const transparent = Color(0x00000000);

  /// Nền mờ nút đóng trên quảng cáo toàn màn.
  static const scrim = Color(0x73000000);

  // ── Màu từng học phần (thẻ ở màn Khoá học) ────────────────────
  static const hiragana = Color(0xFFE0457B);
  static const katakana = Color(0xFF1C7ED6);
  static const kanjiN5 = Color(0xFF0F9D74);
  static const kanjiN4 = Color(0xFF7950F2);
  static const kanjiN3 = Color(0xFFEF6C1A);
  static const kanjiN2 = Color(0xFFC92A2A);
  static const pronunciation = Color(0xFF0C8599);
  static const vocabulary = Color(0xFF1C7ED6);
  static const phrases = Color(0xFFE8590C);
  static const grammar = Color(0xFF7048E8);
  static const dialogues = Color(0xFF2F9E44);
  static const irregularVerbs = Color(0xFFC2255C);
}
