import 'dart:ui' show lerpDouble;

import 'package:cupertino_ui/cupertino_ui.dart'
    show CupertinoPageTransitionsBuilder;
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../tokens/colors.dart';
import '../tokens/spacing.dart';
import '../tokens/typography.dart';

/// Mindora's theme, carried as a [ThemeExtension] so light/dark switches
/// animate smoothly through [AnimatedTheme].
@immutable
class MindoraTheme extends ThemeExtension<MindoraTheme> {
  const MindoraTheme({
    required this.palette,
    this.typography = const MindoraTypography(),
    this.blurScale = 1,
  });

  final MindoraPalette palette;
  final MindoraTypography typography;

  /// Multiplier for blur sigmas (lets low-end devices blur less).
  final double blurScale;

  static MindoraTheme of(BuildContext context) =>
      Theme.of(context).extension<MindoraTheme>() ??
      const MindoraTheme(palette: MindoraPalette.dark);

  @override
  MindoraTheme copyWith({
    MindoraPalette? palette,
    MindoraTypography? typography,
    double? blurScale,
  }) => MindoraTheme(
    palette: palette ?? this.palette,
    typography: typography ?? this.typography,
    blurScale: blurScale ?? this.blurScale,
  );

  @override
  MindoraTheme lerp(MindoraTheme? other, double t) {
    if (other == null) return this;
    return MindoraTheme(
      palette: MindoraPalette.lerp(palette, other.palette, t),
      typography: t < 0.5 ? typography : other.typography,
      blurScale: lerpDouble(blurScale, other.blurScale, t)!,
    );
  }
}

/// Short accessors used throughout the components.
extension MindoraThemeContext on BuildContext {
  MindoraTheme get mindora => MindoraTheme.of(this);
  MindoraPalette get palette => MindoraTheme.of(this).palette;
  MindoraTypography get type => MindoraTheme.of(this).typography;
}

/// Builds a Material [ThemeData] dressed in Mindora Glass, so that the few
/// Material pieces we rely on (text selection, scrollbars, tooltips, focus)
/// match the design system.
ThemeData buildMindoraTheme({
  required Brightness brightness,
  bool highContrast = false,
  String? fontFamily,
  List<String>? fontFamilyFallback,
}) {
  var palette = brightness == Brightness.dark
      ? MindoraPalette.dark
      : MindoraPalette.light;
  if (highContrast) palette = palette.highContrast();
  final type = MindoraTypography(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
  );

  final scheme = ColorScheme(
    brightness: brightness,
    primary: palette.accent,
    onPrimary: palette.onAccent,
    secondary: palette.textPrimary,
    onSecondary: palette.background,
    error: palette.accentInk,
    onError: palette.onAccent,
    surface: palette.background,
    onSurface: palette.textPrimary,
    surfaceContainerHighest: palette.raisedSolid,
    outline: palette.hairline,
    outlineVariant: palette.separator,
  );

  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    scaffoldBackgroundColor: palette.background,
    canvasColor: palette.background,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    hoverColor: palette.hoverOverlay,
    focusColor: palette.accentSoft,
    dividerColor: palette.separator,
    visualDensity: VisualDensity.standard,
    materialTapTargetSize: MaterialTapTargetSize.padded,
  );

  return base.copyWith(
    extensions: [MindoraTheme(palette: palette, typography: type)],
    textTheme: base.textTheme
        .copyWith(
          displayLarge: type.display,
          headlineLarge: type.title1,
          headlineMedium: type.title2,
          titleLarge: type.title2,
          titleMedium: type.headline,
          titleSmall: type.subhead,
          bodyLarge: type.body,
          bodyMedium: type.callout,
          bodySmall: type.footnote,
          labelLarge: type.headline,
          labelMedium: type.subhead,
          labelSmall: type.caption,
        )
        .apply(
          bodyColor: palette.textPrimary,
          displayColor: palette.textPrimary,
        ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: palette.accent,
      selectionColor: palette.accent.withValues(alpha: 0.28),
      selectionHandleColor: palette.accent,
    ),
    tooltipTheme: TooltipThemeData(
      decoration: ShapeDecoration(
        color: palette.floatingSolid,
        shape: const RoundedSuperellipseBorder(borderRadius: Radii.small),
        shadows: [
          BoxShadow(
            color: palette.shadow,
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      textStyle: type.footnote.copyWith(color: palette.textPrimary),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      waitDuration: const Duration(milliseconds: 500),
    ),
    scrollbarTheme: ScrollbarThemeData(
      thumbColor: WidgetStatePropertyAll(palette.textTertiary),
      radius: const Radius.circular(8),
      thickness: const WidgetStatePropertyAll(6),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
      },
    ),
    appBarTheme: AppBarTheme(
      systemOverlayStyle: brightness == Brightness.dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
    ),
  );
}
