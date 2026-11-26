import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/physics.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindora_glass/mindora_glass.dart';

void main() {
  testWidgets('SpringValue settles on its target', (tester) async {
    final v = SpringValue(
      vsync: const TestVSync(),
      spring: MindoraSprings.smooth,
    );
    addTearDown(v.dispose);
    unawaited(v.animateTo(100));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(v.value, closeTo(100, 0.01));
    expect(v.isAnimating, isFalse);
  });

  testWidgets('retargeting mid-flight preserves velocity (no jump)', (
    tester,
  ) async {
    final v = SpringValue(
      vsync: const TestVSync(),
      spring: MindoraSprings.smooth,
    );
    addTearDown(v.dispose);
    unawaited(v.animateTo(100));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    final before = v.value;
    final velocity = v.velocity;
    expect(velocity, greaterThan(0));
    unawaited(v.animateTo(0));
    await tester.pump(const Duration(milliseconds: 1));
    // Still moving forward briefly: momentum carried over.
    expect(v.value, greaterThanOrEqualTo(before - 0.5));
  });

  testWidgets('reduce motion finishes almost immediately', (tester) async {
    final v = SpringValue(vsync: const TestVSync())..reduceMotion = true;
    addTearDown(v.dispose);
    unawaited(v.animateTo(1));
    await tester.pump();
    await tester.pump(
      MindoraDurations.instant + const Duration(milliseconds: 1),
    );
    expect(v.value, 1);
  });

  test(
    'bouncy spring is underdamped, gentle/smooth are not overly springy',
    () {
      double ratio(SpringDescription s) =>
          s.damping / (2 * math.sqrt(s.mass * s.stiffness));
      expect(ratio(MindoraSprings.bouncy), lessThan(1));
      expect(ratio(MindoraSprings.smooth), greaterThan(0.8));
      expect(ratio(MindoraSprings.snappy), greaterThan(0.8));
    },
  );

  test('ticker provider sanity', () {
    expect(const TestVSync(), isA<TickerProvider>());
  });
}
