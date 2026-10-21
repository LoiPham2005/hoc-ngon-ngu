import 'dart:convert';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:path_parsing/path_parsing.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'strokes_provider.g.dart';

/// Kích thước khung toạ độ của dữ liệu nét (viewBox 109×109 của KanjiVG).
const strokeBox = 109.0;

/// Nét viết (SVG path) của mọi Hiragana, Katakana và Kanji N5–N2, đúng thứ tự viết.
/// Dữ liệu: KanjiVG (https://kanjivg.tagaini.net, CC BY-SA 3.0) → `assets/japanese/strokes.json`.
@Riverpod(keepAlive: true)
Future<Map<String, List<String>>> strokeData(Ref ref) async {
  final raw =
      jsonDecode(await rootBundle.loadString('assets/japanese/strokes.json'))
          as Map<String, dynamic>;
  return raw.map((k, v) => MapEntry(k, (v as List).cast<String>()));
}

/// Nét viết của 1 chữ (parse khi cần — không parse sẵn ~1.100 chữ).
@riverpod
Future<List<Path>> strokes(Ref ref, String char) async {
  final data = await ref.watch(strokeDataProvider.future);
  return [for (final d in data[char] ?? const <String>[]) _parse(d)];
}

Path _parse(String svgPath) {
  final builder = _PathBuilder();
  writeSvgPathDataToPath(svgPath, builder);
  return builder.path;
}

class _PathBuilder extends PathProxy {
  final path = Path();

  @override
  void moveTo(double x, double y) => path.moveTo(x, y);

  @override
  void lineTo(double x, double y) => path.lineTo(x, y);

  @override
  void cubicTo(
    double x1,
    double y1,
    double x2,
    double y2,
    double x3,
    double y3,
  ) => path.cubicTo(x1, y1, x2, y2, x3, y3);

  @override
  void close() => path.close();
}
