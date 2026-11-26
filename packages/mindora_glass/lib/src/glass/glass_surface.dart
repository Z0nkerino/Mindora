import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';

import '../theme/glass_config.dart';
import '../theme/mindora_theme.dart';
import '../tokens/colors.dart';
import '../tokens/spacing.dart';

/// The Mindora Glass material.
///
/// Layers, back to front:
/// 1. soft shadow (floating surfaces),
/// 2. backdrop blur + saturation boost (when [blur] and the quality tier
///    allows it),
/// 3. translucent tint for the [depth],
/// 4. specular rim: a light edge at the top-left fading to a soft shade at
///    the bottom-right, plus a hairline where glass meets a same-colour page.
///
/// In the `solid` tier (Reduce Transparency, High Contrast, weak GPUs) the
/// surface becomes opaque and the blur is skipped entirely.
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.depth = GlassDepth.raised,
    this.borderRadius = Radii.medium,
    this.padding,
    this.blur,
    this.tint,
    this.showRim = true,
    this.shadow,
  });

  final Widget child;
  final GlassDepth depth;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry? padding;

  /// Whether to blur what's behind. Defaults to true only for
  /// [GlassDepth.floating] — blurring a card over a plain page costs GPU
  /// time and shows nothing.
  final bool? blur;

  /// Overrides the depth's default tint (e.g. accent-tinted glass).
  final Color? tint;
  final bool showRim;

  /// Overrides the default shadow (floating surfaces only by default).
  final bool? shadow;

  static double blurSigma(GlassDepth depth) => switch (depth) {
    GlassDepth.inset => 0,
    GlassDepth.raised => 18,
    GlassDepth.floating => 28,
  };

  @override
  Widget build(BuildContext context) {
    final config = GlassConfig.of(context);
    final theme = MindoraTheme.of(context);
    final palette = theme.palette;
    final solid = config.effectiveQuality == GlassQuality.solid;
    final wantsBlur = (blur ?? depth == GlassDepth.floating) && !solid;
    final fill = tint ?? palette.fill(depth, solid: solid);
    final hasShadow = shadow ?? depth == GlassDepth.floating;

    final shape = RoundedSuperellipseBorder(borderRadius: borderRadius);

    Widget content = padding == null
        ? child
        : Padding(padding: padding!, child: child);

    content = DecoratedBox(
      decoration: ShapeDecoration(color: fill, shape: shape),
      child: showRim
          ? CustomPaint(
              foregroundPainter: GlassRimPainter(
                borderRadius: borderRadius,
                highlight: palette.rimHighlight,
                shade: palette.rimShade,
                hairline: config.highContrast
                    ? palette.hairline
                    : (palette.isDark && depth != GlassDepth.floating
                          ? Colors.transparent
                          : palette.hairline),
                strength: switch (depth) {
                  GlassDepth.inset => 0.35,
                  GlassDepth.raised => 0.7,
                  GlassDepth.floating => 1,
                },
              ),
              child: content,
            )
          : content,
    );

    if (wantsBlur) {
      final sigma = blurSigma(depth) * theme.blurScale;
      content = ClipRSuperellipse(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ui.ImageFilter.compose(
            outer: _saturate(palette.isDark ? 1.6 : 1.8),
            inner: ui.ImageFilter.blur(
              sigmaX: sigma,
              sigmaY: sigma,
              tileMode: TileMode.mirror,
            ),
          ),
          child: content,
        ),
      );
    } else {
      content = ClipRSuperellipse(borderRadius: borderRadius, child: content);
    }

    if (hasShadow) {
      content = DecoratedBox(
        decoration: ShapeDecoration(
          shape: shape,
          shadows: [
            BoxShadow(
              color: palette.shadow,
              blurRadius: depth == GlassDepth.floating ? 32 : 16,
              spreadRadius: -4,
              offset: Offset(0, depth == GlassDepth.floating ? 12 : 4),
            ),
          ],
        ),
        child: content,
      );
    }

    return content;
  }

  /// Saturation matrix: glass makes colours behind it slightly more vivid,
  /// which is a big part of what reads as "liquid glass" rather than fog.
  static ColorFilter _saturate(double s) {
    const rw = 0.2126, gw = 0.7152, bw = 0.0722;
    final a = (1 - s);
    return ColorFilter.matrix(<double>[
      a * rw + s, a * gw, a * bw, 0, 0, //
      a * rw, a * gw + s, a * bw, 0, 0, //
      a * rw, a * gw, a * bw + s, 0, 0, //
      0, 0, 0, 1, 0, //
    ]);
  }
}

/// Paints the specular rim of a glass surface.
class GlassRimPainter extends CustomPainter {
  GlassRimPainter({
    required this.borderRadius,
    required this.highlight,
    required this.shade,
    required this.hairline,
    this.strength = 1,
  });

  final BorderRadius borderRadius;
  final Color highlight;
  final Color shade;
  final Color hairline;
  final double strength;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final rect = Offset.zero & size;
    final shape = borderRadius.toRSuperellipse(rect.deflate(0.5));

    if (hairline.a > 0) {
      canvas.drawRSuperellipse(
        shape,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = hairline,
      );
    }

    final h = highlight.withValues(alpha: highlight.a * strength);
    final rim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..shader = ui.Gradient.linear(
        rect.topLeft,
        rect.bottomRight,
        [h, h.withValues(alpha: 0), shade.withValues(alpha: 0), shade],
        const [0, 0.38, 0.62, 1],
      );
    canvas.drawRSuperellipse(shape, rim);
  }

  @override
  bool shouldRepaint(GlassRimPainter old) =>
      old.borderRadius != borderRadius ||
      old.highlight != highlight ||
      old.shade != shade ||
      old.hairline != hairline ||
      old.strength != strength;
}
