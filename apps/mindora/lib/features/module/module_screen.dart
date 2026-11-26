import 'package:material_ui/material_ui.dart';
import 'package:mindora_glass/mindora_glass.dart';

import '../../app/destinations.dart';
import '../../l10n/generated/app_localizations.dart';

/// A module's home before it has content: title plus a designed empty state
/// describing what will live here. Each module replaces this with its real
/// screen in its phase.
class ModuleScreen extends StatelessWidget {
  const ModuleScreen({super.key, required this.destination});

  final Destination destination;

  (String, String) _copy(AppLocalizations l) => switch (destination) {
    Destination.calendar => (l.emptyCalendarTitle, l.emptyCalendarBody),
    Destination.tasks => (l.emptyTasksTitle, l.emptyTasksBody),
    Destination.projects => (l.emptyProjectsTitle, l.emptyProjectsBody),
    Destination.notes => (l.emptyNotesTitle, l.emptyNotesBody),
    Destination.ideas => (l.emptyIdeasTitle, l.emptyIdeasBody),
    Destination.habits => (l.emptyHabitsTitle, l.emptyHabitsBody),
    Destination.goals => (l.emptyGoalsTitle, l.emptyGoalsBody),
    Destination.health => (l.emptyHealthTitle, l.emptyHealthBody),
    Destination.finance => (l.emptyFinanceTitle, l.emptyFinanceBody),
    Destination.assistant => (l.emptyAssistantTitle, l.emptyAssistantBody),
    _ => (destination.label(l), ''),
  };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final (title, body) = _copy(l);
    return GlassPage(
      title: destination.label(l),
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: GlassEntrance(
            child: GlassEmptyState(
              icon: destination.selectedIcon,
              title: title,
              message: body,
              litBar: destination.index % 3,
            ),
          ),
        ),
      ],
    );
  }
}
