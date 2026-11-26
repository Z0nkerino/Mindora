import 'dart:math' as math;
import 'dart:ui' show Brightness, Color;

import 'package:flutter/foundation.dart';

/// Raw brand colours. Feature code should not use these directly; read
/// [MindoraPalette] from the theme instead so light/dark and contrast rules
/// are applied.
abstract final class MindoraColors {
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);

  /// The one accent. Used for primary actions, the current selection and
  /// progress — fills, rings and indicators.
  static const Color accent = Color(0xFFFF0051);

  /// Accent for *small text* on light surfaces (5.76:1 on white, 4.69:1 on
  /// the accent-soft selection tint).
  static const Color accentInkLight = Color(0xFFCC0041);

  /// Accent for *small text* on dark surfaces (5.98:1 on black,
  /// 4.84:1 on dark glass).
  static const Color accentInkDark = Color(0xFFFF3374);
}

/// Depth of a glass surface. Higher depth = more blur, stronger tint, more
/// shadow.
enum GlassDepth {
  /// Recessed fields (text inputs, tracks). No blur.
  inset,

  /// Cards and list groups resting on the page. Blur only when requested.
  raised,

  /// Floating chrome: tab bar, sidebar, toolbars, sheets, dialogs.
  floating,
}

/// The resolved colour set for one brightness.
@immutable
class MindoraPalette {
  const MindoraPalette({
    required this.brightness,
    required this.background,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.separator,
    required this.accent,
    required this.accentInk,
    required this.accentSoft,
    required this.onAccent,
    required this.insetFill,
    required this.raisedFill,
    required this.floatingFill,
    required this.insetSolid,
    required this.raisedSolid,
    required this.floatingSolid,
    required this.rimHighlight,
    required this.rimShade,
    required this.hairline,
    required this.shadow,
    required this.scrim,
    required this.pressOverlay,
    required this.hoverOverlay,
  });

  final Brightness brightness;
  final Color background;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color separator;

  /// Brand accent for fills, rings, progress, selection.
  final Color accent;

  /// Accent for small text and thin strokes (contrast-safe).
  final Color accentInk;

  /// Low-opacity accent for selected backgrounds.
  final Color accentSoft;

  /// Text/icon colour on top of an [accent] fill (use with large bold text).
  final Color onAccent;

  /// Translucent fills used when blur is available.
  final Color insetFill;
  final Color raisedFill;
  final Color floatingFill;

  /// Opaque fills used in the `solid` quality tier and for Reduce
  /// Transparency.
  final Color insetSolid;
  final Color raisedSolid;
  final Color floatingSolid;

  /// Specular rim: bright edge at the top-left, soft shade at bottom-right.
  final Color rimHighlight;
  final Color rimShade;

  /// Thin outline used where glass sits on a same-colour background.
  final Color hairline;
  final Color shadow;
  final Color scrim;
  final Color pressOverlay;
  final Color hoverOverlay;

  bool get isDark => brightness == Brightness.dark;

  Color fill(GlassDepth depth, {required bool solid}) => switch (depth) {
    GlassDepth.inset => solid ? insetSolid : insetFill,
    GlassDepth.raised => solid ? raisedSolid : raisedFill,
    GlassDepth.floating => solid ? floatingSolid : floatingFill,
  };

  static const MindoraPalette dark = MindoraPalette(
    brightness: Brightness.dark,
    background: MindoraColors.black,
    textPrimary: MindoraColors.white,
    textSecondary: Color(0xA3FFFFFF), // 64 %
    textTertiary: Color(0x85FFFFFF), // 52 % → 5.5:1 on dark glass
    separator: Color(0x1FFFFFFF),
    accent: MindoraColors.accent,
    accentInk: MindoraColors.accentInkDark,
    accentSoft: Color(0x2EFF0051),
    onAccent: MindoraColors.white,
    insetFill: Color(0x14FFFFFF),
    raisedFill: Color(0x17FFFFFF),
    floatingFill: Color(0xB31A1A1C),
    insetSolid: Color(0xFF141416),
    raisedSolid: Color(0xFF161618),
    floatingSolid: Color(0xFF1C1C1E),
    rimHighlight: Color(0x59FFFFFF),
    rimShade: Color(0x0FFFFFFF),
    hairline: Color(0x1AFFFFFF),
    shadow: Color(0x99000000),
    scrim: Color(0x8C000000),
    pressOverlay: Color(0x1FFFFFFF),
    hoverOverlay: Color(0x0FFFFFFF),
  );

