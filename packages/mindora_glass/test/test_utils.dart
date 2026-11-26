import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mindora_glass/mindora_glass.dart';

/// Wraps [child] in a themed app with the given glass config.
Widget harness(
  Widget child, {
  Brightness brightness = Brightness.dark,
  GlassConfigData config = const GlassConfigData(),
  Size size = const Size(420, 900),
}) {
  return MediaQuery(
    data: MediaQueryData(size: size),
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildMindoraTheme(brightness: brightness),
      builder: (context, c) => GlassConfig(data: config, child: c!),
      home: Scaffold(
        body: SingleChildScrollView(
          child: Padding(padding: const EdgeInsets.all(16), child: child),
        ),
      ),
    ),
  );
}

/// Every combination the design system must render correctly in.
const variants = <(String, Brightness, GlassConfigData)>[
  ('dark/liquid', Brightness.dark, GlassConfigData()),
  ('light/liquid', Brightness.light, GlassConfigData()),
  (
    'dark/frosted',
    Brightness.dark,
    GlassConfigData(quality: GlassQuality.frosted),
  ),
  (
    'light/solid',
    Brightness.light,
    GlassConfigData(quality: GlassQuality.solid),
  ),
  (
    'dark/reduced',
    Brightness.dark,
    GlassConfigData(reduceMotion: true, reduceTransparency: true),
  ),
  (
    'light/high-contrast',
    Brightness.light,
    GlassConfigData(highContrast: true),
  ),
];

/// Asserts every tappable node has a label (screen-reader check).
void expectTappablesLabelled(WidgetTester tester) {
  final handle = tester.ensureSemantics();
  // The test binding's view pipeline owner holds the semantics tree.
  // ignore: deprecated_member_use
  final root = tester.binding.pipelineOwner.semanticsOwner!.rootSemanticsNode!;
  final unlabeled = <SemanticsNode>[];
  void visit(SemanticsNode n) {
    // Nodes merged into a parent aren't read separately; the parent's data
    // already includes their label.
    final d = n.getSemanticsData();
    if (!n.isMergedIntoParent &&
        d.hasAction(SemanticsAction.tap) &&
        d.label.isEmpty &&
        d.value.isEmpty &&
        d.tooltip.isEmpty) {
      unlabeled.add(n);
    }
    n.visitChildren((c) {
      visit(c);
      return true;
    });
  }

  visit(root);
  handle.dispose();
  expect(
    unlabeled,
    isEmpty,
    reason: 'Tappable nodes without a label: $unlabeled',
  );
}
