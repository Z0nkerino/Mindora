import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mindora_glass/mindora_glass.dart';

import '../../app/destinations.dart';
import '../../l10n/generated/app_localizations.dart';

/// Phone-only hub for modules that don't fit in the tab bar.
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final palette = context.palette;
    final items = Destination.moreItems;
    return GlassPage(
      title: l.moreTitle,
      slivers: [
        SliverGrid(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 200,
            mainAxisSpacing: Space.m,
            crossAxisSpacing: Space.m,
            mainAxisExtent: 108,
          ),
          delegate: SliverChildBuilderDelegate((context, i) {
            final d = items[i];
            return GlassEntrance(
              index: i,
              child: GlassCard(
                semanticLabel: d.label(l),
                onTap: () => context.go(d.path),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(d.icon, color: palette.textPrimary, size: 26),
                    const Spacer(),
                    Text(d.label(l), style: context.type.headline),
                  ],
                ),
              ),
            );
          }, childCount: items.length),
        ),
      ],
    );
  }
}
