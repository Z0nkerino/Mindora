import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';

import '../tokens/colors.dart';

/// Geometry of the Mindora mark, traced from the master artwork
/// (`assets/brand/mindora-logo-2000.png`, 2000 × 2000).
///
/// Three slanted bars. Each bar is a parallelogram whose top and bottom
/// edges fall at 45°, with tight rounding at the two sharp corners and
/// soft rounding at the two obtuse corners. The same numbers generate the
/// SVG and every app icon (see `tool/generate_icons.py`).
abstract final class MindoraMark {
  /// Canvas the coordinates below live in.
  static const double canvas = 2000;

  /// Left x of each bar.
  static const List<double> barX = [299, 806, 1313];
  static const double barWidth = 386;

  /// Top-left (sharp) corner y, and the y where the vertical edges end.
  static const double topLeftY = 425;
  static const double verticalLength = 760;

  /// Rounding (tangent distance along each edge) at sharp/obtuse corners.
  static const double sharpRound = 34;
  static const double obtuseRound = 105;

  /// Bounding box of the three bars inside [canvas].
  static Rect get bounds => Rect.fromLTRB(
    barX.first,
    topLeftY,
    barX.last + barWidth,
    topLeftY + barWidth + verticalLength,
  );

  /// Outline of bar [i] in canvas coordinates.
  static Path bar(int i) {
    final x0 = barX[i];
    final x1 = x0 + barWidth;
    final tl = Offset(x0, topLeftY); // sharp
    final tr = Offset(x1, topLeftY + barWidth); // obtuse
    final br = Offset(x1, topLeftY + barWidth + verticalLength); // sharp
    final bl = Offset(x0, topLeftY + verticalLength); // obtuse
    return roundedPolygon(
      [tl, tr, br, bl],
      [sharpRound, obtuseRound, sharpRound, obtuseRound],
    );
  }

  /// All three bars.
  static Path all() {
    final p = Path();
    for (var i = 0; i < barX.length; i++) {
      p.addPath(bar(i), Offset.zero);
    }
    return p;
  }

  /// Polygon with each corner rounded by a quadratic curve that starts and
  /// ends [round] px along the adjacent edges.
  static Path roundedPolygon(List<Offset> pts, List<double> round) {
    final path = Path();
    final n = pts.length;
    Offset along(Offset from, Offset to, double d) {
      final v = to - from;
      final len = v.distance;
      return from + v / len * (d.clamp(0, len / 2));
    }

    for (var i = 0; i < n; i++) {
      final prev = pts[(i - 1 + n) % n];
      final cur = pts[i];
      final next = pts[(i + 1) % n];
      final a = along(cur, prev, round[i]);
      final b = along(cur, next, round[i]);
      if (i == 0) {
        path.moveTo(a.dx, a.dy);
      } else {
        path.lineTo(a.dx, a.dy);
      }
      path.quadraticBezierTo(cur.dx, cur.dy, b.dx, b.dy);
    }
    path.close();
    return path;
  }
}

/// The Mindora mark as a widget. Draws only the three bars (no background)
/// so it works on any surface; pass [background] for the app-icon look.
class MindoraLogo extends StatelessWidget {
  const MindoraLogo({
    super.key,
    this.size = 32,
    this.color = MindoraColors.accent,
    this.background,
    this.semanticLabel = 'Mindora',
  });

  final double size;
  final Color color;
  final Color? background;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      image: true,
      child: CustomPaint(
        size: Size.square(size),
        painter: _MarkPainter(color: color, background: background),
      ),
    );
  }
}

class _MarkPainter extends CustomPainter {
  _MarkPainter({required this.color, this.background});
  final Color color;
  final Color? background;

  @override
  void paint(Canvas canvas, Size size) {
    if (background != null) {
      canvas.drawRSuperellipse(
        ui.RSuperellipse.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(size.shortestSide * 0.225),
        ),
        Paint()..color = background!,
      );
      // App-icon framing: mark at the master artwork's proportions.
      canvas.scale(size.width / MindoraMark.canvas);
    } else {
      // Tight framing: fit the bars' bounds to the box.
      final b = MindoraMark.bounds;
      final s = size.shortestSide / b.longestSide;
      canvas.translate(
        (size.width - b.width * s) / 2,
        (size.height - b.height * s) / 2,
      );
      canvas.scale(s);
      canvas.translate(-b.left, -b.top);
    }
    canvas.drawPath(MindoraMark.all(), Paint()..color = color);
  }

  @override
  bool shouldRepaint(_MarkPainter old) =>
      old.color != color || old.background != background;
}

/// Empty-state illustration: the three bars as translucent glass, one lit.
class MindoraBarsIllustration extends StatelessWidget {
  const MindoraBarsIllustration({
    super.key,
    required this.height,
    required this.lit,
    required this.unlit,
    this.litBar = 1,
  });

  final double height;
  final Color lit;
  final Color unlit;
  final int litBar;

  @override
  Widget build(BuildContext context) {
    final b = MindoraMark.bounds;
    return ExcludeSemantics(
      child: CustomPaint(
        size: Size(height * b.width / b.height, height),
        painter: _BarsPainter(lit: lit, unlit: unlit, litBar: litBar),
      ),
    );
  }
}

class _BarsPainter extends CustomPainter {
  _BarsPainter({required this.lit, required this.unlit, required this.litBar});
  final Color lit;
  final Color unlit;
  final int litBar;

  @override
  void paint(Canvas canvas, Size size) {
    final b = MindoraMark.bounds;
    final s = size.height / b.height;
    canvas.scale(s);
    canvas.translate(-b.left, -b.top);
    for (var i = 0; i < 3; i++) {
      final path = MindoraMark.bar(i);
      final isLit = i == litBar;
      canvas.drawPath(
        path,
        Paint()..color = isLit ? lit.withValues(alpha: 0.9) : unlit,
      );
      if (!isLit) {
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2 / s
            ..color = unlit.withValues(alpha: unlit.a * 1.6),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_BarsPainter old) =>
      old.lit != lit || old.unlit != unlit || old.litBar != litBar;
}
