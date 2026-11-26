import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../glass/glass_pressable.dart';
import '../glass/glass_surface.dart';
import '../glass/liquid_indicator.dart';
import '../motion/motion.dart';
import '../theme/glass_config.dart';
import '../theme/mindora_theme.dart';
import '../tokens/colors.dart';
import '../tokens/spacing.dart';

class GlassSegment<T> {
  const GlassSegment({required this.value, required this.label, this.icon});
  final T value;
  final String label;
  final IconData? icon;
}

/// Segmented control. The selection is a liquid pill that flows between
/// segments.
class GlassSegmented<T> extends StatelessWidget {
  const GlassSegmented({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
    this.semanticLabel,
  });

  final List<GlassSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final type = context.type;
    final index = segments.indexWhere((s) => s.value == selected);
    const pad = 3.0;
    const height = 40.0;

    return Semantics(
      container: true,
      label: semanticLabel,
      child: GlassSurface(
        depth: GlassDepth.inset,
        borderRadius: Radii.pill,
        child: SizedBox(
          height: height,
          child: LayoutBuilder(
            builder: (context, c) {
              final w = (c.maxWidth - pad * 2) / segments.length;
              final target = index < 0
                  ? null
                  : Rect.fromLTWH(pad + w * index, pad, w, height - pad * 2);
              return Stack(
                children: [
                  Positioned.fill(
                    child: LiquidIndicator(
                      target: target,
                      color: palette.isDark
                          ? const Color(0x33FFFFFF)
                          : const Color(0xFFFFFFFF),
                      shine: palette.isDark ? 0.6 : 0.2,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(pad),
                    child: Row(
                      children: [
                        for (final s in segments)
                          Expanded(
                            child: GlassPressable(
                              onPressed: () => onChanged(s.value),
                              borderRadius: Radii.pill,
                              selected: s.value == selected,
                              semanticLabel: s.label,
                              showHover: s.value != selected,
                              minSize: 0,
                              child: Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (s.icon != null) ...[
                                      Icon(
                                        s.icon,
                                        size: 16,
                                        color: s.value == selected
                                            ? palette.textPrimary
                                            : palette.textSecondary,
                                      ),
                                      const SizedBox(width: 6),
                                    ],
                                    Flexible(
                                      child: Text(
                                        s.label,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: type.subhead.copyWith(
                                          color: s.value == selected
                                              ? palette.textPrimary
                                              : palette.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// On/off switch. The knob springs across and stretches while pressed.
class GlassSwitch extends StatefulWidget {
  const GlassSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.semanticLabel,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? semanticLabel;

  @override
  State<GlassSwitch> createState() => _GlassSwitchState();
}

class _GlassSwitchState extends State<GlassSwitch>
    with TickerProviderStateMixin {
  late final SpringValue _t = SpringValue(
    vsync: this,
    initial: widget.value ? 1 : 0,
    spring: MindoraSprings.bouncy,
  );
  late final SpringValue _press = SpringValue(
    vsync: this,
    spring: MindoraSprings.snappy,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final r = GlassConfig.of(context).reduceMotion;
    _t.reduceMotion = r;
    _press.reduceMotion = r;
  }

  @override
  void didUpdateWidget(GlassSwitch old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) _t.animateTo(widget.value ? 1 : 0);
  }

  @override
  void dispose() {
    _t.dispose();
    _press.dispose();
    super.dispose();
  }

  void _toggle() {
    if (widget.onChanged == null) return;
    HapticFeedback.lightImpact();
    widget.onChanged!(!widget.value);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    const w = 52.0, h = 32.0, knob = 26.0;
    return Semantics(
      toggled: widget.value,
      enabled: widget.onChanged != null,
      label: widget.semanticLabel,
      child: Opacity(
        opacity: widget.onChanged == null ? 0.4 : 1,
        child: GlassPressable(
          onPressed: widget.onChanged == null ? null : _toggle,
          borderRadius: Radii.pill,
          pressScale: 1,
          isButton: false,
          showHover: false,
          child: Listener(
            onPointerDown: (_) => _press.animateTo(1),
            onPointerUp: (_) => _press.animateTo(0),
            onPointerCancel: (_) => _press.animateTo(0),
            child: Center(
              child: AnimatedBuilder(
                animation: Listenable.merge([_t, _press]),
                builder: (context, _) {
                  final t = _t.value;
                  final stretch = 6 * _press.value.clamp(0, 1);
                  final kw = knob + stretch;
                  final travel = w - kw - 6;
                  final left = 3 + travel * t.clamp(0, 1);
                  final off = palette.isDark
                      ? const Color(0x33FFFFFF)
                      : const Color(0x24000000);
                  final track = Color.lerp(off, palette.accent, t.clamp(0, 1))!;
                  return SizedBox(
                    width: w,
                    height: h,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: ShapeDecoration(
                              color: track,
                              shape: const StadiumBorder(),
                            ),
                          ),
                        ),
                        Positioned(
                          left: left,
                          top: 3,
                          child: Container(
                            width: kw,
                            height: knob,
                            decoration: ShapeDecoration(
                              color: Colors.white,
                              shape: const StadiumBorder(),
                              shadows: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.22),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Round checkbox with an animated tick — used for tasks and habits.
class GlassCheckbox extends StatefulWidget {
  const GlassCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.size = 24,
    this.semanticLabel,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final double size;
  final String? semanticLabel;

  @override
  State<GlassCheckbox> createState() => _GlassCheckboxState();
}

class _GlassCheckboxState extends State<GlassCheckbox>
    with SingleTickerProviderStateMixin {
  late final SpringValue _t = SpringValue(
    vsync: this,
    initial: widget.value ? 1 : 0,
    spring: MindoraSprings.bouncy,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _t.reduceMotion = GlassConfig.of(context).reduceMotion;
  }

  @override
  void didUpdateWidget(GlassCheckbox old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) _t.animateTo(widget.value ? 1 : 0);
  }

  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Semantics(
      checked: widget.value,
      label: widget.semanticLabel,
      child: GlassPressable(
        onPressed: widget.onChanged == null
            ? null
            : () {
                HapticFeedback.lightImpact();
                widget.onChanged!(!widget.value);
              },
        borderRadius: Radii.pill,
        pressScale: 0.85,
        isButton: false,
        showHover: false,
        child: Center(
          child: AnimatedBuilder(
            animation: _t,
            builder: (context, _) => CustomPaint(
              size: Size.square(widget.size),
              painter: _CheckPainter(
                t: _t.value,
                ring: palette.textTertiary,
                fill: palette.accent,
                tick: palette.onAccent,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  _CheckPainter({
    required this.t,
    required this.ring,
    required this.fill,
    required this.tick,
  });

  final double t;
  final Color ring;
  final Color fill;
  final Color tick;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    final p = t.clamp(0.0, 1.0);

    canvas.drawCircle(
      c,
      r - 1,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = ring.withValues(alpha: ring.a * (1 - p)),
    );
    if (p <= 0) return;
    // Fill grows with a slight overshoot (t can exceed 1 on the bouncy spring).
    canvas.drawCircle(
      c,
      (r * math.min(t, 1.12)).clamp(0, r * 1.12),
      Paint()..color = fill,
    );

    // Tick draws itself along its path.
    final path = Path()
      ..moveTo(size.width * 0.28, size.height * 0.53)
      ..lineTo(size.width * 0.44, size.height * 0.68)
      ..lineTo(size.width * 0.73, size.height * 0.36);
    final metric = path.computeMetrics().first;
    final drawn = metric.extractPath(0, metric.length * p);
    canvas.drawPath(
      drawn,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.1
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = tick,
    );
  }

  @override
  bool shouldRepaint(_CheckPainter old) =>
      old.t != t || old.ring != ring || old.fill != fill || old.tick != tick;
}

/// Small selectable chip (tags, filters).
class GlassChip extends StatelessWidget {
  const GlassChip({
    super.key,
    required this.label,
    this.icon,
    this.selected = false,
    this.onPressed,
  });

  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final fg = selected ? palette.accentInk : palette.textSecondary;
    return GlassPressable(
      onPressed: onPressed,
      borderRadius: Radii.pill,
      selected: selected,
      semanticLabel: label,
      minSize: 0,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: kMinTarget),
        child: Center(
          widthFactor: 1,
          child: AnimatedContainer(
            duration: MindoraDurations.fade,
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: Space.m),
            decoration: ShapeDecoration(
              color: selected ? palette.accentSoft : palette.insetFill,
              shape: const StadiumBorder(),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 15, color: fg),
                  const SizedBox(width: 6),
                ],
                Text(label, style: context.type.subhead.copyWith(color: fg)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
