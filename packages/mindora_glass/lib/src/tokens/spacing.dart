import 'package:flutter/painting.dart';

/// 4-pt spacing grid.
abstract final class Space {
  static const double xxs = 2;
  static const double xs = 4;
  static const double s = 8;
  static const double m = 12;
  static const double l = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 48;

  /// Default horizontal page gutter on phones.
  static const double gutter = 20;
}

/// Continuous-corner radii (rendered as superellipses).
abstract final class Radii {
  static const double s = 12;
  static const double m = 20;
  static const double l = 28;
  static const double full = 999;

  static const BorderRadius small = BorderRadius.all(Radius.circular(s));
  static const BorderRadius medium = BorderRadius.all(Radius.circular(m));
  static const BorderRadius large = BorderRadius.all(Radius.circular(l));
  static const BorderRadius pill = BorderRadius.all(Radius.circular(full));
}

/// Minimum interactive target (44 pt, Apple HIG / WCAG 2.5.8).
const double kMinTarget = 44;

/// Layout breakpoints for the adaptive shell.
abstract final class Breakpoints {
  /// Below this width: phone layout (bottom tab bar).
  static const double tablet = 700;

  /// At or above this width: full sidebar with labels.
  static const double desktop = 1100;
}
