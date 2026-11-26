import 'package:material_ui/material_ui.dart';

import '../glass/glass_pressable.dart';
import '../glass/glass_surface.dart';
import '../glass/liquid_indicator.dart';
import '../theme/mindora_theme.dart';
import '../tokens/colors.dart';
import '../tokens/spacing.dart';
import '../tokens/typography.dart';

/// One navigation destination (tab bar or sidebar).
class GlassNavItem {
  const GlassNavItem({
    required this.icon,
    required this.label,
    this.selectedIcon,
    this.shortcutHint,
    this.dividerBefore = false,
  });

  final IconData icon;
  final IconData? selectedIcon;
  final String label;

  /// Shown on hover in the sidebar, e.g. "⌘1".
  final String? shortcutHint;

  /// Sidebar only: draws a separator above this item.
  final bool dividerBefore;
}

/// Floating glass tab bar for phones. The selection is a liquid droplet that
/// flows between tabs.
class GlassTabBar extends StatelessWidget {
  const GlassTabBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<GlassNavItem> items;

  /// May be -1 when the current page isn't one of the tabs.
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const double height = 64;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final type = context.type;
    const pad = 6.0;

    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: GlassSurface(
        depth: GlassDepth.floating,
        borderRadius: BorderRadius.circular(height / 2),
        child: SizedBox(
          height: height,
          child: LayoutBuilder(
            builder: (context, c) {
              final w = (c.maxWidth - pad * 2) / items.length;
              final target = selectedIndex < 0
                  ? null
                  : Rect.fromLTWH(
                      pad + w * selectedIndex,
                      pad,
                      w,
                      height - pad * 2,
                    );
              return Stack(
                children: [
                  Positioned.fill(
                    child: LiquidIndicator(
                      target: target,
                      color: palette.accentSoft,
                      shine: palette.isDark ? 0.5 : 0.25,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(pad),
                    child: Row(
                      children: [
                        for (var i = 0; i < items.length; i++)
                          Expanded(
                            child: _TabButton(
                              item: items[i],
                              selected: i == selectedIndex,
                              onTap: () => onSelected(i),
                              palette: palette,
                              labelStyle: type.caption,
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

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.item,
    required this.selected,
    required this.onTap,
    required this.palette,
    required this.labelStyle,
  });

  final GlassNavItem item;
  final bool selected;
  final VoidCallback onTap;
  final MindoraPalette palette;
  final TextStyle labelStyle;

  @override
  Widget build(BuildContext context) {
    final color = selected ? palette.accentInk : palette.textSecondary;
    return GlassPressable(
      onPressed: onTap,
      borderRadius: Radii.pill,
      selected: selected,
      semanticLabel: item.label,
      showHover: !selected,
      pressScale: 0.9,
      minSize: 0,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            selected ? (item.selectedIcon ?? item.icon) : item.icon,
            size: 23,
            color: color,
          ),
          const SizedBox(height: 2),
          Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.fade,
            softWrap: false,
            style: labelStyle.copyWith(
              color: color,
              fontSize: 11,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Glass sidebar for tablets and desktops. Collapses to an icon rail.
class GlassSidebar extends StatelessWidget {
  const GlassSidebar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    this.header,
    this.footer,
    this.collapsed = false,
  });

  final List<GlassNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final Widget? header;
  final Widget? footer;
  final bool collapsed;

  static const double rowHeight = 40;
  static const double dividerHeight = 17;
  static const double expandedWidth = 248;
  static const double collapsedWidth = 76;

  double _offsetOf(int index) {
    var y = 0.0;
    for (var i = 0; i <= index && i < items.length; i++) {
      if (items[i].dividerBefore) y += dividerHeight;
      if (i < index) y += rowHeight + 2;
    }
    return y;
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final type = context.type;
    const hPad = Space.m;

    final list = LayoutBuilder(
      builder: (context, c) {
        final target = selectedIndex < 0
            ? null
            : Rect.fromLTWH(0, _offsetOf(selectedIndex), c.maxWidth, rowHeight);
        return SingleChildScrollView(
          child: Stack(
            children: [
              Positioned.fill(
                child: LiquidIndicator(
                  target: target,
                  axis: Axis.vertical,
                  radius: 12,
                  color: palette.accentSoft,
                  shine: palette.isDark ? 0.45 : 0.2,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < items.length; i++) ...[
                    if (items[i].dividerBefore)
                      SizedBox(
                        height: dividerHeight,
                        child: Center(
                          child: Container(
                            height: 1,
                            margin: const EdgeInsets.symmetric(
                              horizontal: Space.s,
                            ),
                            color: palette.separator,
                          ),
                        ),
                      ),
                    _SidebarRow(
                      item: items[i],
                      selected: i == selectedIndex,
                      collapsed: collapsed,
                      onTap: () => onSelected(i),
                      palette: palette,
                      type: type,
                    ),
                    if (i < items.length - 1) const SizedBox(height: 2),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );

    return Padding(
      padding: const EdgeInsets.all(Space.s),
      child: GlassSurface(
        depth: GlassDepth.floating,
        borderRadius: Radii.large,
        child: SizedBox(
          width: (collapsed ? collapsedWidth : expandedWidth) - Space.s * 2,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(hPad, Space.l, hPad, Space.m),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (header != null) ...[
                  header!,
                  const SizedBox(height: Space.l),
                ],
                Expanded(child: list),
                if (footer != null) ...[
                  const SizedBox(height: Space.s),
                  footer!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarRow extends StatelessWidget {
  const _SidebarRow({
    required this.item,
    required this.selected,
    required this.collapsed,
    required this.onTap,
    required this.palette,
    required this.type,
  });

  final GlassNavItem item;
  final bool selected;
  final bool collapsed;
  final VoidCallback onTap;
  final MindoraPalette palette;
  final MindoraTypography type;

  @override
  Widget build(BuildContext context) {
    final color = selected ? palette.accentInk : palette.textPrimary;
    final icon = Icon(
      selected ? (item.selectedIcon ?? item.icon) : item.icon,
      size: 20,
      color: selected ? palette.accentInk : palette.textSecondary,
    );
    return GlassPressable(
      onPressed: onTap,
      borderRadius: Radii.small,
      selected: selected,
      semanticLabel: item.label,
      tooltip: collapsed ? item.label : null,
      showHover: !selected,
      pressScale: 0.97,
      minSize: 0,
      child: SizedBox(
        height: GlassSidebar.rowHeight,
        child: collapsed
            ? Center(child: icon)
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: Space.m),
                child: Row(
                  children: [
                    icon,
                    const SizedBox(width: Space.m),
                    Expanded(
                      child: Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: type.callout.copyWith(
                          color: color,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                    if (item.shortcutHint != null)
                      Text(
                        item.shortcutHint!,
                        style: type.caption.copyWith(
                          color: palette.textTertiary,
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}
