import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mindora_glass/mindora_glass.dart';

import '../features/module/module_screen.dart';
import '../features/more/more_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/today/today_screen.dart';
import '../gallery/gallery_screen.dart';
import 'destinations.dart';
import 'shell/adaptive_shell.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: Destination.today.path,
    routes: [
      StatefulShellRoute(
        builder: (context, state, shell) => AdaptiveShell(shell: shell),
        navigatorContainerBuilder: (context, shell, children) =>
            _BranchContainer(
              currentIndex: shell.currentIndex,
              children: children,
            ),
        branches: [
          for (final d in Destination.values)
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: d.path,
                  pageBuilder: (context, state) => NoTransitionPage(
                    key: state.pageKey,
                    child: _screenFor(d),
                  ),
                ),
              ],
            ),
        ],
      ),
      GoRoute(
        path: '/gallery',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const GalleryScreen(),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

Widget _screenFor(Destination d) => switch (d) {
  Destination.today => const TodayScreen(),
  Destination.more => const MoreScreen(),
  Destination.settings => const SettingsScreen(),
  _ => ModuleScreen(destination: d),
};

/// Holds every branch navigator (keeping their state) and cross-fades with a
/// slight lift when switching, instead of cutting instantly.
class _BranchContainer extends StatefulWidget {
  const _BranchContainer({required this.currentIndex, required this.children});

  final int currentIndex;
  final List<Widget> children;

  @override
  State<_BranchContainer> createState() => _BranchContainerState();
}

class _BranchContainerState extends State<_BranchContainer> {
  @override
  Widget build(BuildContext context) {
    final reduce = reduceMotionOf(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        for (var i = 0; i < widget.children.length; i++)
          _Branch(
            key: ValueKey(i),
            active: i == widget.currentIndex,
            reduceMotion: reduce,
            child: widget.children[i],
          ),
      ],
    );
  }
}

class _Branch extends StatelessWidget {
  const _Branch({
    super.key,
    required this.active,
    required this.reduceMotion,
    required this.child,
  });

  final bool active;
  final bool reduceMotion;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !active,
      child: ExcludeSemantics(
        excluding: !active,
        child: FocusScope(
          canRequestFocus: active,
          child: TickerMode(
            enabled: active,
            child: AnimatedOpacity(
              opacity: active ? 1 : 0,
              duration: active
                  ? const Duration(milliseconds: 240)
                  : const Duration(milliseconds: 120),
              curve: Curves.easeOut,
              child: AnimatedSlide(
                offset: active || reduceMotion
                    ? Offset.zero
                    : const Offset(0, 0.012),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
