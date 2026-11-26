import 'package:flutter/widgets.dart';

/// How rich the glass material is rendered.
enum GlassQuality {
  /// Blur + tint + specular rim + shader-driven liquid indicators.
  liquid,

  /// Blur + tint + static rim. Cheaper; no shaders.
  frosted,

  /// Opaque layered surfaces, no blur. Used for Reduce Transparency, weak
  /// GPUs and as a last resort on the web.
  solid,
}

/// Rendering and accessibility switches for every glass widget below it.
///
/// The app resolves these from user settings plus OS accessibility flags
/// (`MediaQuery.disableAnimations`, `highContrast`, …) and places one
/// [GlassConfig] above the navigator.
@immutable
class GlassConfigData {
  const GlassConfigData({
    this.quality = GlassQuality.liquid,
    this.reduceMotion = false,
    this.reduceTransparency = false,
    this.highContrast = false,
  });

  final GlassQuality quality;
  final bool reduceMotion;
  final bool reduceTransparency;
  final bool highContrast;

  /// The quality actually used after accessibility overrides.
  GlassQuality get effectiveQuality =>
      reduceTransparency || highContrast ? GlassQuality.solid : quality;

  bool get usesBlur => effectiveQuality != GlassQuality.solid;
  bool get usesShaders =>
      effectiveQuality == GlassQuality.liquid && !reduceMotion;

  GlassConfigData copyWith({
    GlassQuality? quality,
    bool? reduceMotion,
    bool? reduceTransparency,
    bool? highContrast,
  }) => GlassConfigData(
    quality: quality ?? this.quality,
    reduceMotion: reduceMotion ?? this.reduceMotion,
    reduceTransparency: reduceTransparency ?? this.reduceTransparency,
    highContrast: highContrast ?? this.highContrast,
  );

  @override
  bool operator ==(Object other) =>
      other is GlassConfigData &&
      other.quality == quality &&
      other.reduceMotion == reduceMotion &&
      other.reduceTransparency == reduceTransparency &&
      other.highContrast == highContrast;

  @override
  int get hashCode =>
      Object.hash(quality, reduceMotion, reduceTransparency, highContrast);
}

class GlassConfig extends InheritedWidget {
  const GlassConfig({super.key, required this.data, required super.child});

  final GlassConfigData data;

  static const GlassConfigData _fallback = GlassConfigData();

  static GlassConfigData of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<GlassConfig>()?.data ??
      _fallback;

  @override
  bool updateShouldNotify(GlassConfig oldWidget) => data != oldWidget.data;
}
