import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/semantics.dart';
import 'package:material_ui/material_ui.dart';

import '../glass/glass_surface.dart';
import '../motion/motion.dart';
import '../theme/glass_config.dart';
import '../theme/mindora_theme.dart';
import '../tokens/colors.dart';
import '../tokens/spacing.dart';
import 'buttons.dart';

/// Presents a glass sheet that slides up on a spring, stretches with
/// rubber-banding when pulled up, and dismisses when dragged down or
/// flicked. On wide screens it appears as a centred floating panel.
Future<T?> showGlassSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  String? barrierLabel,
  double maxWidth = 640,
}) {
  return Navigator.of(context).push<T>(
    _GlassSheetRoute<T>(
      builder: builder,
      barrierLabel:
          barrierLabel ??
          MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: context.palette.scrim,
      maxWidth: maxWidth,
      config: GlassConfig.of(context),
    ),
  );
}

class _GlassSheetRoute<T> extends PopupRoute<T> {
  _GlassSheetRoute({
    required this.builder,
    required this.barrierLabel,
    required this.barrierColor,
    required this.maxWidth,
    required this.config,
  });

  final WidgetBuilder builder;
  final double maxWidth;
  final GlassConfigData config;

  @override
  final String barrierLabel;

  @override
  final Color barrierColor;

  @override
  bool get barrierDismissible => true;

  @override
  Duration get transitionDuration => config.reduceMotion
      ? MindoraDurations.fade
      : const Duration(milliseconds: 520);

  @override
  Duration get reverseTransitionDuration => config.reduceMotion
      ? MindoraDurations.fade
      : const Duration(milliseconds: 280);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return _GlassSheetFrame(
      animation: animation,
      maxWidth: maxWidth,
      onDismiss: () => Navigator.of(context).maybePop(),
      child: Builder(builder: builder),
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => child;
}

/// Spring-shaped curve: overshoots slightly, like [MindoraSprings.gentle].
class _SpringCurve extends Curve {
  const _SpringCurve();
  @override
  double transformInternal(double t) {
    // Damped oscillation normalised to end at 1.
    return 1 - math.pow(math.e, -6.5 * t) * math.cos(8.5 * t);
  }
}

class _GlassSheetFrame extends StatefulWidget {
  const _GlassSheetFrame({
    required this.animation,
    required this.child,
    required this.maxWidth,
    required this.onDismiss,
  });

  final Animation<double> animation;
  final Widget child;
  final double maxWidth;
  final VoidCallback onDismiss;

  @override
  State<_GlassSheetFrame> createState() => _GlassSheetFrameState();
}

class _GlassSheetFrameState extends State<_GlassSheetFrame>
    with SingleTickerProviderStateMixin {
  late final SpringValue _drag = SpringValue(
    vsync: this,
    spring: MindoraSprings.smooth,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _drag.reduceMotion = GlassConfig.of(context).reduceMotion;
  }

  @override
  void dispose() {
    _drag.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails d) {
    final dy = d.primaryDelta ?? 0;
    // Rubber-band when pulling up past the rest position.
    final resistance = _drag.value < 0 ? 0.25 : 1.0;
    _drag.drag(dy * resistance);
  }

  void _onDragEnd(DragEndDetails d, double height) {
    final v = d.primaryVelocity ?? 0;
    if (_drag.value > height * 0.28 || v > 900) {
      widget.onDismiss();
      _drag.fling(height, v);
    } else {
      _drag.fling(0, v);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reduce = GlassConfig.of(context).reduceMotion;
    final media = MediaQuery.of(context);
    final wide = media.size.width >= Breakpoints.tablet;
    final curved = CurvedAnimation(
      parent: widget.animation,
      curve: reduce ? Curves.easeOut : const _SpringCurve(),
      reverseCurve: Curves.easeInCubic,
    );

    final radius = wide
        ? Radii.large
        : const BorderRadius.vertical(top: Radius.circular(Radii.l + 6));

    return LayoutBuilder(
      builder: (context, c) {
        final sheet = GlassSurface(
          depth: GlassDepth.floating,
          borderRadius: radius,
          child: SafeArea(
            top: false,
            bottom: !wide,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onVerticalDragUpdate: _onDragUpdate,
                  onVerticalDragEnd: (d) => _onDragEnd(d, c.maxHeight),
                  child: SizedBox(
                    height: 22,
                    width: double.infinity,
                    child: Center(
                      child: Container(
                        width: 36,
                        height: 5,
                        decoration: ShapeDecoration(
                          color: context.palette.textTertiary,
                          shape: const StadiumBorder(),
                        ),
                      ),
                    ),
                  ),
                ),
                Flexible(child: widget.child),
              ],
            ),
          ),
        );

        return AnimatedBuilder(
          animation: Listenable.merge([curved, _drag]),
          builder: (context, child) {
            final t = curved.value;
            final drag = _drag.value;
            final stretch = drag < 0 ? 1 + (-drag / 800) : 1.0;
            final offset = reduce
                ? Offset(0, (1 - t) * 24)
                : Offset(0, (1 - t) * c.maxHeight + math.max(drag, 0));
            return Opacity(
              opacity: reduce ? t.clamp(0, 1) : 1,
              child: Transform.translate(
                offset: offset,
                child: Transform.scale(
                  scaleY: stretch,
                  alignment: Alignment.bottomCenter,
                  child: child,
                ),
              ),
            );
          },
          child: Align(
            alignment: wide ? Alignment.center : Alignment.bottomCenter,
            child: Padding(
              padding: wide
                  ? const EdgeInsets.all(Space.xxl)
                  : EdgeInsets.only(top: media.padding.top + Space.xl),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: widget.maxWidth,
                  maxHeight: c.maxHeight * (wide ? 0.85 : 0.94),
                ),
                child: Padding(
                  padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
                  child: Material(
                    type: MaterialType.transparency,
                    child: sheet,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Standard sheet content layout: title row with close button, body.
class GlassSheetScaffold extends StatelessWidget {
  const GlassSheetScaffold({
    super.key,
    required this.title,
    required this.child,
    this.actions = const [],
    this.closeLabel = 'Close',
  });

  final String title;
  final Widget child;
  final List<Widget> actions;
  final String closeLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.xl, 0, Space.xl, Space.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(title, style: context.type.title2),
                ),
              ),
              ...actions,
              GlassIconButton(
                icon: Icons.close_rounded,
                label: closeLabel,
                size: 34,
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ],
          ),
          const SizedBox(height: Space.l),
          Flexible(child: SingleChildScrollView(child: child)),
        ],
      ),
    );
  }
}

