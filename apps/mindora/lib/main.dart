import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mindora_glass/mindora_glass.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'app/settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Warm the liquid shader so the first selection animation is smooth.
  final shader = LiquidShader.load();
  final prefs = await SharedPreferences.getInstance();
  await shader;
  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const MindoraApp(),
    ),
  );
}
