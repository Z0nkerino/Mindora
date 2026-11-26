import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mindora_glass/mindora_glass.dart';

import 'test_utils.dart';

/// A screenful of every component, used to smoke-test all variants.
class _Showcase extends StatefulWidget {
  const _Showcase();
  @override
  State<_Showcase> createState() => _ShowcaseState();
}

class _ShowcaseState extends State<_Showcase> {
  bool sw = false, cb = false;
  String seg = 'a';
  int tab = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const MindoraLogo(size: 40),
        GlassButton.primary(label: 'Plan my day', onPressed: () {}),
        GlassButton(label: 'Reschedule', onPressed: () {}),
        GlassIconButton(icon: Icons.add, label: 'Add', onPressed: () {}),
        const GlassTextField(label: 'Task', placeholder: 'Call mum'),
        const GlassSearchField(placeholder: 'Search', showShortcut: true),
        GlassSegmented<String>(
          selected: seg,
          onChanged: (v) => setState(() => seg = v),
          segments: const [
            GlassSegment(value: 'a', label: 'Day'),
            GlassSegment(value: 'b', label: 'Week'),
          ],
        ),
        GlassSwitch(
          value: sw,
          onChanged: (v) => setState(() => sw = v),
          semanticLabel: 'Focus',
        ),
        GlassCheckbox(
          value: cb,
          onChanged: (v) => setState(() => cb = v),
          semanticLabel: 'Water',
        ),
        GlassChip(label: '#work', selected: true, onPressed: () {}),
        GlassListSection(
          title: 'Routine',
          children: [
            const GlassListRow(title: 'Stretch', subtitle: 'Mon · Wed'),
            GlassListRow(title: 'Reminders', onTap: () {}),
          ],
        ),
        const GlassCard(child: Text('Card')),
        const GlassProgressRing(progress: 0.6, semanticLabel: 'Goal'),
        const GlassSkeleton(width: 100),
        const GlassLineChart(values: [1, 3, 2, 5], semanticSummary: 'Trend up'),
        const GlassBarChart(
          values: [1, 2, 3],
          labels: ['M', 'T', 'W'],
          semanticSummary: 'Bars',
        ),
        const GlassHeatmap(
          values: [0, 0.5, 1, 0.2, 0, 1, 1],
          semanticSummary: 'Week',
        ),
        const GlassSparkline(values: [1, 2, 1, 3], semanticSummary: 'Spark'),
        GlassTabBar(
          selectedIndex: tab,
          onSelected: (i) => setState(() => tab = i),
          items: const [
            GlassNavItem(icon: Icons.today, label: 'Today'),
            GlassNavItem(icon: Icons.check, label: 'Tasks'),
          ],
        ),
        const SizedBox(
          height: 280,
          child: GlassEmptyState(
            title: 'Nothing here',
            message: 'Add something.',
          ),
        ),
      ],
    );
  }
}

/// The showcase includes a looping skeleton shimmer, so it never "settles";
/// advance a fixed time instead.
Future<void> settle(WidgetTester tester) =>
    tester.pump(const Duration(seconds: 2));

