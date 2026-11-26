import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// Mindora type scale. Uses the platform system font (SF Pro on Apple,
/// Roboto on Android, Segoe UI Variable on Windows) unless [fontFamily] is
/// set — the web build bundles Inter so it never fetches fonts from a CDN.
///
/// Sizes are logical pixels before text scaling. All styles scale with the
/// OS text-size setting (Dynamic Type) up to 200 %.
@immutable
class MindoraTypography {
  const MindoraTypography({this.fontFamily, this.fontFamilyFallback});

  final String? fontFamily;
  final List<String>? fontFamilyFallback;

  TextStyle _s(double size, FontWeight w, double height, double tracking) =>
      TextStyle(
        fontFamily: fontFamily,
        fontFamilyFallback: fontFamilyFallback,
        fontSize: size,
        fontWeight: w,
        height: height,
        letterSpacing: tracking,
        leadingDistribution: TextLeadingDistribution.even,
      );

  /// Big screen titles ("Today").
  TextStyle get display => _s(34, FontWeight.w700, 1.12, -0.6);

  /// Section and sheet titles.
  TextStyle get title1 => _s(28, FontWeight.w700, 1.15, -0.4);
  TextStyle get title2 => _s(22, FontWeight.w600, 1.2, -0.25);

  /// Emphasised body (row titles, button labels).
  TextStyle get headline => _s(17, FontWeight.w600, 1.3, -0.2);
  TextStyle get body => _s(17, FontWeight.w400, 1.35, -0.2);
  TextStyle get callout => _s(15, FontWeight.w400, 1.35, -0.1);
  TextStyle get subhead => _s(15, FontWeight.w600, 1.3, -0.1);
  TextStyle get footnote => _s(13, FontWeight.w400, 1.35, 0);
  TextStyle get caption => _s(12, FontWeight.w500, 1.3, 0.1);

  /// Large bold label for text on accent fills. 19 px bold counts as
  /// "large text" under WCAG, so white on #FF0051 (3.91:1) passes AA.
  TextStyle get accentLabel => _s(19, FontWeight.w700, 1.2, -0.2);
}
