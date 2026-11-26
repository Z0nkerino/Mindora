import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mindora_glass/mindora_glass.dart';

import '../../l10n/generated/app_localizations.dart';
import '../destinations.dart';
import '../settings.dart';
import 'command_palette.dart';

/// The app frame. Phone: floating glass tab bar. Tablet: collapsed glass
/// sidebar (icon rail). Desktop/web: full sidebar. Global keyboard shortcuts
/// live here.
class AdaptiveShell extends ConsumerWidget {
  const AdaptiveShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  static const double _tabBarSpace = GlassTabBar.height + Space.l;

  Destination get _current => Destination.values[shell.currentIndex];

  void _go(Destination d) =>
      shell.goBranch(d.index, initialLocation: d.index == shell.currentIndex);

  bool get _isApple =>
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.iOS;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final palette = context.palette;

    void openPalette() => showCommandPalette(
      context: context,
      onNavigate: _go,
      onToggleTheme: () => ref
          .read(settingsProvider.notifier)
          .toggleBrightness(Theme.of(context).brightness),
      onOpenGallery: () => context.push('/gallery'),
    );

    Widget body;
    if (width < Breakpoints.tablet) {
      // Phone layout.
      final tabs = Destination.phoneTabs;
      final current = _current;
      final tabIndex = tabs.contains(current)
          ? tabs.indexOf(current)
          : (Destination.moreItems.contains(current)
                ? tabs.indexOf(Destination.more)
                : -1);
      final media = MediaQuery.of(context);
      body = Stack(
        children: [
          MediaQuery(
            data: media.copyWith(
              padding: media.padding.copyWith(
                bottom: media.padding.bottom + _tabBarSpace,
              ),
            ),
            child: shell,
          ),
          Positioned(
            left: Space.l,
            right: Space.l,
            bottom: media.padding.bottom + Space.s,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: GlassTabBar(
                  items: [for (final d in tabs) d.navItem(l)],
                  selectedIndex: tabIndex,
                  onSelected: (i) => _go(tabs[i]),
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      final collapsed = width < Breakpoints.desktop;
      final mod = _isApple ? '⌘' : 'Ctrl ';
      final items = <GlassNavItem>[];
      final dests = <Destination>[];
      for (var i = 0; i < Destination.sidebar.length; i++) {
        final (d, divider) = Destination.sidebar[i];
        dests.add(d);
        items.add(
          d.navItem(
            l,
            dividerBefore: divider,
            shortcut: i < 9 ? '$mod${i + 1}' : null,
          ),
        );
      }
      final selected = dests.indexOf(_current);

      body = Row(
        children: [
          SafeArea(
            right: false,
            child: GlassSidebar(
              collapsed: collapsed,
              items: items,
              selectedIndex: selected,
              onSelected: (i) => _go(dests[i]),
              header: _SidebarHeader(collapsed: collapsed),
              footer: _PaletteLauncher(
                collapsed: collapsed,
                onTap: openPalette,
              ),
            ),
          ),
          Expanded(
            child: MediaQuery.removePadding(
              context: context,
              removeLeft: true,
              child: shell,
            ),
          ),
        ],
      );
    }

    final shortcuts = <ShortcutActivator, VoidCallback>{
      SingleActivator(
        LogicalKeyboardKey.keyK,
        meta: _isApple,
        control: !_isApple,
      ): openPalette,
      SingleActivator(
        LogicalKeyboardKey.comma,
        meta: _isApple,
        control: !_isApple,
      ): () =>
          _go(Destination.settings),
    };
    const digits = [
      LogicalKeyboardKey.digit1,
      LogicalKeyboardKey.digit2,
      LogicalKeyboardKey.digit3,
      LogicalKeyboardKey.digit4,
      LogicalKeyboardKey.digit5,
      LogicalKeyboardKey.digit6,
      LogicalKeyboardKey.digit7,
      LogicalKeyboardKey.digit8,
      LogicalKeyboardKey.digit9,
    ];
    final numbered = Destination.numbered;
    for (var i = 0; i < numbered.length; i++) {
      final d = numbered[i];
      shortcuts[SingleActivator(
        digits[i],
        meta: _isApple,
        control: !_isApple,
      )] = () =>
          _go(d);
    }

    return CallbackShortcuts(
      bindings: shortcuts,
      child: Focus(
        autofocus: true,
        child: ColoredBox(color: palette.background, child: body),
      ),
    );
  }
}

class _SidebarHeader extends StatelessWidget {
  const _SidebarHeader({required this.collapsed});
  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    const logo = MindoraLogo(size: 26);
    if (collapsed) return const Center(child: logo);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.m),
      child: Row(
        children: [
          logo,
          const SizedBox(width: Space.m),
          Text(
            AppLocalizations.of(context).appName,
            style: context.type.title2.copyWith(fontSize: 20),
          ),
        ],
      ),
    );
  }
}

class _PaletteLauncher extends StatelessWidget {
  const _PaletteLauncher({required this.collapsed, required this.onTap});
  final bool collapsed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final palette = context.palette;
    if (collapsed) {
      return Center(
        child: GlassIconButton(
          icon: Icons.search_rounded,
          label: l.searchLabel,
          onPressed: onTap,
          glass: false,
        ),
      );
    }
    return GlassPressable(
      onPressed: onTap,
      borderRadius: Radii.small,
      semanticLabel: l.searchLabel,
      minSize: 0,
      child: GlassSurface(
        depth: GlassDepth.inset,
        borderRadius: Radii.small,
        padding: const EdgeInsets.symmetric(horizontal: Space.m, vertical: 10),
        child: Row(
          children: [
            Icon(Icons.search_rounded, size: 18, color: palette.textTertiary),
            const SizedBox(width: Space.s),
            Expanded(
              child: Text(
                l.searchLabel,
                style: context.type.callout.copyWith(
                  color: palette.textTertiary,
                ),
              ),
            ),
            Text(
              GlassSearchField.shortcutLabel(),
              style: context.type.caption.copyWith(color: palette.textTertiary),
            ),
          ],
        ),
      ),
    );
  }
}
