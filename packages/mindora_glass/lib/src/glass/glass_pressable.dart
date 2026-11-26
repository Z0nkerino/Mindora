import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../motion/motion.dart';
import '../theme/glass_config.dart';
import '../theme/mindora_theme.dart';
import '../tokens/spacing.dart';

/// Shared interaction layer for every tappable glass element.
///
/// * spring "squish" on press (velocity-preserving, interruptible),
/// * hover highlight on pointer devices,
/// * visible focus ring for keyboard navigation (accent-ink),
/// * Enter / Space activation,
/// * button semantics for screen readers,
/// * minimum 44 pt hit target.
class GlassPressable extends StatefulWidget {
  const GlassPressable({
    super.key,
    required this.child,
    required this.onPressed,
    this.onLongPress,
    this.borderRadius = Radii.medium,
    this.pressScale = 0.965,
    this.semanticLabel,
    this.tooltip,
    this.selected,
    this.toggled,
    this.checked,
    this.focusNode,
    this.autofocus = false,
    this.showHover = true,
    this.isButton = true,
    this.minSize = kMinTarget,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final BorderRadius borderRadius;
  final double pressScale;
  final String? semanticLabel;
  final String? tooltip;
  final bool? selected;
  final bool? toggled;
  final bool? checked;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool showHover;
  final bool isButton;
  final double minSize;

  @override
  State<GlassPressable> createState() => _GlassPressableState();
}

class _GlassPressableState extends State<GlassPressable>
    with SingleTickerProviderStateMixin {
  late final SpringValue _scale = SpringValue(
    vsync: this,
    initial: 1,
    spring: MindoraSprings.snappy,
  );
  bool _hovered = false;
  bool _focused = false;

  bool get _enabled => widget.onPressed != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scale.reduceMotion = GlassConfig.of(context).reduceMotion;
  }

  @override
  void dispose() {
    _scale.dispose();
    super.dispose();
  }

  void _down() {
    if (!_enabled || _scale.reduceMotion) return;
    _scale.animateTo(widget.pressScale);
  }

  void _up() {
    if (_scale.reduceMotion) return;
    _scale.animateTo(1, spring: MindoraSprings.bouncy);
  }

  void _activate() {
    if (!_enabled) return;
    HapticFeedback.selectionClick();
    widget.onPressed!();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final shape = RoundedSuperellipseBorder(borderRadius: widget.borderRadius);

    Widget child = AnimatedBuilder(
      animation: _scale,
      builder: (context, child) => Transform.scale(
        scale: _scale.value,
        filterQuality: FilterQuality.medium,
        child: child,
      ),
      child: Stack(
        // Pass the parent's constraints straight to the child so wrapping a
        // widget in GlassPressable never changes its size or alignment.
        fit: StackFit.passthrough,
        children: [
          widget.child,
          if (widget.showHover)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedOpacity(
                  opacity: _hovered && _enabled ? 1 : 0,
                  duration: MindoraDurations.fade,
                  child: DecoratedBox(
                    decoration: ShapeDecoration(
                      color: palette.hoverOverlay,
                      shape: shape,
                    ),
                  ),
                ),
              ),
            ),
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: _focused ? 1 : 0,
                duration: MindoraDurations.instant,
                child: DecoratedBox(
                  decoration: ShapeDecoration(
                    shape: RoundedSuperellipseBorder(
                      borderRadius: widget.borderRadius,
                      side: BorderSide(
                        color: palette.accentInk,
                        width: 2,
                        strokeAlign: BorderSide.strokeAlignOutside,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    child = FocusableActionDetector(
      enabled: _enabled,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      mouseCursor: _enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            _activate();
            return null;
          },
        ),
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _down(),
        onTapUp: (_) => _up(),
        onTapCancel: _up,
        onTap: _enabled ? _activate : null,
        onLongPress: widget.onLongPress,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: widget.minSize,
            minHeight: widget.minSize,
          ),
          child: child,
        ),
      ),
    );

    child = Semantics(
      // Without an explicit label, the visible text inside becomes the label.
      container: widget.semanticLabel == null,
      button: widget.isButton,
      enabled: _enabled,
      selected: widget.selected,
      toggled: widget.toggled,
      checked: widget.checked,
      label: widget.semanticLabel,
      onTap: _enabled ? _activate : null,
      excludeSemantics: widget.semanticLabel != null,
      child: child,
    );
    if (widget.semanticLabel == null) child = MergeSemantics(child: child);

    if (widget.tooltip != null) {
      child = Tooltip(message: widget.tooltip!, child: child);
    }
    return child;
  }
}
