import 'package:flutter/material.dart';
import 'package:lingua/design/theme/app_colors.dart';

/// Bộ widget giao diện nhỏ dùng chung. Màu luôn lấy từ `context.colors` / màu truyền vào.

/// Ô vuông bo góc có chữ đại diện (あ, 日…) trên nền gradient [color].
class GlyphBadge extends StatelessWidget {
  const GlyphBadge(
    this.glyph, {
    required this.color,
    this.size = 52,
    super.key,
  });

  final String glyph;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.3),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, darken(color)],
        ),
      ),
      // FittedBox: nhiều chữ (vd 'あア') tự thu nhỏ cho vừa ô.
      padding: EdgeInsets.all(size * 0.14),
      child: FittedBox(
        child: Text(
          glyph,
          style: TextStyle(
            color: context.colors.onPrimary,
            fontSize: size * 0.5,
            fontWeight: FontWeight.w600,
            height: 1,
          ),
        ),
      ),
    );
  }
}

/// Tối màu đi một chút (đáy gradient).
Color darken(Color color, [double amount = 0.12]) {
  final hsl = HSLColor.fromColor(color);
  return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
}

/// Tiêu đề nhóm trong danh sách.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {this.trailing, super.key});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8, bottom: 12),
    child: Row(
      children: [
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.titleMedium),
        ),
        ?trailing,
      ],
    ),
  );
}

/// Thanh tiến độ bo tròn.
class RoundedProgress extends StatelessWidget {
  const RoundedProgress(this.value, {this.color, this.height = 8, super.key});

  final double value;
  final Color? color;
  final double height;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(height),
    child: LinearProgressIndicator(
      value: value.clamp(0, 1),
      minHeight: height,
      color: color,
    ),
  );
}

/// Ô thống kê: số lớn + nhãn nhỏ.
class StatTile extends StatelessWidget {
  const StatTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    super.key,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 10),
            FittedBox(child: Text(value, style: theme.textTheme.headlineSmall)),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
