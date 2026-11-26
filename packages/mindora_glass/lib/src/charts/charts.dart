import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';

import '../motion/motion.dart';
import '../theme/glass_config.dart';
import '../theme/mindora_theme.dart';

/// Common plumbing: every chart draws itself in on a spring and exposes a
/// plain-language [semanticSummary] to screen readers (charts are images to
/// assistive tech unless we describe them).
abstract class _AnimatedChart extends StatefulWidget {
  const _AnimatedChart({super.key, required this.semanticSummary});
  final String semanticSummary;
}

abstract class _AnimatedChartState<T extends _AnimatedChart> extends State<T>
    with SingleTickerProviderStateMixin {
  late final SpringValue reveal = SpringValue(
    vsync: this,
    spring: MindoraSprings.gentle,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = GlassConfig.of(context).reduceMotion;
    reveal.reduceMotion = reduce;
    if (!_started) {
      _started = true;
      reduce ? reveal.jumpTo(1) : reveal.animateTo(1);
    }
  }

  @override
  void dispose() {
    reveal.dispose();
    super.dispose();
  }

  Widget paint(CustomPainter Function(double t) painter, double height) {
    return Semantics(
      label: widget.semanticSummary,
      image: true,
      child: ExcludeSemantics(
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: AnimatedBuilder(
            animation: reveal,
            builder: (context, _) =>
                CustomPaint(painter: painter(reveal.value)),
          ),
        ),
      ),
    );
  }
}

/// Smooth line chart with a soft gradient fill. Good for trends (sleep,
/// weight, balance).
class GlassLineChart extends _AnimatedChart {
  const GlassLineChart({
    super.key,
    required this.values,
    required super.semanticSummary,
    this.height = 140,
    this.color,
    this.showDots = false,
    this.showGrid = true,
  });

  final List<double> values;
  final double height;
  final Color? color;
  final bool showDots;
  final bool showGrid;

  @override
  State<GlassLineChart> createState() => _GlassLineChartState();
}

class _GlassLineChartState extends _AnimatedChartState<GlassLineChart> {
  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final c = widget.color ?? palette.accent;
    return paint(
      (t) => _LinePainter(
        values: widget.values,
        t: t,
        color: c,
        grid: widget.showGrid ? palette.separator : const Color(0x00000000),
        dots: widget.showDots,
        dotFill: palette.background,
      ),
      widget.height,
    );
  }
}

class _LinePainter extends CustomPainter {
  _LinePainter({
    required this.values,
    required this.t,
    required this.color,
    required this.grid,
    required this.dots,
    required this.dotFill,
  });

  final List<double> values;
  final double t;
  final Color color;
  final Color grid;
  final bool dots;
  final Color dotFill;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    // Pad the range so small day-to-day changes look calm, not dramatic.
    final lo = values.reduce(math.min);
    final hi = values.reduce(math.max);
    final raw = (hi - lo).abs() < 1e-9 ? (hi.abs() < 1e-9 ? 1.0 : hi.abs()) : hi - lo;
    final minV = lo - raw * 0.35;
    final maxV = hi + raw * 0.15;
    final span = maxV - minV;
    const padY = 8.0;
    final h = size.height - padY * 2;

    // Light horizontal guides.
    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (var i = 0; i <= 2 && grid.a > 0; i++) {
      final y = padY + h * i / 2;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final pts = <Offset>[
      for (var i = 0; i < values.length; i++)
        Offset(
          size.width * i / (values.length - 1),
          padY + h * (1 - (values[i] - minV) / span),
        ),
    ];

    // Catmull-Rom → cubic Bézier for a smooth curve.
    final line = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 0; i < pts.length - 1; i++) {
      final p0 = i == 0 ? pts[i] : pts[i - 1];
      final p1 = pts[i];
      final p2 = pts[i + 1];
      final p3 = i + 2 < pts.length ? pts[i + 2] : p2;
      final c1 = p1 + (p2 - p0) / 6;
      final c2 = p2 - (p3 - p1) / 6;
      line.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
    }

    final p = t.clamp(0.0, 1.0);
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width * p, size.height));

    final fill = Path.from(line)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = ui.Gradient.linear(Offset.zero, Offset(0, size.height), [
          color.withValues(alpha: 0.28),
          color.withValues(alpha: 0),
        ]),
    );
    canvas.drawPath(
      line,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );
    if (dots) {
      for (final pt in pts) {
        canvas.drawCircle(pt, 4, Paint()..color = dotFill);
        canvas.drawCircle(
          pt,
          4,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = color,
        );
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_LinePainter old) =>
      old.t != t ||
      old.values != values ||
      old.color != color ||
      old.grid != grid ||
      old.dots != dots;
}

/// Rounded bar chart with optional labels; [highlightIndex] bar uses the
/// accent, the rest are neutral (accent used sparingly).
class GlassBarChart extends _AnimatedChart {
  const GlassBarChart({
    super.key,
    required this.values,
    required super.semanticSummary,
    this.labels,
    this.highlightIndex,
    this.height = 140,
  });

  final List<double> values;
  final List<String>? labels;
  final int? highlightIndex;
  final double height;

  @override
  State<GlassBarChart> createState() => _GlassBarChartState();
}

