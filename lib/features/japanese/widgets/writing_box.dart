import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingua/features/japanese/providers/strokes_provider.dart';
import 'package:lingua/shared/states/async_view.dart';

enum _Mode { order, practice }

/// Thứ tự nét + tập viết cho 1 chữ — dùng chung màn chi tiết Kana và Kanji.
/// Tự co theo chỗ trống (đặt trong `Expanded`) → không cần cuộn (cuộn tranh cử chỉ với ô tập viết).
class WritingPanel extends HookConsumerWidget {
  const WritingPanel({required this.char, super.key});

  final String char;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = useState(_Mode.order);
    final theme = Theme.of(context);
    return AsyncView<List<Path>>(
      state: ref.watch(strokesProvider(char)),
      onRetry: () => ref.invalidate(strokesProvider(char)),
      builder: (context, strokes) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<_Mode>(
            segments: [
              ButtonSegment(
                value: _Mode.order,
                icon: const Icon(Icons.gesture),
                label: Text('Thứ tự nét (${strokes.length})'),
              ),
              const ButtonSegment(
                value: _Mode.practice,
                icon: Icon(Icons.edit_outlined),
                label: Text('Tập viết'),
              ),
            ],
            selected: {mode.value},
            onSelectionChanged: (s) => mode.value = s.first,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Center(
              child: mode.value == _Mode.order
                  ? StrokeOrderBox(strokes: strokes)
                  : PracticeBox(guide: strokes),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            mode.value == _Mode.order
                ? 'Số nhỏ = thứ tự nét. Bấm ↻ để xem lại.'
                : 'Tô theo nét mờ, đúng thứ tự. Bấm 🗑 để viết lại.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
          Text(
            'Dữ liệu nét chữ: KanjiVG (CC BY-SA 3.0)',
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Ô vuông có lưới ô li — hoạt ảnh viết từng nét theo đúng thứ tự (có số thứ tự nét).
class StrokeOrderBox extends HookWidget {
  const StrokeOrderBox({required this.strokes, super.key});

  final List<Path> strokes;

  @override
  Widget build(BuildContext context) {
    final controller = useAnimationController(
      duration: Duration(milliseconds: 800 * strokes.length),
    );
    useEffect(() {
      controller.forward(from: 0);
      return null;
    }, [strokes]);
    final progress = useAnimation(controller);
    final colors = Theme.of(context).colorScheme;

    return _Box(
      action: IconButton.filledTonal(
        tooltip: 'Viết lại',
        onPressed: () => controller.forward(from: 0),
        icon: const Icon(Icons.replay),
      ),
      painter: _StrokePainter(
        strokes: strokes,
        drawn: progress * strokes.length,
        ink: colors.onSurface,
        guide: colors.onSurface.withValues(alpha: 0.12), // nét mờ: chỗ sắp viết
        number: colors.primary,
      ),
    );
  }
}

/// Ô tập viết: tô theo nét mờ của chữ bằng ngón tay.
class PracticeBox extends HookWidget {
  const PracticeBox({required this.guide, super.key});

  final List<Path> guide;

  @override
  Widget build(BuildContext context) {
    final lines = useState<List<List<Offset>>>(const []);
    final colors = Theme.of(context).colorScheme;

    return _Box(
      action: IconButton.filledTonal(
        tooltip: 'Xoá',
        onPressed: () => lines.value = const [],
        icon: const Icon(Icons.delete_outline),
      ),
      painter: _PracticePainter(
        guide: guide,
        lines: lines.value,
        ink: colors.primary,
        guideColor: colors.onSurface.withValues(alpha: 0.15),
      ),
      child: GestureDetector(
        onPanStart: (d) => lines.value = [
          ...lines.value,
          [d.localPosition],
        ],
        onPanUpdate: (d) => lines.value = [
          ...lines.value.take(lines.value.length - 1),
          [...lines.value.last, d.localPosition],
        ],
      ),
    );
  }
}

class _Box extends StatelessWidget {
  const _Box({required this.painter, required this.action, this.child});

  final CustomPainter painter;
  final Widget action;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AspectRatio(
      aspectRatio: 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _GridPainter(colors.outlineVariant),
                  foregroundPainter: painter,
                  child: child ?? const SizedBox.expand(),
                ),
              ),
              Positioned(top: 8, right: 8, child: action),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lưới ô li: 2 đường giữa (nét đứt) để căn chữ.
class _GridPainter extends CustomPainter {
  const _GridPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    const dash = 6.0;
    for (var d = 0.0; d < size.width; d += dash * 2) {
      canvas
        ..drawLine(
          Offset(d, size.height / 2),
          Offset(d + dash, size.height / 2),
          paint,
        )
        ..drawLine(
          Offset(size.width / 2, d),
          Offset(size.width / 2, d + dash),
          paint,
        );
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => old.color != color;
}

Paint _strokePaint(Color color, double width) => Paint()
  ..color = color
  ..style = PaintingStyle.stroke
  ..strokeWidth = width
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round;

class _StrokePainter extends CustomPainter {
  const _StrokePainter({
    required this.strokes,
    required this.drawn,
    required this.ink,
    required this.guide,
    required this.number,
  });

  final List<Path> strokes;

  /// Số nét đã vẽ (phần lẻ = nét đang vẽ dở), 0 → strokes.length.
  final double drawn;
  final Color ink;
  final Color guide;
  final Color number;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / strokeBox);
    final guidePaint = _strokePaint(guide, 4);
    final inkPaint = _strokePaint(ink, 4.5);
    for (final stroke in strokes) {
      canvas.drawPath(stroke, guidePaint);
    }
    for (var i = 0; i < strokes.length && i < drawn; i++) {
      final part = (drawn - i).clamp(0.0, 1.0);
      for (final metric in strokes[i].computeMetrics()) {
        canvas.drawPath(metric.extractPath(0, metric.length * part), inkPaint);
        // Số thứ tự nét ở điểm bắt đầu nét.
        final start = metric.getTangentForOffset(0)?.position;
        if (start != null) _drawNumber(canvas, '${i + 1}', start);
        break; // mỗi nét KanjiVG là 1 đường liền
      }
    }
  }

  void _drawNumber(Canvas canvas, String text, Offset at) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: number,
          fontSize: 7,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, at - const Offset(8, 8));
  }

  @override
  bool shouldRepaint(_StrokePainter old) =>
      old.drawn != drawn || old.strokes != strokes || old.ink != ink;
}

class _PracticePainter extends CustomPainter {
  const _PracticePainter({
    required this.guide,
    required this.lines,
    required this.ink,
    required this.guideColor,
  });

  final List<Path> guide;
  final List<List<Offset>> lines;
  final Color ink;
  final Color guideColor;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / strokeBox;
    canvas
      ..save()
      ..scale(scale);
    final guidePaint = _strokePaint(guideColor, 4);
    for (final stroke in guide) {
      canvas.drawPath(stroke, guidePaint);
    }
    canvas.restore();

    final inkPaint = _strokePaint(ink, 4.5 * scale);
    for (final line in lines) {
      if (line.length == 1) {
        canvas.drawPoints(PointMode.points, line, inkPaint);
      } else {
        canvas.drawPath(Path()..addPolygon(line, false), inkPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_PracticePainter old) =>
      old.lines != lines || old.guide != guide || old.ink != ink;
}