void main() {
  for (final (name, brightness, config) in variants) {
    testWidgets('all components render without errors: $name', (tester) async {
      await tester.pumpWidget(
        harness(const _Showcase(), brightness: brightness, config: config),
      );
      await settle(tester);
      expect(tester.takeException(), isNull);
      expect(find.text('Plan my day'), findsOneWidget);
    });
  }

  testWidgets('every tappable component exposes a screen-reader label', (
    tester,
  ) async {
    await tester.pumpWidget(harness(const _Showcase()));
    await settle(tester);
    expectTappablesLabelled(tester);
  });

  testWidgets('switch, checkbox and segmented respond to taps', (tester) async {
    await tester.pumpWidget(harness(const _Showcase()));
    await settle(tester);

    await tester.tap(find.byType(GlassSwitch));
    await settle(tester);
    expect(tester.widget<GlassSwitch>(find.byType(GlassSwitch)).value, isTrue);

    await tester.tap(find.byType(GlassCheckbox));
    await settle(tester);
    expect(
      tester.widget<GlassCheckbox>(find.byType(GlassCheckbox)).value,
      isTrue,
    );

    await tester.tap(find.text('Week'));
    await settle(tester);
    expect(
      tester
          .widget<GlassSegmented<String>>(find.byType(GlassSegmented<String>))
          .selected,
      'b',
    );
  });

  testWidgets('disabled button does not fire', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      harness(GlassButton(label: 'Go', onPressed: null, key: UniqueKey())),
    );
    await tester.tap(find.text('Go'), warnIfMissed: false);
    expect(taps, 0);
    await tester.pumpWidget(
      harness(GlassButton(label: 'Go', onPressed: () => taps++)),
    );
    await tester.tap(find.text('Go'));
    await tester.pumpAndSettle();
    expect(taps, 1);
  });

  testWidgets('buttons are keyboard-activatable (Enter / Space)', (
    tester,
  ) async {
    var taps = 0;
    final focus = FocusNode();
    addTearDown(focus.dispose);
    await tester.pumpWidget(
      harness(
        GlassPressable(
          focusNode: focus,
          semanticLabel: 'Go',
          onPressed: () => taps++,
          child: const SizedBox(width: 80, height: 44),
        ),
      ),
    );
    focus.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(taps, 2);
  });

  testWidgets('pressables keep a 44 pt minimum hit target', (tester) async {
    await tester.pumpWidget(
      harness(
        GlassIconButton(
          icon: Icons.add,
          label: 'Add',
          size: 28,
          onPressed: () {},
        ),
      ),
    );
    final size = tester.getSize(find.byType(GlassPressable));
    expect(size.width, greaterThanOrEqualTo(kMinTarget));
    expect(size.height, greaterThanOrEqualTo(kMinTarget));
  });

  testWidgets('sheet opens and closes with the close button', (tester) async {
    await tester.pumpWidget(
      harness(
        Builder(
          builder: (context) => GlassButton(
            label: 'Open',
            onPressed: () => showGlassSheet<void>(
              context: context,
              builder: (_) => const GlassSheetScaffold(
                title: 'New event',
                child: Text('Body'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('New event'), findsOneWidget);
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.text('New event'), findsNothing);
  });

  testWidgets('dialog returns the chosen action', (tester) async {
    bool? result;
    await tester.pumpWidget(
      harness(
        Builder(
          builder: (context) => GlassButton(
            label: 'Ask',
            onPressed: () async => result = await showGlassDialog(
              context: context,
              title: 'Delete habit?',
              confirmLabel: 'Delete',
              cancelLabel: 'Keep',
              destructive: true,
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Ask'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Keep'));
    await tester.pumpAndSettle();
    expect(result, isFalse);
  });

  testWidgets('toast appears and dismisses itself', (tester) async {
    await tester.pumpWidget(
      harness(
        Builder(
          builder: (context) => GlassButton(
            label: 'Toast',
            onPressed: () => showGlassToast(
              context,
              'Saved',
              duration: const Duration(seconds: 1),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Toast'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Saved'), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.text('Saved'), findsNothing);
  });

  testWidgets('solid tier never builds a BackdropFilter', (tester) async {
    await tester.pumpWidget(
      harness(
        const GlassSurface(
          depth: GlassDepth.floating,
          child: SizedBox(height: 40),
        ),
        config: const GlassConfigData(quality: GlassQuality.solid),
      ),
    );
    expect(find.byType(BackdropFilter), findsNothing);

    await tester.pumpWidget(
      harness(
        const GlassSurface(
          depth: GlassDepth.floating,
          child: SizedBox(height: 40),
        ),
      ),
    );
    expect(find.byType(BackdropFilter), findsOneWidget);
  });

  test('reduce transparency and high contrast force the solid tier', () {
    expect(
      const GlassConfigData(reduceTransparency: true).effectiveQuality,
      GlassQuality.solid,
    );
    expect(
      const GlassConfigData(highContrast: true).effectiveQuality,
      GlassQuality.solid,
    );
    expect(const GlassConfigData(reduceMotion: true).usesShaders, isFalse);
  });

  test('Mindora mark geometry stays inside its canvas', () {
    final b = MindoraMark.bounds;
    expect(b.left, greaterThan(0));
    expect(b.right, lessThan(MindoraMark.canvas));
    expect(b.bottom, lessThan(MindoraMark.canvas));
    expect(MindoraMark.all().getBounds().width, closeTo(b.width, 1));
  });
}
