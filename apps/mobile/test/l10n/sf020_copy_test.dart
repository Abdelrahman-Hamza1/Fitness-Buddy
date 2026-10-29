import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// SF-020's moral words about food and eating (A13 D16): "good food", "bad
/// food", "cheat", "guilt", "sinful", "clean eating", "junk". Case-insensitive
/// at word boundaries; the stems also catch their forms ("cheat day",
/// "guilty", "junk food", "good foods").
final RegExp sf020MoralWords = RegExp(
  r'\b(?:good\s+foods?|bad\s+foods?|cheat\w*|guilt\w*|sinful\w*|'
  r'clean\s+eating|junk\w*)\b',
  caseSensitive: false,
);

/// Every message value of the ARB file at [path] (keys without `@`).
Map<String, String> _messages(String path) {
  final arb = jsonDecode(File(path).readAsStringSync()) as Map<String, Object?>;
  return {
    for (final MapEntry(:key, :value) in arb.entries)
      if (!key.startsWith('@')) key: value! as String,
  };
}

void main() {
  test('SF-020 no app_en.arb value contains good food, bad food, cheat, '
      'guilt, sinful, clean eating or junk', () {
    final offending = <String>[
      for (final path in [
        'lib/l10n/app_en.arb',
        '../../packages/fb_design_system/lib/l10n/fb_ds_en.arb',
      ])
        for (final MapEntry(:key, :value) in _messages(path).entries)
          if (sf020MoralWords.hasMatch(value)) '$path: $key = $value',
    ];
    expect(offending, isEmpty);
    // The guard reads real copy: the file is the app's template.
    expect(_messages('lib/l10n/app_en.arb'), hasLength(greaterThan(500)));
  });

  test('SF-020 the guard catches each word and its forms, and passes '
      'neutral copy', () {
    for (final bad in [
      'Good food choices',
      'That was a BAD FOOD',
      'Cheat day!',
      'No more cheating',
      'Feeling guilty?',
      'Guilt-free',
      'Sinful dessert',
      'Clean eating plan',
      'Junk food',
      'junky snacks',
      'good   foods',
    ]) {
      expect(sf020MoralWords.hasMatch(bad), isTrue, reason: bad);
    }
    for (final ok in [
      'kcal over today',
      'Choose a lower target, or another goal.',
      'Cheddar',
      'Goodness',
      'Clean up the list',
      'Food search',
      'This week: 350 kcal over',
    ]) {
      expect(sf020MoralWords.hasMatch(ok), isFalse, reason: ok);
    }
  });
}
