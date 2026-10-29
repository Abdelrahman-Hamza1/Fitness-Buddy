import 'package:fb_domain/fb_domain.dart';
import 'package:glados/glados.dart';

import '../helpers/property.dart';

void main() {
  // 2026-10-17 is a Saturday.
  final today = LocalDate(2026, 10, 17);

  // rule: A22 date-hint
  test('A22 date hint resolves the closed day grammar on the phone', () {
    for (final (hint, expected) in [
      ('today', LocalDate(2026, 10, 17)),
      ('yesterday', LocalDate(2026, 10, 16)),
      ('daysAgo:2', LocalDate(2026, 10, 15)),
      ('daysAgo:999', today.plusDays(-999)),
      ('date:2016-10-19', LocalDate(2016, 10, 19)), // 3650 days back.
      ('lastWeekday:sat', LocalDate(2026, 10, 10)),
      ('lastWeekday:fri', LocalDate(2026, 10, 16)),
      ('lastWeekday:sun', LocalDate(2026, 10, 11)),
      ('lastWeekday:mon', LocalDate(2026, 10, 12)),
      ('date:10-03', LocalDate(2026, 10, 3)),
      ('date:10-17', LocalDate(2026, 10, 17)),
      ('date:12-25', LocalDate(2025, 12, 25)),
      ('date:02-29', LocalDate(2024, 2, 29)),
      ('date:2026-01-05', LocalDate(2026, 1, 5)),
    ]) {
      expect(DayHint.isValid(hint), isTrue, reason: hint);
      expect(DayHint.resolve(hint, today), expected, reason: hint);
    }
  });

  // rule: A22 date-hint
  test('A22 date hint outside the grammar or in the future resolves to '
      'nothing', () {
    for (final hint in [
      '',
      'Yesterday',
      'daysAgo:1',
      'daysAgo:0',
      'daysAgo:1000',
      'lastWeekday:monday',
      'date:13-01',
      'date:2026-02-30',
      'date:2026-10-18',
      'date:2027-01-01',
      'tomorrow',
      // Outside the diary's reach (DayPager's ten years, epoch).
      'date:1969-12-31',
      'date:2016-10-18',
    ]) {
      expect(DayHint.resolve(hint, today), isNull, reason: hint);
    }
    expect(DayHint.isValid('date:2026-02-30'), isTrue);
    // daysAgo:3651 is in the grammar but past ten years.
    final far = LocalDate(2030, 1, 1);
    expect(DayHint.resolve('daysAgo:999', far), isNotNull);
    expect(DayHint.resolve('date:${far.plusDays(-3651)}', far), isNull);
    expect(DayHint.resolve('date:${far.plusDays(-3650)}', far), isNotNull);
    expect(DayHint.isValid('tomorrow'), isFalse);
  });

  Glados2(
    any.intInRange(1, 999),
    any.intInRange(-4000, 4000),
    propertyRuns,
  ).test('A22 date hint never resolves after today', (n, offset) {
    final day = LocalDate(2026, 10, 17).plusDays(offset);
    for (final hint in [
      if (n >= 2) 'daysAgo:$n',
      for (final w in ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'])
        'lastWeekday:$w',
      'date:${day.toString().substring(5)}',
    ]) {
      final resolved = DayHint.resolve(hint, today);
      if (resolved != null) {
        expect(resolved.isAfter(today), isFalse, reason: hint);
      }
      if (hint.startsWith('lastWeekday')) {
        final back = today.epochDay - resolved!.epochDay;
        expect(back, inInclusiveRange(1, 7), reason: hint);
      }
    }
    expect(
      DayHint.resolve('date:$day', today),
      day.isAfter(today) || day.daysUntil(today) > DayPager.defaultMaxDays
          ? isNull
          : day,
    );
  });
}
