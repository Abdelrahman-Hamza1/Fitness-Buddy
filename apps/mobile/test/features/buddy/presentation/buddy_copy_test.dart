import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../../l10n/sf020_copy_test.dart' show sf020MoralWords;

/// Alarm words a reply or card must never use either (SF-021: over target
/// is neutral).
final RegExp _alarm = RegExp(
  r'\b(?:warning|danger\w*|too\s+much|exceed\w*|failed)\b',
  caseSensitive: false,
);

void main() {
  // rule: A22 sf020-copy
  test('A22 reply and card copy has no moral food words', () {
    final arb = jsonDecode(
      File('lib/l10n/app_en.arb').readAsStringSync(),
    ) as Map<String, Object?>;
    final copy = {
      for (final MapEntry(:key, :value) in arb.entries)
        if (!key.startsWith('@') &&
            (key.startsWith('buddy') ||
                key.startsWith('proposal') ||
                key.startsWith('assumption')))
          key: value! as String,
    };
    expect(copy.length, greaterThan(60));
    final offending = [
      for (final MapEntry(:key, :value) in copy.entries)
        if (sf020MoralWords.hasMatch(value) || _alarm.hasMatch(value))
          '$key = $value',
    ];
    expect(offending, isEmpty);
  });
}