class _GlassBarChartState extends _AnimatedChartState<GlassBarChart> {
  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final type = context.type;
    return paint(
      (t) => _BarPainter(
        values: widget.values,
        labels: widget.labels,
        t: t,
        highlight: widget.highlightIndex,
        accent: palette.accent,
        neutral: palette.isDark
            ? const Color(0x33FFFFFF)
            : const Color(0x1F000000),
        labelStyle: type.caption.copyWith(color: palette.textTertiary),
        direction: Directionality.of(context),
      ),
      widget.height,
    );
  }
}

class _BarPainter extends CustomPainter {
  _BarPainter({
    required this.values,
    required this.labels,
    required this.t,
    required this.highlight,
    required this.accent,
    required this.neutral,
    required this.labelStyle,
    required this.direction,
  });

  final List<double> values;
  final List<String>? labels;
  final double t;
  final int? highlight;
  final Color accent;
  final Color neutral;
  final TextStyle labelStyle;
  final TextDirection direction;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final maxV = math.max(values.reduce(math.max), 1e-9);
    final labelH = labels == null ? 0.0 : 20.0;
    final chartH = size.height - labelH;
    final slot = size.width / values.length;
    final barW = math.min(slot * 0.56, 28.0);

    for (var i = 0; i < values.length; i++) {
      // Stagger: each bar starts a little later.
      final local = ((t * 1.3) - i * 0.3 / values.length).clamp(0.0, 1.0);
      final h = chartH * (values[i] / maxV) * local;
      final cx = slot * i + slot / 2;
      final rect = Rect.fromLTWH(cx - barW / 2, chartH - h, barW, h);
      if (h > 0) {
        canvas.drawRSuperellipse(
          ui.RSuperellipse.fromRectAndRadius(
            rect,
            Radius.circular(math.min(barW / 2, 8)),
          ),
          Paint()..color = i == highlight ? accent : neutral,
        );
      }
      if (labels != null && i < labels!.length) {
        final tp = TextPainter(
          text: TextSpan(text: labels![i], style: labelStyle),
          textDirection: direction,
          maxLines: 1,
        )..layout(maxWidth: slot);
        tp.paint(canvas, Offset(cx - tp.width / 2, chartH + 4));
      }
    }
  }

  @override
  bool shouldRepaint(_BarPainter old) =>
      old.t != t ||
      old.values != values ||
      old.highlight != highlight ||
      old.accent != accent ||
      old.neutral != neutral;
}

/// Calendar heatmap (habits). [values] are 0..1 per day, column-major by
/// week (7 rows), oldest first.
class GlassHeatmap extends _AnimatedChart {
  const GlassHeatmap({
    super.key,
    required this.values,
    required super.semanticSummary,
    this.cell = 13,
    this.gap = 3,
  });

  final List<double> values;
  final double cell;
  final double gap;

  @override
  State<GlassHeatmap> createState() => _GlassHeatmapState();
}

class _GlassHeatmapState extends _AnimatedChartState<GlassHeatmap> {
  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final height = widget.cell * 7 + widget.gap * 6;
    return paint(
      (t) => _HeatmapPainter(
        values: widget.values,
        t: t,
        cell: widget.cell,
        gap: widget.gap,
        accent: palette.accent,
        empty: palette.isDark
            ? const Color(0x14FFFFFF)
            : const Color(0x0F000000),
      ),
      height,
    );
  }
}

class _HeatmapPainter extends CustomPainter {
  _HeatmapPainter({
    required this.values,
    required this.t,
    required this.cell,
    required this.gap,
    required this.accent,
    required this.empty,
  });

  final List<double> values;
  final double t;
  final double cell;
  final double gap;
  final Color accent;
  final Color empty;

  @override
  void paint(Canvas canvas, Size size) {
    final weeks = (values.length / 7).ceil();
    // Right-align so the most recent week is always visible.
    final total = weeks * (cell + gap) - gap;
    final dx = math.min(0.0, size.width - total);
    for (var i = 0; i < values.length; i++) {
      final col = i ~/ 7;
      final row = i % 7;
      final local = ((t * 1.4) - col / math.max(weeks, 1) * 0.4).clamp(
        0.0,
        1.0,
      );
      final v = values[i].clamp(0.0, 1.0) * local;
      final color = v <= 0
          ? empty
          : Color.lerp(empty, accent, 0.25 + 0.75 * v)!;
      final rect = Rect.fromLTWH(
        dx + col * (cell + gap),
        row * (cell + gap),
        cell,
        cell,
      );
      canvas.drawRSuperellipse(
        ui.RSuperellipse.fromRectAndRadius(rect, const Radius.circular(4)),
        Paint()..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_HeatmapPainter old) =>
      old.t != t || old.values != values || old.accent != accent;
}

/// Tiny inline trend line for tiles.
class GlassSparkline extends StatelessWidget {
  const GlassSparkline({
    super.key,
    required this.values,
    required this.semanticSummary,
    this.width = 72,
    this.height = 28,
    this.color,
  });

  final List<double> values;
  final String semanticSummary;
  final double width;
  final double height;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: GlassLineChart(
        values: values,
        semanticSummary: semanticSummary,
        height: height,
        showGrid: false,
        color: color ?? context.palette.textSecondary,
      ),
    );
  }
}