/// A centred glass dialog with title, message and up to two actions.
Future<bool?> showGlassDialog({
  required BuildContext context,
  required String title,
  String? message,
  required String confirmLabel,
  String? cancelLabel,
  bool destructive = false,
}) {
  final reduce = GlassConfig.of(context).reduceMotion;
  return showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: context.palette.scrim,
    transitionDuration: reduce
        ? MindoraDurations.fade
        : const Duration(milliseconds: 380),
    pageBuilder: (context, _, _) {
      final palette = context.palette;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(Space.xxl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Material(
              type: MaterialType.transparency,
              child: GlassSurface(
                depth: GlassDepth.floating,
                borderRadius: Radii.large,
                padding: const EdgeInsets.all(Space.xxl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        title,
                        style: context.type.title2,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    if (message != null) ...[
                      const SizedBox(height: Space.s),
                      Text(
                        message,
                        style: context.type.callout.copyWith(
                          color: palette.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: Space.xxl),
                    GlassButton(
                      label: confirmLabel,
                      expand: true,
                      variant: destructive
                          ? GlassButtonVariant.destructive
                          : GlassButtonVariant.primary,
                      onPressed: () => Navigator.of(context).pop(true),
                    ),
                    if (cancelLabel != null) ...[
                      const SizedBox(height: Space.s),
                      GlassButton(
                        label: cancelLabel,
                        expand: true,
                        variant: GlassButtonVariant.ghost,
                        onPressed: () => Navigator.of(context).pop(false),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: reduce ? Curves.easeOut : Curves.easeOutBack,
        reverseCurve: Curves.easeIn,
      );
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: reduce
            ? child
            : ScaleTransition(
                scale: Tween(begin: 0.9, end: 1.0).animate(curved),
                child: child,
              ),
      );
    },
  );
}

/// Brief glass toast at the bottom (top on desktop is avoided to stay out of
/// the way of window chrome). Announced to screen readers.
void showGlassToast(
  BuildContext context,
  String message, {
  IconData? icon,
  Duration duration = const Duration(seconds: 3),
}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _GlassToast(
      message: message,
      icon: icon,
      duration: duration,
      onDone: () => entry.remove(),
    ),
  );
  overlay.insert(entry);
  SemanticsService.sendAnnouncement(
    View.of(context),
    message,
    Directionality.of(context),
  );
}

class _GlassToast extends StatefulWidget {
  const _GlassToast({
    required this.message,
    required this.icon,
    required this.duration,
    required this.onDone,
  });

  final String message;
  final IconData? icon;
  final Duration duration;
  final VoidCallback onDone;

  @override
  State<_GlassToast> createState() => _GlassToastState();
}

class _GlassToastState extends State<_GlassToast>
    with SingleTickerProviderStateMixin {
  late final SpringValue _t = SpringValue(
    vsync: this,
    spring: MindoraSprings.bouncy,
  );
  Timer? _timer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _t.reduceMotion = GlassConfig.of(context).reduceMotion;
    if (_timer == null) {
      _t.animateTo(1);
      _timer = Timer(widget.duration, () async {
        if (!mounted) return;
        await _t
            .animateTo(0, spring: MindoraSprings.snappy)
            .orCancel
            .catchError((_) {});
        widget.onDone();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final bottom = MediaQuery.paddingOf(context).bottom + 96;
    return Positioned(
      left: Space.l,
      right: Space.l,
      bottom: bottom,
      child: AnimatedBuilder(
        animation: _t,
        builder: (context, child) => Opacity(
          opacity: _t.value.clamp(0, 1),
          child: Transform.translate(
            offset: Offset(0, (1 - _t.value) * 30),
            child: child,
          ),
        ),
        child: Center(
          child: Material(
            type: MaterialType.transparency,
            child: GlassSurface(
              depth: GlassDepth.floating,
              borderRadius: Radii.pill,
              padding: const EdgeInsets.symmetric(
                horizontal: Space.xl,
                vertical: Space.m,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon, size: 18, color: palette.accentInk),
                    const SizedBox(width: Space.s),
                  ],
                  Flexible(
                    child: Text(
                      widget.message,
                      style: context.type.subhead.copyWith(
                        color: palette.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
