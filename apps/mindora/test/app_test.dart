import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mindora/app/destinations.dart';
import 'package:mindora/features/today/today_screen.dart';
import 'package:mindora/l10n/generated/app_localizations_en.dart';
import 'package:mindora/l10n/generated/app_localizations_ru.dart';
import 'package:mindora_glass/mindora_glass.dart';

import 'helpers.dart';

void main() {
  group('phone layout', () {
    testWidgets('boots into Today with a floating tab bar', (tester) async {
      await pumpApp(tester);
      expect(find.byType(GlassTabBar), findsOneWidget);
      expect(find.byType(GlassSidebar), findsNothing);
      expect(find.byType(TodayScreen), findsOneWidget);
      expect(find.text('Agenda'), findsOneWidget);
    });

    testWidgets('tab bar navigates between modules', (tester) async {
      await pumpApp(tester);
      await tester.tap(
        find.descendant(
          of: find.byType(GlassTabBar),
          matching: find.text('Tasks'),
        ),
      );
      await settle(tester);
      expect(find.text('Nothing on your plate'), findsOneWidget);

      await tester.tap(
        find.descendant(
          of: find.byType(GlassTabBar),
          matching: find.text('Notes'),
        ),
      );
      await settle(tester);
      expect(find.text('A quiet place to think'), findsOneWidget);
    });

    testWidgets('More lists the remaining modules and opens them', (
      tester,
    ) async {
      await pumpApp(tester);
      await tester.tap(
        find.descendant(
          of: find.byType(GlassTabBar),
          matching: find.text('More'),
        ),
      );
      await settle(tester);
      for (final label in [
        'Projects',
        'Ideas',
        'Habits',
        'Goals',
        'Health',
        'Finance',
      ]) {
        expect(find.text(label), findsWidgets);
      }
      await tester.tap(find.text('Finance'));
      await settle(tester);
      expect(find.text('Money, made calm'), findsOneWidget);
      // "More" stays highlighted while inside a More module.
      final bar = tester.widget<GlassTabBar>(find.byType(GlassTabBar));
      expect(
        bar.selectedIndex,
        Destination.phoneTabs.indexOf(Destination.more),
      );
    });
  });

  group('desktop layout', () {
    testWidgets('shows a full sidebar with every module', (tester) async {
      await pumpApp(tester, size: const Size(1280, 800));
      expect(find.byType(GlassSidebar), findsOneWidget);
      expect(find.byType(GlassTabBar), findsNothing);
      final sidebar = tester.widget<GlassSidebar>(find.byType(GlassSidebar));
      expect(sidebar.collapsed, isFalse);
      expect(sidebar.items.length, Destination.sidebar.length);
    });

    testWidgets('tablet width collapses the sidebar to a rail', (tester) async {
      await pumpApp(tester, size: const Size(900, 700));
      expect(
        tester.widget<GlassSidebar>(find.byType(GlassSidebar)).collapsed,
        isTrue,
      );
    });

    testWidgets('Ctrl+3 jumps to Tasks, Ctrl+, opens Settings', (tester) async {
      await pumpApp(tester, size: const Size(1280, 800));
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.digit3);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await settle(tester);
      expect(find.text('Nothing on your plate'), findsOneWidget);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.comma);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await settle(tester);
      expect(find.text('Appearance'), findsOneWidget);
    });

    testWidgets('Ctrl+K palette: type, Enter navigates', (tester) async {
      await pumpApp(tester, size: const Size(1280, 800));
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await settle(tester);
      expect(find.text('Search or jump to…'), findsOneWidget);

      await tester.enterText(find.byType(EditableText), 'financ');
      await settle(tester);
      expect(find.text('Go to Finance'), findsOneWidget);
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await settle(tester);
      expect(find.text('Money, made calm'), findsOneWidget);
    });
  });

  group('settings', () {
    testWidgets('switching language to Russian relabels the app and persists', (
      tester,
    ) async {
      final prefs = await pumpApp(tester, size: const Size(1280, 900));
      await tester.tap(find.text('Settings').first);
      await settle(tester);
      await tester.tap(find.text('Русский'));
      await settle(tester);
      expect(find.text('Настройки'), findsWidgets);
      expect(find.text('Оформление'), findsOneWidget);
      expect(prefs.getString('settings.language'), 'ru');
    });

    testWidgets('theme and glass choices persist', (tester) async {
      final prefs = await pumpApp(tester, size: const Size(1280, 900));
      await tester.tap(find.text('Settings').first);
      await settle(tester);
      await tester.tap(find.text('Dark'));
      await tester.tap(find.text('Solid'));
      await settle(tester);
      expect(prefs.getString('settings.themeMode'), 'dark');
      expect(prefs.getString('settings.glass'), 'solid');
      // Solid tier: no blur anywhere on screen.
      expect(find.byType(BackdropFilter), findsNothing);
    });

    testWidgets('saved preferences are restored at launch', (tester) async {
      await pumpApp(
        tester,
        prefs: {'settings.language': 'ru', 'settings.themeMode': 'light'},
      );
      expect(find.text('Сегодня'), findsWidgets);
    });
  });

  group('Today', () {
    test('greeting follows the time of day', () {
      final en = AppLocalizationsEn();
      expect(TodayScreen.greeting(en, DateTime(2026, 1, 1, 7)), 'Good morning');
      expect(
        TodayScreen.greeting(en, DateTime(2026, 1, 1, 13)),
        'Good afternoon',
      );
      expect(
        TodayScreen.greeting(en, DateTime(2026, 1, 1, 20)),
        'Good evening',
      );
      expect(TodayScreen.greeting(en, DateTime(2026, 1, 1, 2)), 'Good night');
      final ru = AppLocalizationsRu();
      expect(TodayScreen.greeting(ru, DateTime(2026, 1, 1, 7)), 'Доброе утро');
    });
  });
}
