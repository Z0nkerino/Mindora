import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// EN and RU must always have the same keys and placeholders, and no
/// translation may be left empty or identical-by-accident to English for
/// sentences.
void main() {
  Map<String, dynamic> load(String locale) =>
      jsonDecode(File('lib/l10n/app_$locale.arb').readAsStringSync())
          as Map<String, dynamic>;

  final en = load('en');
  final ru = load('ru');
  Iterable<String> keys(Map<String, dynamic> m) =>
      m.keys.where((k) => !k.startsWith('@'));

  test('same message keys in EN and RU', () {
    expect(keys(ru).toSet(), keys(en).toSet());
  });

  test('no empty translations', () {
    for (final k in keys(ru)) {
      expect((ru[k] as String).trim(), isNotEmpty, reason: k);
    }
  });

  test('placeholders match', () {
    final re = RegExp(r'\{(\w+)\}');
    for (final k in keys(en)) {
      final a = re.allMatches(en[k] as String).map((m) => m[1]).toSet();
      final b = re.allMatches(ru[k] as String).map((m) => m[1]).toSet();
      expect(b, a, reason: k);
    }
  });

  test('sentences are actually translated', () {
    for (final k in keys(en)) {
      final v = en[k] as String;
      if (v.contains(' ') && v.length > 12) {
        expect(ru[k], isNot(v), reason: '$k looks untranslated');
      }
    }
  });
}
