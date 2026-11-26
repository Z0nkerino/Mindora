@Tags(['golden'])
library;

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mindora/gallery/gallery_screen.dart';
import 'package:mindora_glass/mindora_glass.dart';

/// Golden snapshots of the component gallery in both modes, both text
/// scales and the solid tier, rendered with the real Inter font.
///
/// Font rasterisation differs slightly between operating systems, so these
/// run on Linux only (CI's ubuntu job). Update with:
///   flutter test --tags golden --update-goldens
Future<void> _loadFonts() async {
  Future<void> load(String family, List<String> files) async {
    final loader = FontLoader(family);
    for (final f in files) {
      loader.addFont(
        Future.value(ByteData.sublistView(File(f).readAsBytesSync())),
      );
    }
    await loader.load();
  }

  await load('Inter', [
    'assets/fonts/Inter-Regular.ttf',
    'assets/fonts/Inter-Medium.ttf',
    'assets/fonts/Inter-SemiBold.ttf',
    'assets/fonts/Inter-Bold.ttf',
  ]);
  final flutterRoot = Platform.environment['FLUTTER_ROOT'] ?? '/opt/flutter';
  await load('MaterialIcons', [
    '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  ]);
}

void main() {
  setUpAll(_loadFonts);

  final cases = <(String, Brightness, double, GlassConfigData)>[
    ('dark', Brightness.dark, 1.0, const GlassConfigData()),
    ('light', Brightness.light, 1.0, const GlassConfigData()),
    ('dark_text200', Brightness.dark, 2.0, const GlassConfigData()),
    (
      'light_solid',
      Brightness.light,
      1.0,
      const GlassConfigData(quality: GlassQuality.solid),
    ),
  ];

  for (final (name, brightness, scale, config) in cases) {
    testWidgets('gallery $name', (tester) async {
      tester.view.physicalSize = const Size(430, 3400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildMindoraTheme(brightness: brightness, fontFamily: 'Inter'),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(scale),
              disableAnimations: true,
            ),
            child: GlassConfig(
              data: config.copyWith(reduceMotion: true),
              child: child!,
            ),
          ),
          home: const Scaffold(
            body: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: GalleryContent(),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(
        tester.takeException(),
        isNull,
        reason: 'no overflow at ${scale}x text',
      );
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('gallery_$name.png'),
      );
    }, skip: !Platform.isLinux);
  }
}
