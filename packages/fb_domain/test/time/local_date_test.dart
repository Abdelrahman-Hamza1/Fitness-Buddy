import 'package:fb_domain/fb_domain.dart';
import 'package:glados/glados.dart';

import '../helpers/property.dart';

void main() {
  group('LocalDate:', () {
    test('parse/format ISO, invalid dates rejected', () {
      final date = LocalDate.parse('2026-10-13');
      expect((date.year, date.month, date.day), (2026, 10, 13));
      expect(date.toString(), '2026-10-13');
      expect(LocalDate(5, 1, 2).toString(), '0005-01-02');
      expect(LocalDate.parse('2024-02-29'), LocalDate(2024, 2, 29));

      for (final bad in [
        '2026-02-29', // not a leap year
        '2026-13-01',
        '2026-00-10',
        '2026-04-31',
        '2026-10-00',
        '0000-01-01',
        '2026-1-13',
        '2026-10-13T00:00',
        ' 2026-10-13',
        '20261013',
        '',
      ]) {
        expect(LocalDate.tryParse(bad), isNull, reason: bad);
        expect(() => LocalDate.parse(bad), throwsFormatException, reason: bad);
      }
      expect(() => LocalDate(2026, 2, 30), throwsArgumentError);
      expect(() => LocalDate(10000, 1, 1), throwsArgumentError);
      expect(() => LocalDate(2026, 1, 32), throwsArgumentError);
    });

    test('epoch days, plusDays and daysUntil cross months and years', () {
      expect(LocalDate(1970, 1, 1).epochDay, 0);
      expect(LocalDate(1969, 12, 31).epochDay, -1);
      expect(LocalDate.fromEpochDay(0), LocalDate(1970, 1, 1));
      expect(LocalDate(2024, 2, 28).plusDays(1), LocalDate(2024, 2, 29));
      expect(LocalDate(2026, 12, 31).plusDays(1), LocalDate(2027, 1, 1));
      expect(LocalDate(2026, 3, 1).plusDays(-1), LocalDate(2026, 2, 28));
      expect(LocalDate(2026, 1, 1).daysUntil(LocalDate(2027, 1, 1)), 365);
      expect(LocalDate(2027, 1, 1).daysUntil(LocalDate(2026, 1, 1)), -365);
      expect(LocalDate(1, 1, 1), LocalDate.fromEpochDay(-719162));
      expect(LocalDate(9999, 12, 31), LocalDate.fromEpochDay(2932896));
      expect(() => LocalDate(9999, 12, 31).plusDays(1), throwsRangeError);
      expect(() => LocalDate(1, 1, 1).plusDays(-1), throwsRangeError);
    });

    test('weekday follows ISO numbering', () {
      expect(LocalDate(2026, 10, 13).weekday, DayOfWeek.tuesday);
      expect(LocalDate(2026, 10, 17).weekday, DayOfWeek.saturday);
      expect(LocalDate(2026, 10, 18).weekday, DayOfWeek.sunday);
      expect(DayOfWeek.fromIso(1), DayOfWeek.monday);
      expect(DayOfWeek.sunday.isoNumber, 7);
      expect(() => DayOfWeek.fromIso(0), throwsRangeError);
      expect(() => DayOfWeek.fromIso(8), throwsRangeError);
    });

    test('compare, equality and hash', () {
      final a = LocalDate(2026, 10, 13);
      final b = LocalDate(2026, 10, 14);
      expect(a.compareTo(b), lessThan(0));
      expect(a.isBefore(b), isTrue);
      expect(b.isAfter(a), isTrue);
      expect(a.isAfter(a), isFalse);
      expect(LocalDate(2025, 12, 31).compareTo(a), lessThan(0));
      expect(LocalDate(2026, 11, 1).compareTo(a), greaterThan(0));
      expect(a, LocalDate.parse('2026-10-13'));
      expect(a.hashCode, LocalDate(2026, 10, 13).hashCode);
      expect(a == b, isFalse);
    });
  });

  group('property: LocalDate', () {
    Glados2(any.localDate, any.intInRange(-100000, 100000), propertyRuns).test(
      'plusDays(n).plusDays(−n) is identity',
      (date, days) {
        expect(date.plusDays(days).plusDays(-days), date);
        expect(date.daysUntil(date.plusDays(days)), days);
      },
    );

    Glados2(any.localDate, any.localDate, propertyRuns).test(
      'parse(toString) is identity and text order is date order',
      (a, b) {
        expect(LocalDate.parse(a.toString()), a);
        expect(a.toString().compareTo(b.toString()).sign, a.compareTo(b).sign);
        expect(a.compareTo(b).sign, a.epochDay.compareTo(b.epochDay).sign);
      },
    );
  });
}
