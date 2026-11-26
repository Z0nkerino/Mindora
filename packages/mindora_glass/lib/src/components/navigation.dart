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
              final target = selectedIndex < 0 || selectedIndex >= items.length
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
      // Tab labels cap text scaling (as system tab bars do) and scale down
      // rather than overflow the fixed-height bar. Full-size labels remain
      // available to screen readers through the semantic label.
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.35,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
        ),
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
    this.pinnedItems = const [],
    this.header,
    this.footer,
    this.collapsed = false,
  });

  /// Main destinations. They compact, then scroll, when the window is short.
  final List<GlassNavItem> items;

  /// Destinations pinned to the bottom (e.g. Settings): always visible.
  final List<GlassNavItem> pinnedItems;

  /// Index into `[...items, ...pinnedItems]`; -1 for none.
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final Widget? header;
  final Widget? footer;
  final bool collapsed;

  /// Preferred and minimum row heights. Rows shrink towards [minRowHeight]
  /// when the window is short, so every item stays visible; below that the
  /// list scrolls.
  static const double rowHeight = 40;
  static const double minRowHeight = 30;
  static const double dividerHeight = 17;
  static const double compactDividerHeight = 9;

  /// (row height, divider height) that best fit all items into [available].
  /// Dividers compact first, then rows shrink down to [minRowHeight].
  (double, double) fittedMetrics(double available) {
    final dividers = items.where((i) => i.dividerBefore).length;
    final gaps = (items.length - 1) * 2.0;
    double fit(double divider) =>
        (available - dividers * divider - gaps) / items.length;
    if (fit(dividerHeight) >= rowHeight) return (rowHeight, dividerHeight);
    final row = fit(compactDividerHeight).clamp(minRowHeight, rowHeight);
    return (row.toDouble(), compactDividerHeight);
  }

  static const double expandedWidth = 248;
  static const double collapsedWidth = 76;

  double _offsetOf(int index, double rowHeight, double dividerHeight) {
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
        final (rowH, dividerH) = fittedMetrics(c.maxHeight);
        final contentH =
            items.length * rowH +
            (items.length - 1) * 2 +
            items.where((i) => i.dividerBefore).length * dividerH;
        final scrolls = contentH > c.maxHeight + 0.5;
        final target = selectedIndex < 0
            ? null
            : Rect.fromLTWH(
                0,
                _offsetOf(selectedIndex, rowH, dividerH),
                c.maxWidth,
                rowH,
              );
        final list = SingleChildScrollView(
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
                        height: dividerH,
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
                      height: rowH,
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
        if (!scrolls) return list;
        // Still too tall: fade the bottom edge so it reads as scrollable.
        return ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (r) => const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF000000), Color(0xFF000000), Color(0x00000000)],
            stops: [0, 0.88, 1],
          ).createShader(r),
          child: list,
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
                if (pinnedItems.isNotEmpty) ...[
                  Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(
                      horizontal: Space.s,
                      vertical: Space.s,
                    ),
                    color: palette.separator,
                  ),
                  for (var j = 0; j < pinnedItems.length; j++)
                    _SidebarRow(
                      height: rowHeight,
                      item: pinnedItems[j],
                      selected: selectedIndex == items.length + j,
                      selectedBackground: true,
                      collapsed: collapsed,
                      onTap: () => onSelected(items.length + j),
                      palette: palette,
                      type: type,
                    ),
                ],
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
    required this.height,
    this.selectedBackground = false,
    required this.item,
    required this.selected,
    required this.collapsed,
    required this.onTap,
    required this.palette,
    required this.type,
  });

  final double height;

  /// Pinned rows have no liquid indicator behind them, so they paint their
  /// own selected background.
  final bool selectedBackground;
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: height,
        decoration: ShapeDecoration(
          color: selected && selectedBackground
              ? palette.accentSoft
              : const Color(0x00000000),
          shape: const RoundedSuperellipseBorder(borderRadius: Radii.small),
        ),
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
