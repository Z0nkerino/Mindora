import 'dart:ui' show Size;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindora/app/app.dart';
import 'package:mindora/app/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pumps the full app at a given window size with fresh preferences.
Future<SharedPreferences> pumpApp(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  Map<String, Object> prefs = const {},
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final sp = await SharedPreferences.getInstance();
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(sp)],
      child: const MindoraApp(),
    ),
  );
  await settle(tester);
  return sp;
}

/// Entrance animations and springs settle well within this.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
