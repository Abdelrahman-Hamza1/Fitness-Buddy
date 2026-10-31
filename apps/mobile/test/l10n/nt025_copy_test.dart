import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'sf020_copy_test.dart' show sf020MoralWords;

/// NT-025's guilt-tripping phrases on top of SF-020's words.
final RegExp _guilt = RegExp(
  r"\b(?:forg[eo]t\w*|streak\w*|miss(?:ed|ing)?|don't\s+break|should\s+have|"
  r'failed|lazy)\b',
  caseSensitive: false,
);

void main() {
  test('NT-025 notification and reminder copy is neutral: no SF-020 words, '
      'no "forgot", "streak", "missed" or "don\'t break"', () {
    final arb = jsonDecode(
      File('lib/l10n/app_en.arb').readAsStringSync(),
    ) as Map<String, Object?>;
    final copy = {
      for (final MapEntry(:key, :value) in arb.entries)
        if (key.startsWith('notif') || key.startsWith('weeklySummary'))
          key: value! as String,
    };
    expect(copy.length, greaterThan(40), reason: 'the guard reads real copy');
    final offending = [
      for (final MapEntry(:key, :value) in copy.entries)
        if (sf020MoralWords.hasMatch(value) || _guilt.hasMatch(value))
          '$key = $value',
    ];
    expect(offending, isEmpty);
    for (final bad in [
      'You forgot to log',
      "Don't break your streak",
      'You missed a workout',
    ]) {
      expect(_guilt.hasMatch(bad), isTrue, reason: bad);
    }
  });
}
