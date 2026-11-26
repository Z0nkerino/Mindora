import 'package:flutter_test/flutter_test.dart';
import 'package:mindora/app/shell/command_palette.dart';

void main() {
  group('fuzzyScore', () {
    test('empty query matches everything', () {
      expect(fuzzyScore('', 'Go to Tasks'), 0);
    });

    test('prefix beats substring beats subsequence', () {
      final prefix = fuzzyScore('go', 'Go to Tasks')!;
      final sub = fuzzyScore('tas', 'Go to Tasks')!;
      final seq = fuzzyScore('gtt', 'Go to Tasks')!;
      expect(prefix, greaterThan(sub));
      expect(sub, greaterThan(seq));
    });

    test('is case-insensitive and works for Cyrillic', () {
      expect(fuzzyScore('ЗАД', 'Задачи'), isNotNull);
      expect(fuzzyScore('фин', 'Перейти: Финансы'), isNotNull);
    });

    test('returns null when characters are missing', () {
      expect(fuzzyScore('xyz', 'Go to Tasks'), isNull);
    });
  });
}
