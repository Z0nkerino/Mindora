import 'dart:async';
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';

import '../motion/motion.dart';
import '../theme/glass_config.dart';

/// Loads and caches the liquid-pill fragment shader. Returns null when
/// shaders are unavailable (some test environments, old GPUs); callers then
/// fall back to a CPU-drawn shape.
abstract final class LiquidShader {
  static Future<ui.FragmentProgram?>? _future;
  static ui.FragmentProgram? _program;

  static ui.FragmentProgram? get program => _program;

  static Future<ui.FragmentProgram?> load() {
    return _future ??= () async {
      try {
        _program = await ui.FragmentProgram.fromAsset(
          'packages/mindora_glass/shaders/liquid_pill.frag',
        );
      } catch (e) {
        debugPrint('Mindora Glass: liquid shader unavailable ($e)');
        _program = null;
      }
      return _program;
    }();
  }

  /// Test hook: forget any loaded program.
  @visibleForTesting
  static void reset() {
    _future = null;
    _program = null;
  }
}

/// A selection indicator that flows between positions like a droplet.
///
/// The *head* follows the target on a stiff spring and the *tail* on a
/// softer one. While moving, the shape stretches between them and pinches
/// in the middle. In the `liquid` tier this is drawn by a fragment shader
/// (smooth-min of two signed-distance shapes with a specular rim); in other
/// tiers, or if shaders are unavailable, a stretched superellipse is drawn.
class LiquidIndicator extends StatefulWidget {
  const LiquidIndicator({
    super.key,
    required this.target,
    required this.color,
    this.radius = 999,
    this.axis = Axis.horizontal,
    this.shine = 1,
  });

  /// Target rectangle in this widget's local coordinates. Null hides it.
  final Rect? target;
  final Color color;
  final double radius;

  /// Main direction of travel (used to decide where the pinch happens).
  final Axis axis;

  /// Specular highlight strength, 0..1.
  final double shine;

  @override
  State<LiquidIndicator> createState() => _LiquidIndicatorState();
}

class _LiquidIndicatorState extends State<LiquidIndicator>
    with TickerProviderStateMixin {
  late final List<SpringValue> _head;
  late final List<SpringValue> _tail;
  bool _placed = false;

  @override
  void initState() {
    super.initState();
    SpringValue mk(SpringDescription s) => SpringValue(vsync: this, spring: s);
    _head = List.generate(4, (_) => mk(MindoraSprings.smooth));
    _tail = List.generate(4, (_) => mk(MindoraSprings.trailing));
    if (LiquidShader.program == null) {
      unawaited(
        LiquidShader.load().then((p) {
          if (mounted && p != null) setState(() {});
        }),
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = GlassConfig.of(context).reduceMotion;
    for (final s in [..._head, ..._tail]) {
      s.reduceMotion = reduce;
    }
    if (!_placed) _apply(widget.target, animate: false);
  }

  @override
  void didUpdateWidget(LiquidIndicator old) {
    super.didUpdateWidget(old);
    if (old.target != widget.target) {
      _apply(widget.target, animate: _placed);
    }
  }

  void _apply(Rect? r, {required bool animate}) {
    if (r == null) return;
    final v = [r.left, r.top, r.right, r.bottom];
    for (var i = 0; i < 4; i++) {
      if (animate) {
        _head[i].animateTo(v[i]);
        _tail[i].animateTo(v[i]);
      } else {
        _head[i].jumpTo(v[i]);
        _tail[i].jumpTo(v[i]);
      }
    }
    _placed = true;
  }

  @override
  void dispose() {
    for (final s in [..._head, ..._tail]) {
      s.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.target == null) return const SizedBox.shrink();
    final config = GlassConfig.of(context);
    final program = config.usesShaders ? LiquidShader.program : null;
    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: _LiquidPainter(
          repaint: Listenable.merge([..._head, ..._tail]),
          head: _head,
          tail: _tail,
          color: widget.color,
          radius: widget.radius,
          axis: widget.axis,
          shine: widget.shine,
          program: program,
        ),
      ),
    );
  }
}

class _LiquidPainter extends CustomPainter {
  _LiquidPainter({
    required Listenable repaint,
    required this.head,
    required this.tail,
    required this.color,
    required this.radius,
    required this.axis,
    required this.shine,
    required this.program,
  }) : super(repaint: repaint);

  final List<SpringValue> head;
  final List<SpringValue> tail;
  final Color color;
  final double radius;
  final Axis axis;
  final double shine;
  final ui.FragmentProgram? program;

  Rect _rect(List<SpringValue> v) =>
      Rect.fromLTRB(v[0].value, v[1].value, v[2].value, v[3].value);

  @override
  void paint(Canvas canvas, Size size) {
    final h = _rect(head);
    final t = _rect(tail);
    if (h.isEmpty && t.isEmpty) return;
    final union = h.expandToInclude(t);

    final program = this.program;
    if (program == null) {
      // CPU fallback: a stretched superellipse spanning head and tail.
      final r = Radius.circular(
        radius.clamp(0, union.shortestSide / 2).toDouble(),
      );
      canvas.drawRSuperellipse(
        ui.RSuperellipse.fromRectAndRadius(union, r),
        Paint()..color = color,
      );
      return;
    }

    // Bridge: the union of head and tail, pinched across the travel axis in
    // proportion to how far apart they are. Merged with the head by the
    // shader's smooth-min, this reads as a droplet in motion.
    final travel = axis == Axis.horizontal
        ? (union.width - h.width).abs()
        : (union.height - h.height).abs();
    final extent = axis == Axis.horizontal ? h.width : h.height;
    final pinch = (1 - (travel / (extent * 2.5)).clamp(0.0, 0.45)).toDouble();
    final bridge = axis == Axis.horizontal
        ? Rect.fromCenter(
            center: union.center,
            width: union.width,
            height: union.height * pinch,
          )
        : Rect.fromCenter(
            center: union.center,
            width: union.width * pinch,
            height: union.height,
          );

    final shader = program.fragmentShader();
    var i = 0;
    void f(double v) => shader.setFloat(i++, v);
    f(h.left);
    f(h.top);
    f(h.width);
    f(h.height);
    f(bridge.left);
    f(bridge.top);
    f(bridge.width);
    f(bridge.height);
    f(radius);
    f(h.shortestSide * 0.45); // smooth-min blend distance
    f(color.r);
    f(color.g);
    f(color.b);
    f(color.a);
    f(shine);

    canvas.drawRect(union.inflate(2), Paint()..shader = shader);
    shader.dispose();
  }

  @override
  bool shouldRepaint(_LiquidPainter old) =>
      old.color != color ||
      old.radius != radius ||
      old.axis != axis ||
      old.shine != shine ||
      old.program != program;
}
