import 'package:material_ui/material_ui.dart';
import 'package:mindora_glass/mindora_glass.dart';

import '../l10n/generated/app_localizations.dart';

/// Every top-level place in the app. Order = shell branch order.
enum Destination {
  today('/today', Icons.wb_sunny_outlined, Icons.wb_sunny_rounded),
  calendar(
    '/calendar',
    Icons.calendar_today_outlined,
    Icons.calendar_today_rounded,
  ),
  tasks(
    '/tasks',
    Icons.check_circle_outline_rounded,
    Icons.check_circle_rounded,
  ),
  projects('/projects', Icons.folder_outlined, Icons.folder_rounded),
  notes('/notes', Icons.sticky_note_2_outlined, Icons.sticky_note_2_rounded),
  ideas('/ideas', Icons.lightbulb_outline_rounded, Icons.lightbulb_rounded),
  habits('/habits', Icons.repeat_rounded, Icons.repeat_on_rounded),
  goals('/goals', Icons.flag_outlined, Icons.flag_rounded),
  health('/health', Icons.favorite_outline_rounded, Icons.favorite_rounded),
  finance(
    '/finance',
    Icons.account_balance_wallet_outlined,
    Icons.account_balance_wallet_rounded,
  ),
  assistant(
    '/assistant',
    Icons.auto_awesome_outlined,
    Icons.auto_awesome_rounded,
  ),
  settings('/settings', Icons.settings_outlined, Icons.settings_rounded),
  more('/more', Icons.grid_view_outlined, Icons.grid_view_rounded);

  const Destination(this.path, this.icon, this.selectedIcon);

  final String path;
  final IconData icon;
  final IconData selectedIcon;

  String label(AppLocalizations l) => switch (this) {
    today => l.navToday,
    calendar => l.navCalendar,
    tasks => l.navTasks,
    projects => l.navProjects,
    notes => l.navNotes,
    ideas => l.navIdeas,
    habits => l.navHabits,
    goals => l.navGoals,
    health => l.navHealth,
    finance => l.navFinance,
    assistant => l.navAssistant,
    settings => l.navSettings,
    more => l.navMore,
  };

  /// Phone tab bar: four primary places + More.
  static const phoneTabs = [today, calendar, tasks, notes, more];

  /// Sidebar order; `true` marks a group break before the item.
  static const sidebar = <(Destination, bool)>[
    (today, false),
    (calendar, false),
    (tasks, false),
    (projects, false),
    (notes, true),
    (ideas, false),
    (habits, true),
    (goals, false),
    (health, true),
    (finance, false),
    (assistant, true),
  ];

  /// Pinned to the bottom of the sidebar so it is always reachable.
  static const sidebarPinned = [settings];

  /// Destinations reachable from the phone "More" screen.
  static const moreItems = [
    projects,
    ideas,
    habits,
    goals,
    health,
    finance,
    assistant,
    settings,
  ];

  /// ⌘/Ctrl + number shortcuts (first nine sidebar items).
  static List<Destination> get numbered =>
      sidebar.map((e) => e.$1).take(9).toList();

  GlassNavItem navItem(
    AppLocalizations l, {
    bool dividerBefore = false,
    String? shortcut,
  }) => GlassNavItem(
    icon: icon,
    selectedIcon: selectedIcon,
    label: label(l),
    dividerBefore: dividerBefore,
    shortcutHint: shortcut,
  );
}
