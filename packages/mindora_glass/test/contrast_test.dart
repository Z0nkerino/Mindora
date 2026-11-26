import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindora_glass/mindora_glass.dart';

/// Every text/background pairing the components use must meet WCAG AA:
/// 4.5:1 for normal text, 3:1 for large text and UI graphics.
void main() {
  const aaText = 4.5;
  const aaLarge = 3.0;

  for (final palette in [MindoraPalette.dark, MindoraPalette.light]) {
    final mode = palette.isDark ? 'dark' : 'light';
    final surfaces = <String, Color>{
      'background': palette.background,
      'inset': palette.insetSolid,
      'raised': palette.raisedSolid,
      'floating': palette.floatingSolid,
    };

    group('$mode palette', () {
      surfaces.forEach((name, surface) {
        test('primary text on $name ≥ 7:1 (AAA)', () {
          expect(
            Contrast.ratio(palette.textPrimary, surface),
            greaterThanOrEqualTo(7),
          );
        });
        test('secondary text on $name ≥ 4.5:1', () {
          expect(
            Contrast.ratio(palette.textSecondary, surface),
            greaterThanOrEqualTo(aaText),
          );
        });
        test('tertiary text on $name ≥ 4.5:1', () {
          expect(
            Contrast.ratio(palette.textTertiary, surface),
            greaterThanOrEqualTo(aaText),
          );
        });
        test('accent-ink text on $name ≥ 4.5:1', () {
          expect(
            Contrast.ratio(palette.accentInk, surface),
            greaterThanOrEqualTo(aaText),
          );
        });
        test('accent fill on $name ≥ 3:1 (UI graphics)', () {
          expect(
            Contrast.ratio(palette.accent, surface),
            greaterThanOrEqualTo(aaLarge),
          );
        });
      });

      test('accent-ink on selected (accent-soft) background ≥ 4.5:1', () {
        final selected = Color.alphaBlend(
          palette.accentSoft,
          palette.background,
        );
        expect(
          Contrast.ratio(palette.accentInk, selected),
          greaterThanOrEqualTo(aaText),
        );
      });

      test('on-accent label (large bold) on accent fill ≥ 3:1', () {
        expect(
          Contrast.ratio(palette.onAccent, palette.accent),
          greaterThanOrEqualTo(aaLarge),
        );
        // And the label style really is WCAG "large text" (≥ 18.66 px bold).
        final style = const MindoraTypography().accentLabel;
        expect(style.fontSize, greaterThanOrEqualTo(18.66));
        expect(style.fontWeight!.value, greaterThanOrEqualTo(700));
      });

      test('high-contrast variant strengthens secondary text', () {
        final hc = palette.highContrast();
        expect(
          Contrast.ratio(hc.textSecondary, hc.background),
          greaterThan(
            Contrast.ratio(palette.textSecondary, palette.background),
          ),
        );
      });
    });
  }

  test('brand accent values match the brief', () {
    expect(MindoraColors.accent, const Color(0xFFFF0051));
    expect(
      Contrast.ratio(MindoraColors.accent, MindoraColors.black),
      closeTo(5.37, 0.01),
    );
    expect(
      Contrast.ratio(MindoraColors.accent, MindoraColors.white),
      closeTo(3.91, 0.01),
    );
  });
}
