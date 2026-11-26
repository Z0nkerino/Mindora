import 'package:flutter/foundation.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

import '../theme/glass_config.dart';

/// Spring tokens. Every animated value in Mindora uses one of these, so the
/// whole app shares one physical "feel".
abstract final class MindoraSprings {
  /// Quick, crisp response for presses and toggles.
  static const SpringDescription snappy = SpringDescription(
    mass: 1,
    stiffness: 520,
    damping: 38,
  );

  /// Default for layout changes and selection indicators.
  static const SpringDescription smooth = SpringDescription(
    mass: 1,
    stiffness: 300,
    damping: 30,
  );

  /// Slight overshoot for playful moments (completing, morphing).
  static const SpringDescription bouncy = SpringDescription(
    mass: 1,
    stiffness: 260,
    damping: 18,
  );

  /// Slow and soft for large surfaces (sheets, page transitions).
  static const SpringDescription gentle = SpringDescription(
    mass: 1,
    stiffness: 170,
    damping: 26,
  );

  /// The lagging edge of a liquid indicator: softer than [smooth] so the
  /// shape stretches like a droplet while moving.
  static const SpringDescription trailing = SpringDescription(
    mass: 1,
    stiffness: 150,
    damping: 22,
  );
}

/// Fallback durations, used when Reduce Motion is on (crossfades only).
abstract final class MindoraDurations {
  static const Duration instant = Duration(milliseconds: 90);
  static const Duration fade = Duration(milliseconds: 180);
  static const Duration page = Duration(milliseconds: 320);
}

/// An unbounded value driven by spring physics. Retargeting mid-flight keeps
/// the current velocity, so interrupted gestures and rapid taps never jump.
///
/// When [reduceMotion] is true, changes are applied with a short linear
/// tween instead.
class SpringValue extends ChangeNotifier implements ValueListenable<double> {
  SpringValue({
    required TickerProvider vsync,
    double initial = 0,
    this.spring = MindoraSprings.smooth,
  }) : _controller = AnimationController.unbounded(
         vsync: vsync,
         value: initial,
       ) {
    _controller.addListener(notifyListeners);
  }

  final AnimationController _controller;
  SpringDescription spring;
  bool reduceMotion = false;
  double _target = 0;

  @override
  double get value => _controller.value;

  double get target => _target;
  double get velocity => _controller.velocity;
  bool get isAnimating => _controller.isAnimating;

  /// Animates towards [target], preserving current velocity.
  TickerFuture animateTo(double target, {SpringDescription? spring}) {
    _target = target;
    if (reduceMotion) {
      return _controller.animateTo(
        target,
        duration: MindoraDurations.instant,
        curve: Curves.linear,
      );
    }
    final sim = SpringSimulation(
      spring ?? this.spring,
      _controller.value,
      target,
      _controller.velocity,
      tolerance: const Tolerance(distance: 0.001, velocity: 0.01),
    );
    return _controller.animateWith(sim);
  }

  /// Jumps to [v] without animating.
  void jumpTo(double v) {
    _target = v;
    _controller.value = v;
  }

  /// Adds a gesture-driven offset (e.g. while dragging).
  void drag(double delta) {
    _controller.stop();
    _controller.value += delta;
  }

  /// Flings towards [target] with an explicit starting [velocity].
  TickerFuture fling(double target, double velocity) {
    _target = target;
    if (reduceMotion) return animateTo(target);
    final sim = SpringSimulation(spring, _controller.value, target, velocity);
    return _controller.animateWith(sim);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

/// Convenience: whether animations should be reduced in this context
/// (OS setting or in-app override).
bool reduceMotionOf(BuildContext context) =>
    GlassConfig.of(context).reduceMotion;

/// Picks [spring] normally, or a near-critically damped quick spring when
/// motion is reduced.
SpringDescription springFor(BuildContext context, SpringDescription spring) =>
    reduceMotionOf(context) ? MindoraSprings.snappy : spring;
