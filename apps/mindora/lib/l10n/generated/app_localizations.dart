import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Mindora'**
  String get appName;

  /// No description provided for @navToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get navToday;

  /// No description provided for @navCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get navCalendar;

  /// No description provided for @navTasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get navTasks;

  /// No description provided for @navProjects.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get navProjects;

  /// No description provided for @navNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get navNotes;

  /// No description provided for @navIdeas.
  ///
  /// In en, this message translates to:
  /// **'Ideas'**
  String get navIdeas;

  /// No description provided for @navHabits.
  ///
  /// In en, this message translates to:
  /// **'Habits'**
  String get navHabits;

  /// No description provided for @navGoals.
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get navGoals;

  /// No description provided for @navHealth.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get navHealth;

  /// No description provided for @navFinance.
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get navFinance;

  /// No description provided for @navAssistant.
  ///
  /// In en, this message translates to:
  /// **'Assistant'**
  String get navAssistant;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @navMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get navMore;

  /// No description provided for @greetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get greetingMorning;

  /// No description provided for @greetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get greetingAfternoon;

  /// No description provided for @greetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get greetingEvening;

  /// No description provided for @greetingNight.
  ///
  /// In en, this message translates to:
  /// **'Good night'**
  String get greetingNight;

  /// No description provided for @todayAgenda.
  ///
  /// In en, this message translates to:
  /// **'Agenda'**
  String get todayAgenda;

  /// No description provided for @todayAgendaEmpty.
  ///
  /// In en, this message translates to:
  /// **'No events today. Your calendar is clear.'**
  String get todayAgendaEmpty;

  /// No description provided for @todayTasks.
  ///
  /// In en, this message translates to:
  /// **'Top tasks'**
  String get todayTasks;

  /// No description provided for @todayTasksEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing due today.'**
  String get todayTasksEmpty;

  /// No description provided for @todayHabits.
  ///
  /// In en, this message translates to:
  /// **'Habits'**
  String get todayHabits;

  /// No description provided for @todayHabitsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No habits yet. Small steps add up.'**
  String get todayHabitsEmpty;

  /// No description provided for @todayHealth.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get todayHealth;

  /// No description provided for @todayHealthEmpty.
  ///
  /// In en, this message translates to:
  /// **'Connect a health source or log your first entry.'**
  String get todayHealthEmpty;

  /// No description provided for @todayBudget.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get todayBudget;

  /// No description provided for @todayBudgetEmpty.
  ///
  /// In en, this message translates to:
  /// **'Set a monthly budget to see how you\'re doing.'**
  String get todayBudgetEmpty;

  /// No description provided for @emptyCalendarTitle.
  ///
  /// In en, this message translates to:
  /// **'Your time, at a glance'**
  String get emptyCalendarTitle;

  /// No description provided for @emptyCalendarBody.
  ///
  /// In en, this message translates to:
  /// **'Events and time blocks will appear here in day, week, month and agenda views.'**
  String get emptyCalendarBody;

  /// No description provided for @emptyTasksTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing on your plate'**
  String get emptyTasksTitle;

  /// No description provided for @emptyTasksBody.
  ///
  /// In en, this message translates to:
  /// **'Tasks you add are sorted into Today, Upcoming and Overdue automatically.'**
  String get emptyTasksBody;

  /// No description provided for @emptyProjectsTitle.
  ///
  /// In en, this message translates to:
  /// **'No projects yet'**
  String get emptyProjectsTitle;

  /// No description provided for @emptyProjectsBody.
  ///
  /// In en, this message translates to:
  /// **'Group tasks, notes and files into projects and track progress as a list, board or timeline.'**
  String get emptyProjectsBody;

  /// No description provided for @emptyNotesTitle.
  ///
  /// In en, this message translates to:
  /// **'A quiet place to think'**
  String get emptyNotesTitle;

  /// No description provided for @emptyNotesBody.
  ///
  /// In en, this message translates to:
  /// **'Write notes with checklists and images, and connect them with [[links]].'**
  String get emptyNotesBody;

  /// No description provided for @emptyIdeasTitle.
  ///
  /// In en, this message translates to:
  /// **'Catch ideas before they fly away'**
  String get emptyIdeasTitle;

  /// No description provided for @emptyIdeasBody.
  ///
  /// In en, this message translates to:
  /// **'Capture a thought by text, voice or photo, then turn it into a task, project or note.'**
  String get emptyIdeasBody;

  /// No description provided for @emptyHabitsTitle.
  ///
  /// In en, this message translates to:
  /// **'Build habits gently'**
  String get emptyHabitsTitle;

  /// No description provided for @emptyHabitsBody.
  ///
  /// In en, this message translates to:
  /// **'Track daily or weekly habits. Missing a day never resets your progress to zero.'**
  String get emptyHabitsBody;

  /// No description provided for @emptyGoalsTitle.
  ///
  /// In en, this message translates to:
  /// **'Where are you heading?'**
  String get emptyGoalsTitle;

  /// No description provided for @emptyGoalsBody.
  ///
  /// In en, this message translates to:
  /// **'Break long-term goals into milestones, then link tasks and habits that move them forward.'**
  String get emptyGoalsBody;

  /// No description provided for @emptyHealthTitle.
  ///
  /// In en, this message translates to:
  /// **'Your wellbeing, in one place'**
  String get emptyHealthTitle;

  /// No description provided for @emptyHealthBody.
  ///
  /// In en, this message translates to:
  /// **'Sleep, steps, water, workouts and mood — from Apple Health, Health Connect or manual entry.'**
  String get emptyHealthBody;

  /// No description provided for @emptyFinanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Money, made calm'**
  String get emptyFinanceTitle;

  /// No description provided for @emptyFinanceBody.
  ///
  /// In en, this message translates to:
  /// **'Track spending, budgets and subscriptions in AED, RUB, USD, EUR and more.'**
  String get emptyFinanceBody;

  /// No description provided for @emptyAssistantTitle.
  ///
  /// In en, this message translates to:
  /// **'Your private assistant'**
  String get emptyAssistantTitle;

  /// No description provided for @emptyAssistantBody.
  ///
  /// In en, this message translates to:
  /// **'Runs entirely on this device. It always shows what it will change and waits for your OK.'**
  String get emptyAssistantBody;

  /// No description provided for @moreTitle.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get moreTitle;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @settingsGlass.
  ///
  /// In en, this message translates to:
  /// **'Glass'**
  String get settingsGlass;

  /// No description provided for @glassAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get glassAuto;

  /// No description provided for @glassLiquid.
  ///
  /// In en, this message translates to:
  /// **'Liquid'**
  String get glassLiquid;

  /// No description provided for @glassFrosted.
  ///
  /// In en, this message translates to:
  /// **'Frosted'**
  String get glassFrosted;

  /// No description provided for @glassSolid.
  ///
  /// In en, this message translates to:
  /// **'Solid'**
  String get glassSolid;

  /// No description provided for @settingsGlassFooter.
  ///
  /// In en, this message translates to:
  /// **'Liquid is the richest look. Frosted and Solid use less battery and suit older devices.'**
  String get settingsGlassFooter;

  /// No description provided for @settingsReduceMotion.
  ///
  /// In en, this message translates to:
  /// **'Reduce motion'**
  String get settingsReduceMotion;

  /// No description provided for @settingsReduceTransparency.
  ///
  /// In en, this message translates to:
  /// **'Reduce transparency'**
  String get settingsReduceTransparency;

  /// No description provided for @settingsMotionFooter.
  ///
  /// In en, this message translates to:
  /// **'Mindora also follows your device\'s accessibility settings.'**
  String get settingsMotionFooter;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageSystem;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @settingsVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get settingsVersion;

  /// No description provided for @settingsGallery.
  ///
  /// In en, this message translates to:
  /// **'Component gallery'**
  String get settingsGallery;

  /// No description provided for @settingsGallerySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Every Mindora Glass component'**
  String get settingsGallerySubtitle;

  /// No description provided for @paletteHint.
  ///
  /// In en, this message translates to:
  /// **'Search or jump to…'**
  String get paletteHint;

  /// No description provided for @paletteNoResults.
  ///
  /// In en, this message translates to:
  /// **'No matches'**
  String get paletteNoResults;

  /// No description provided for @paletteGoTo.
  ///
  /// In en, this message translates to:
  /// **'Go to {destination}'**
  String paletteGoTo(String destination);

  /// No description provided for @paletteToggleTheme.
  ///
  /// In en, this message translates to:
  /// **'Switch light / dark'**
  String get paletteToggleTheme;

  /// No description provided for @paletteOpenGallery.
  ///
  /// In en, this message translates to:
  /// **'Open component gallery'**
  String get paletteOpenGallery;

  /// No description provided for @searchLabel.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchLabel;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @galleryTitle.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get galleryTitle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
