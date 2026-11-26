// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Mindora';

  @override
  String get navToday => 'Today';

  @override
  String get navCalendar => 'Calendar';

  @override
  String get navTasks => 'Tasks';

  @override
  String get navProjects => 'Projects';

  @override
  String get navNotes => 'Notes';

  @override
  String get navIdeas => 'Ideas';

  @override
  String get navHabits => 'Habits';

  @override
  String get navGoals => 'Goals';

  @override
  String get navHealth => 'Health';

  @override
  String get navFinance => 'Finance';

  @override
  String get navAssistant => 'Assistant';

  @override
  String get navSettings => 'Settings';

  @override
  String get navMore => 'More';

  @override
  String get greetingMorning => 'Good morning';

  @override
  String get greetingAfternoon => 'Good afternoon';

  @override
  String get greetingEvening => 'Good evening';

  @override
  String get greetingNight => 'Good night';

  @override
  String get todayAgenda => 'Agenda';

  @override
  String get todayAgendaEmpty => 'No events today. Your calendar is clear.';

  @override
  String get todayTasks => 'Top tasks';

  @override
  String get todayTasksEmpty => 'Nothing due today.';

  @override
  String get todayHabits => 'Habits';

  @override
  String get todayHabitsEmpty => 'No habits yet. Small steps add up.';

  @override
  String get todayHealth => 'Health';

  @override
  String get todayHealthEmpty =>
      'Connect a health source or log your first entry.';

  @override
  String get todayBudget => 'Budget';

  @override
  String get todayBudgetEmpty =>
      'Set a monthly budget to see how you\'re doing.';

  @override
  String get emptyCalendarTitle => 'Your time, at a glance';

  @override
  String get emptyCalendarBody =>
      'Events and time blocks will appear here in day, week, month and agenda views.';

  @override
  String get emptyTasksTitle => 'Nothing on your plate';

  @override
  String get emptyTasksBody =>
      'Tasks you add are sorted into Today, Upcoming and Overdue automatically.';

  @override
  String get emptyProjectsTitle => 'No projects yet';

  @override
  String get emptyProjectsBody =>
      'Group tasks, notes and files into projects and track progress as a list, board or timeline.';

  @override
  String get emptyNotesTitle => 'A quiet place to think';

  @override
  String get emptyNotesBody =>
      'Write notes with checklists and images, and connect them with [[links]].';

  @override
  String get emptyIdeasTitle => 'Catch ideas before they fly away';

  @override
  String get emptyIdeasBody =>
      'Capture a thought by text, voice or photo, then turn it into a task, project or note.';

  @override
  String get emptyHabitsTitle => 'Build habits gently';

  @override
  String get emptyHabitsBody =>
      'Track daily or weekly habits. Missing a day never resets your progress to zero.';

  @override
  String get emptyGoalsTitle => 'Where are you heading?';

  @override
  String get emptyGoalsBody =>
      'Break long-term goals into milestones, then link tasks and habits that move them forward.';

  @override
  String get emptyHealthTitle => 'Your wellbeing, in one place';

  @override
  String get emptyHealthBody =>
      'Sleep, steps, water, workouts and mood — from Apple Health, Health Connect or manual entry.';

  @override
  String get emptyFinanceTitle => 'Money, made calm';

  @override
  String get emptyFinanceBody =>
      'Track spending, budgets and subscriptions in AED, RUB, USD, EUR and more.';

  @override
  String get emptyAssistantTitle => 'Your private assistant';

  @override
  String get emptyAssistantBody =>
      'Runs entirely on this device. It always shows what it will change and waits for your OK.';

  @override
  String get moreTitle => 'More';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get settingsGlass => 'Glass';

  @override
  String get glassAuto => 'Auto';

  @override
  String get glassLiquid => 'Liquid';

  @override
  String get glassFrosted => 'Frosted';

  @override
  String get glassSolid => 'Solid';

  @override
  String get settingsGlassFooter =>
      'Liquid is the richest look. Frosted and Solid use less battery and suit older devices.';

  @override
  String get settingsReduceMotion => 'Reduce motion';

  @override
  String get settingsReduceTransparency => 'Reduce transparency';

  @override
  String get settingsMotionFooter =>
      'Mindora also follows your device\'s accessibility settings.';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get languageSystem => 'System';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsGallery => 'Component gallery';

  @override
  String get settingsGallerySubtitle => 'Every Mindora Glass component';

  @override
  String get paletteHint => 'Search or jump to…';

  @override
  String get paletteNoResults => 'No matches';

  @override
  String paletteGoTo(String destination) {
    return 'Go to $destination';
  }

  @override
  String get paletteToggleTheme => 'Switch light / dark';

  @override
  String get paletteOpenGallery => 'Open component gallery';

  @override
  String get searchLabel => 'Search';

  @override
  String get close => 'Close';

  @override
  String get galleryTitle => 'Gallery';
}
