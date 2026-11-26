import 'package:material_ui/material_ui.dart';

import '../glass/glass_pressable.dart';
import '../glass/glass_surface.dart';
import '../theme/mindora_theme.dart';
import '../tokens/colors.dart';
import '../tokens/spacing.dart';

/// A titled group of rows on one glass card (settings-style list).
class GlassListSection extends StatelessWidget {
  const GlassListSection({
    super.key,
    this.title,
    this.footer,
    required this.children,
  });

  final String? title;
  final String? footer;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final type = context.type;
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      rows.add(children[i]);
      if (i < children.length - 1) {
        rows.add(
          Padding(
            padding: const EdgeInsetsDirectional.only(start: Space.l),
            child: Container(height: 0.6, color: palette.separator),
          ),
        );
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsetsDirectional.only(
              start: Space.l,
              bottom: Space.s,
            ),
            child: Semantics(
              header: true,
              child: Text(
                title!,
                style: type.subhead.copyWith(color: palette.textSecondary),
              ),
            ),
          ),
        GlassSurface(
          depth: GlassDepth.raised,
          borderRadius: Radii.medium,
          child: Column(mainAxisSize: MainAxisSize.min, children: rows),
        ),
        if (footer != null)
          Padding(
            padding: const EdgeInsetsDirectional.only(
              start: Space.l,
              end: Space.l,
              top: Space.s,
            ),
            child: Text(
              footer!,
              style: type.footnote.copyWith(color: palette.textTertiary),
            ),
          ),
      ],
    );
  }
}

/// A list row: leading, title + subtitle, trailing. Pressable when [onTap]
/// is set (shows a chevron unless [trailing] is given).
class GlassListRow extends StatelessWidget {
  const GlassListRow({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.showChevron,
    this.destructive = false,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool? showChevron;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final type = context.type;
    final chevron = showChevron ?? (onTap != null && trailing == null);

    final row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 52),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Space.l,
          vertical: Space.s + 2,
        ),
        child: Row(
          children: [
            if (leading != null) ...[
              IconTheme.merge(
                data: IconThemeData(color: palette.textSecondary, size: 22),
                child: leading!,
              ),
              const SizedBox(width: Space.m + 2),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: type.body.copyWith(
                      color: destructive
                          ? palette.accentInk
                          : palette.textPrimary,
                    ),
                  ),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        subtitle!,
                        style: type.footnote.copyWith(
                          color: palette.textSecondary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: Space.m),
              trailing!,
            ],
            if (chevron) ...[
              const SizedBox(width: Space.s),
              Icon(
                Directionality.of(context) == TextDirection.rtl
                    ? Icons.chevron_left_rounded
                    : Icons.chevron_right_rounded,
                color: palette.textTertiary,
                size: 22,
              ),
            ],
          ],
        ),
      ),
    );

    if (onTap == null) {
      return MergeSemantics(child: row);
    }
    return GlassPressable(
      onPressed: onTap,
      borderRadius: Radii.small,
      pressScale: 0.99,
      minSize: 0,
      child: row,
    );
  }
}
