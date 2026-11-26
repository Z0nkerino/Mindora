import 'package:material_ui/material_ui.dart';

import '../glass/glass_pressable.dart';
import '../glass/glass_surface.dart';
import '../theme/mindora_theme.dart';
import '../tokens/colors.dart';
import '../tokens/spacing.dart';

enum GlassButtonVariant {
  /// The one main action on a screen. Accent fill.
  primary,

  /// Neutral glass button.
  secondary,

  /// Text-only, for low-emphasis actions.
  ghost,

  /// Destructive action (accent-ink text on glass, never a red fill).
  destructive,
}

enum GlassButtonSize { large, regular, compact }

/// Mindora button.
///
/// Contrast rule: a filled accent background is only used for the *large*
/// primary button, whose 19 px bold label is WCAG "large text" (white on
/// #FF0051 = 3.91:1 ≥ 3:1). Smaller primary buttons use an accent-soft
/// tint with accent-ink text instead, which passes 4.5:1.
class GlassButton extends StatelessWidget {
  const GlassButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = GlassButtonVariant.secondary,
    this.size = GlassButtonSize.regular,
    this.expand = false,
    this.tooltip,
  });

  const GlassButton.primary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.size = GlassButtonSize.large,
    this.expand = false,
    this.tooltip,
  }) : variant = GlassButtonVariant.primary;

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final GlassButtonVariant variant;
  final GlassButtonSize size;
  final bool expand;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final type = context.type;
    final enabled = onPressed != null;

    final height = switch (size) {
      GlassButtonSize.large => 54.0,
      GlassButtonSize.regular => 44.0,
      GlassButtonSize.compact => 34.0,
    };
    final radius = BorderRadius.circular(height / 2);
    final filled =
        variant == GlassButtonVariant.primary && size == GlassButtonSize.large;

    final Color fg = switch (variant) {
      GlassButtonVariant.primary =>
        filled ? palette.onAccent : palette.accentInk,
      GlassButtonVariant.secondary => palette.textPrimary,
      GlassButtonVariant.ghost => palette.textPrimary,
      GlassButtonVariant.destructive => palette.accentInk,
    };

    final TextStyle style = switch (size) {
      GlassButtonSize.large => filled ? type.accentLabel : type.headline,
      GlassButtonSize.regular => type.headline,
      GlassButtonSize.compact => type.subhead,
    };

    final content = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: size == GlassButtonSize.compact ? Space.m : Space.xl,
      ),
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: size == GlassButtonSize.compact ? 17 : 20,
              color: fg,
            ),
            const SizedBox(width: Space.s),
          ],
          Flexible(
            child: Text(
              label,
              style: style.copyWith(color: fg),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );

    Widget surface;
    if (filled) {
      surface = DecoratedBox(
        decoration: ShapeDecoration(
          color: palette.accent,
          shape: RoundedSuperellipseBorder(borderRadius: radius),
          shadows: [
            BoxShadow(
              color: palette.accent.withValues(alpha: 0.35),
              blurRadius: 18,
              spreadRadius: -6,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: CustomPaint(
          foregroundPainter: GlassRimPainter(
            borderRadius: radius,
            highlight: const Color(0x80FFFFFF),
            shade: const Color(0x14000000),
            hairline: Colors.transparent,
          ),
          child: content,
        ),
      );
    } else if (variant == GlassButtonVariant.ghost) {
      surface = content;
    } else {
      surface = GlassSurface(
        depth: GlassDepth.raised,
        borderRadius: radius,
        tint: variant == GlassButtonVariant.primary ? palette.accentSoft : null,
        child: content,
      );
    }

    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: GlassPressable(
        onPressed: onPressed,
        borderRadius: radius,
        semanticLabel: label,
        tooltip: tooltip,
        minSize: 0,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: height < kMinTarget ? kMinTarget : height,
          ),
          child: Center(
            widthFactor: expand ? null : 1,
            child: SizedBox(
              height: height,
              width: expand ? double.infinity : null,
              child: surface,
            ),
          ),
        ),
      ),
    );
  }
}

/// Circular icon-only button. Always has a semantic label / tooltip.
class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.size = 40,
    this.glass = true,
    this.selected = false,
    this.color,
  });

  final IconData icon;

  /// Accessible label; also shown as a tooltip on pointer devices.
  final String label;
  final VoidCallback? onPressed;
  final double size;
  final bool glass;
  final bool selected;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final radius = BorderRadius.circular(size / 2);
    final iconWidget = Icon(
      icon,
      size: size * 0.5,
      color: color ?? (selected ? palette.accentInk : palette.textPrimary),
    );
    return Opacity(
      opacity: onPressed == null ? 0.4 : 1,
      child: GlassPressable(
        onPressed: onPressed,
        borderRadius: radius,
        semanticLabel: label,
        tooltip: label,
        selected: selected,
        pressScale: 0.9,
        child: Center(
          widthFactor: 1,
          heightFactor: 1,
          child: SizedBox.square(
            dimension: size,
            child: glass
                ? GlassSurface(
                    depth: GlassDepth.raised,
                    borderRadius: radius,
                    tint: selected ? palette.accentSoft : null,
                    child: Center(child: iconWidget),
                  )
                : Center(child: iconWidget),
          ),
        ),
      ),
    );
  }
}
