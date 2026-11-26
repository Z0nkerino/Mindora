import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../brand/mindora_logo.dart';
import '../motion/motion.dart';
import '../theme/glass_config.dart';
import '../theme/mindora_theme.dart';
import '../tokens/spacing.dart';
import 'buttons.dart';

/// Animated progress ring (goals, habits, budgets). Progress is a spring,
/// so it glides when the value changes.
class GlassProgressRing extends StatefulWidget {
  const GlassProgressRing({
    super.key,
    required this.progress,
    this.size = 56,
    this.strokeWidth = 6,
    this.color,
    this.center,
    this.semanticLabel,
  });

  /// 0..1 (values above 1 render as a full ring).
  final double progress;
  final double size;
  final double strokeWidth;
  final Color? color;
  final Widget? center;
  final String? semanticLabel;

  @override
  State<GlassProgressRing> createState() => _GlassProgressRingState();
}

class _GlassProgressRingState extends State<GlassProgressRing>
    with SingleTickerProviderStateMixin {
  late final SpringValue _p = SpringValue(
    vsync: this,
    spring: MindoraSprings.gentle,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _p.reduceMotion = GlassConfig.of(context).reduceMotion;
    if (!_started) {
      _started = true;
      if (_p.reduceMotion) {
        _p.jumpTo(widget.progress);
      } else {
        _p.animateTo(widget.progress);
      }
    }
  }

  @override
  void didUpdateWidget(GlassProgressRing old) {
    super.didUpdateWidget(old);
    if (old.progress != widget.progress) _p.animateTo(widget.progress);
  }

  @override
  void dispose() {
    _p.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final pct = (widget.progress.clamp(0, 1) * 100).round();
    return Semantics(
      label: widget.semanticLabel,
      value: '$pct%',
      child: SizedBox.square(
        dimension: widget.size,
        child: AnimatedBuilder(
          animation: _p,
          builder: (context, child) => CustomPaint(
            painter: _RingPainter(
              progress: _p.value,
              stroke: widget.strokeWidth,
              track: palette.isDark
                  ? const Color(0x1FFFFFFF)
                  : const Color(0x14000000),
              color: widget.color ?? palette.accent,
            ),
            child: child,
          ),
          child: widget.center == null ? null : Center(child: widget.center),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.stroke,
    required this.track,
    required this.color,
  });

  final double progress;
  final double stroke;
  final Color track;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(stroke / 2);
    canvas.drawArc(
      rect,
      0,
      math.pi * 2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = track,
    );
    final p = progress.clamp(0.0, 1.0);
    if (p <= 0) return;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * p,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.stroke != stroke ||
      old.track != track ||
      old.color != color;
}

/// Loading placeholder with a soft travelling sheen (static when motion is
/// reduced).
class GlassSkeleton extends StatefulWidget {
  const GlassSkeleton({
    super.key,
    this.width,
    this.height = 14,
    this.borderRadius = Radii.small,
  });

  final double? width;
  final double height;
  final BorderRadius borderRadius;

  @override
  State<GlassSkeleton> createState() => _GlassSkeletonState();
}

class _GlassSkeletonState extends State<GlassSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (GlassConfig.of(context).reduceMotion) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final base = palette.isDark
        ? const Color(0x14FFFFFF)
        : const Color(0x0D000000);
    final hi = palette.isDark
        ? const Color(0x24FFFFFF)
        : const Color(0x17000000);
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final x = _c.value * 3 - 1;
          return Container(
            width: widget.width,
            height: widget.height,
            decoration: ShapeDecoration(
              shape: RoundedSuperellipseBorder(
                borderRadius: widget.borderRadius,
              ),
              gradient: LinearGradient(
                begin: Alignment(x - 1, 0),
                end: Alignment(x + 1, 0),
                colors: [base, hi, base],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Designed empty state. The illustration echoes the Mindora mark: three
/// slanted glass bars, one of them lit in the accent.
class GlassEmptyState extends StatelessWidget {
  const GlassEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon,
    this.actionLabel,
    this.onAction,
    this.litBar = 1,
  });

  final String title;
  final String message;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Which of the three illustration bars carries the accent (0–2).
  final int litBar;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final type = context.type;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Padding(
          padding: const EdgeInsets.all(Space.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 96,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    MindoraBarsIllustration(
                      height: 88,
                      litBar: litBar,
                      lit: palette.accent,
                      unlit: palette.isDark
                          ? const Color(0x1FFFFFFF)
                          : const Color(0x12000000),
                    ),
                    if (icon != null)
                      Icon(icon, size: 30, color: palette.textPrimary),
                  ],
                ),
              ),
              const SizedBox(height: Space.xxl),
              Semantics(
                header: true,
                child: Text(
                  title,
                  style: type.title2,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: Space.s),
              Text(
                message,
                style: type.callout.copyWith(color: palette.textSecondary),
                textAlign: TextAlign.center,
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: Space.xxl),
                GlassButton(
                  label: actionLabel!,
                  onPressed: onAction,
                  variant: GlassButtonVariant.primary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
