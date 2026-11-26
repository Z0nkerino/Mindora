import 'package:material_ui/material_ui.dart';

import '../glass/glass_pressable.dart';
import '../glass/glass_surface.dart';
import '../theme/mindora_theme.dart';
import '../tokens/colors.dart';
import '../tokens/spacing.dart';

/// A glass card. Becomes pressable when [onTap] is set.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(Space.l),
    this.depth = GlassDepth.raised,
    this.borderRadius = Radii.large,
    this.semanticLabel,
    this.blur,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final GlassDepth depth;
  final BorderRadius borderRadius;
  final String? semanticLabel;
  final bool? blur;

  @override
  Widget build(BuildContext context) {
    final card = GlassSurface(
      depth: depth,
      borderRadius: borderRadius,
      padding: padding,
      blur: blur,
      child: child,
    );
    if (onTap == null) {
      return Semantics(container: true, label: semanticLabel, child: card);
    }
    return GlassPressable(
      onPressed: onTap,
      borderRadius: borderRadius,
      pressScale: 0.98,
      semanticLabel: semanticLabel,
      minSize: 0,
      child: card,
    );
  }
}

/// Card header row: title, optional trailing action.
class GlassCardHeader extends StatelessWidget {
  const GlassCardHeader({
    super.key,
    required this.title,
    this.icon,
    this.trailing,
  });

  final String title;
  final IconData? icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.m),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: palette.textSecondary),
            const SizedBox(width: Space.s),
          ],
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title,
                style: context.type.subhead.copyWith(
                  color: palette.textSecondary,
                ),
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
