import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mindora_glass/mindora_glass.dart';

import '../../l10n/generated/app_localizations.dart';
import '../destinations.dart';

/// One runnable command in the palette.
class PaletteCommand {
  const PaletteCommand({
    required this.title,
    required this.icon,
    required this.run,
    this.keywords = const [],
  });

  final String title;
  final IconData icon;
  final VoidCallback run;

  /// Extra terms that match (e.g. the English name when the UI is Russian).
  final List<String> keywords;
}

/// Subsequence fuzzy score. Higher is better; null = no match.
/// Rewards matches at word starts and consecutive runs.
int? fuzzyScore(String query, String text) {
  final q = query.toLowerCase().trim();
  if (q.isEmpty) return 0;
  final t = text.toLowerCase();
  if (t.startsWith(q)) return 1000 - t.length;
  if (t.contains(q)) return 700 - t.indexOf(q);
  var score = 0, ti = 0, run = 0;
  for (final ch in q.runes) {
    var found = false;
    while (ti < t.length) {
      final c = t.codeUnitAt(ti);
      final atWordStart = ti == 0 || t[ti - 1] == ' ';
      ti++;
      if (c == ch) {
        run++;
        score += 10 + run * 5 + (atWordStart ? 15 : 0);
        found = true;
        break;
      }
      run = 0;
    }
    if (!found) return null;
  }
  return score;
}

/// The ⌘K / Ctrl K command palette. Phase 1 covers navigation and app
/// commands; full-text search across modules joins in Phase 4.
Future<void> showCommandPalette({
  required BuildContext context,
  required ValueChanged<Destination> onNavigate,
  required VoidCallback onToggleTheme,
  required VoidCallback onOpenGallery,
}) {
  final l = AppLocalizations.of(context);
  final commands = <PaletteCommand>[
    for (final d in Destination.values.where((d) => d != Destination.more))
      PaletteCommand(
        title: l.paletteGoTo(d.label(l)),
        icon: d.icon,
        keywords: [d.name, d.label(l)],
        run: () => onNavigate(d),
      ),
    PaletteCommand(
      title: l.paletteToggleTheme,
      icon: Icons.contrast_rounded,
      keywords: const ['theme', 'dark', 'light', 'тема'],
      run: onToggleTheme,
    ),
    PaletteCommand(
      title: l.paletteOpenGallery,
      icon: Icons.widgets_outlined,
      keywords: const ['gallery', 'components', 'design', 'галерея'],
      run: onOpenGallery,
    ),
  ];

  final reduce = reduceMotionOf(context);
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: context.palette.scrim,
    transitionDuration: reduce
        ? MindoraDurations.fade
        : const Duration(milliseconds: 320),
    pageBuilder: (context, _, _) => _CommandPalette(commands: commands),
    transitionBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeIn,
      );
      return FadeTransition(
        opacity: animation,
        child: reduce
            ? child
            : ScaleTransition(
                scale: Tween(begin: 0.96, end: 1.0).animate(curved),
                alignment: Alignment.topCenter,
                child: child,
              ),
      );
    },
  );
}

class _CommandPalette extends StatefulWidget {
  const _CommandPalette({required this.commands});
  final List<PaletteCommand> commands;

  @override
  State<_CommandPalette> createState() => _CommandPaletteState();
}

class _CommandPaletteState extends State<_CommandPalette> {
  final _query = TextEditingController();
  int _highlight = 0;

  List<PaletteCommand> get _results {
    final q = _query.text;
    if (q.trim().isEmpty) return widget.commands;
    final scored = <(PaletteCommand, int)>[];
    for (final c in widget.commands) {
      int? best;
      for (final s in [c.title, ...c.keywords]) {
        final sc = fuzzyScore(q, s);
        if (sc != null && (best == null || sc > best)) best = sc;
      }
      if (best != null) scored.add((c, best));
    }
    scored.sort((a, b) => b.$2.compareTo(a.$2));
    return [for (final s in scored) s.$1];
  }

  void _run(PaletteCommand c) {
    Navigator.of(context).pop();
    c.run();
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final palette = context.palette;
    final results = _results;
    if (_highlight >= results.length) _highlight = 0;

    return SafeArea(
      child: Align(
        alignment: const Alignment(0, -0.6),
        child: Padding(
          padding: const EdgeInsets.all(Space.l),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600, maxHeight: 480),
            child: Material(
              type: MaterialType.transparency,
              child: CallbackShortcuts(
                bindings: {
                  const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
                      setState(
                        () => _highlight =
                            (_highlight + 1) %
                            (results.isEmpty ? 1 : results.length),
                      ),
                  const SingleActivator(LogicalKeyboardKey.arrowUp): () =>
                      setState(
                        () => _highlight = (_highlight - 1) < 0
                            ? (results.isEmpty ? 0 : results.length - 1)
                            : _highlight - 1,
                      ),
                  const SingleActivator(LogicalKeyboardKey.escape): () =>
                      Navigator.of(context).pop(),
                },
                child: GlassSurface(
                  depth: GlassDepth.floating,
                  borderRadius: Radii.large,
                  padding: const EdgeInsets.all(Space.m),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      GlassSearchField(
                        controller: _query,
                        placeholder: l.paletteHint,
                        autofocus: true,
                        onChanged: (_) => setState(() => _highlight = 0),
                        onSubmitted: (_) {
                          if (results.isNotEmpty) _run(results[_highlight]);
                        },
                      ),
                      const SizedBox(height: Space.s),
                      Flexible(
                        child: results.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.all(Space.xxl),
                                child: Text(
                                  l.paletteNoResults,
                                  textAlign: TextAlign.center,
                                  style: context.type.callout.copyWith(
                                    color: palette.textTertiary,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                itemCount: results.length,
                                itemBuilder: (context, i) {
                                  final c = results[i];
                                  final hi = i == _highlight;
                                  return GlassPressable(
                                    onPressed: () => _run(c),
                                    borderRadius: Radii.small,
                                    semanticLabel: c.title,
                                    minSize: 0,
                                    child: AnimatedContainer(
                                      duration: MindoraDurations.instant,
                                      height: 46,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: Space.m,
                                      ),
                                      decoration: ShapeDecoration(
                                        color: hi
                                            ? palette.accentSoft
                                            : Colors.transparent,
                                        shape: const RoundedSuperellipseBorder(
                                          borderRadius: Radii.small,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            c.icon,
                                            size: 20,
                                            color: hi
                                                ? palette.accentInk
                                                : palette.textSecondary,
                                          ),
                                          const SizedBox(width: Space.m),
                                          Expanded(
                                            child: Text(
                                              c.title,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: context.type.callout
                                                  .copyWith(
                                                    color: palette.textPrimary,
                                                  ),
                                            ),
                                          ),
                                          if (hi)
                                            Icon(
                                              Icons.keyboard_return_rounded,
                                              size: 16,
                                              color: palette.textTertiary,
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