  static const MindoraPalette light = MindoraPalette(
    brightness: Brightness.light,
    background: MindoraColors.white,
    textPrimary: MindoraColors.black,
    textSecondary: Color(0x9E000000), // 62 %
    textTertiary: Color(0x8F000000), // 56 % → 4.9:1 on white
    separator: Color(0x14000000),
    accent: MindoraColors.accent,
    accentInk: MindoraColors.accentInkLight,
    accentSoft: Color(0x1FFF0051),
    onAccent: MindoraColors.white,
    insetFill: Color(0x0D000000),
    raisedFill: Color(0x08000000),
    floatingFill: Color(0xC7FFFFFF),
    insetSolid: Color(0xFFF2F2F3),
    raisedSolid: Color(0xFFF7F7F8),
    floatingSolid: Color(0xFFFFFFFF),
    rimHighlight: Color(0xE6FFFFFF),
    rimShade: Color(0x0F000000),
    hairline: Color(0x14000000),
    shadow: Color(0x1F000000),
    scrim: Color(0x52000000),
    pressOverlay: Color(0x14000000),
    hoverOverlay: Color(0x0A000000),
  );

  /// High-contrast variants: stronger text and hairlines, no faint greys.
  MindoraPalette highContrast() => MindoraPalette(
    brightness: brightness,
    background: background,
    textPrimary: textPrimary,
    textSecondary: isDark ? const Color(0xD9FFFFFF) : const Color(0xD9000000),
    textTertiary: isDark ? const Color(0xB3FFFFFF) : const Color(0xB3000000),
    separator: isDark ? const Color(0x59FFFFFF) : const Color(0x59000000),
    accent: accent,
    accentInk: accentInk,
    accentSoft: accentSoft,
    onAccent: onAccent,
    insetFill: insetSolid,
    raisedFill: raisedSolid,
    floatingFill: floatingSolid,
    insetSolid: insetSolid,
    raisedSolid: raisedSolid,
    floatingSolid: floatingSolid,
    rimHighlight: rimHighlight,
    rimShade: rimShade,
    hairline: isDark ? const Color(0x66FFFFFF) : const Color(0x66000000),
    shadow: shadow,
    scrim: scrim,
    pressOverlay: pressOverlay,
    hoverOverlay: hoverOverlay,
  );

  static MindoraPalette lerp(MindoraPalette a, MindoraPalette b, double t) {
    Color l(Color x, Color y) => Color.lerp(x, y, t)!;
    return MindoraPalette(
      brightness: t < 0.5 ? a.brightness : b.brightness,
      background: l(a.background, b.background),
      textPrimary: l(a.textPrimary, b.textPrimary),
      textSecondary: l(a.textSecondary, b.textSecondary),
      textTertiary: l(a.textTertiary, b.textTertiary),
      separator: l(a.separator, b.separator),
      accent: l(a.accent, b.accent),
      accentInk: l(a.accentInk, b.accentInk),
      accentSoft: l(a.accentSoft, b.accentSoft),
      onAccent: l(a.onAccent, b.onAccent),
      insetFill: l(a.insetFill, b.insetFill),
      raisedFill: l(a.raisedFill, b.raisedFill),
      floatingFill: l(a.floatingFill, b.floatingFill),
      insetSolid: l(a.insetSolid, b.insetSolid),
      raisedSolid: l(a.raisedSolid, b.raisedSolid),
      floatingSolid: l(a.floatingSolid, b.floatingSolid),
      rimHighlight: l(a.rimHighlight, b.rimHighlight),
      rimShade: l(a.rimShade, b.rimShade),
      hairline: l(a.hairline, b.hairline),
      shadow: l(a.shadow, b.shadow),
      scrim: l(a.scrim, b.scrim),
      pressOverlay: l(a.pressOverlay, b.pressOverlay),
      hoverOverlay: l(a.hoverOverlay, b.hoverOverlay),
    );
  }
}

/// WCAG 2.x contrast helpers, used by tests and debug assertions.
abstract final class Contrast {
  static double _channel(double c) =>
      c <= 0.04045 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();

  /// Relative luminance of an opaque colour.
  static double luminance(Color c) =>
      0.2126 * _channel(c.r) + 0.7152 * _channel(c.g) + 0.0722 * _channel(c.b);

  /// Contrast ratio of [foreground] composited over an opaque [background].
  static double ratio(Color foreground, Color background) {
    final fg = Color.alphaBlend(foreground, background);
    final a = luminance(fg);
    final b = luminance(background);
    final hi = math.max(a, b);
    final lo = math.min(a, b);
    return (hi + 0.05) / (lo + 0.05);
  }
}
