import 'package:fb_domain/fb_domain.dart';
import 'package:glados/glados.dart';

import '../helpers/property.dart';

void main() {
  group('LC-021 week calendar:', () {
    test('LC-021 week starts Saturday by default', () {
      const calendar = WeekCalendar();
      expect(calendar.weekStart, DayOfWeek.saturday);
      // Tuesday 2026-10-13 is in the week Saturday 10-10 … Friday 10-16.
      final week = calendar.weekOf(LocalDate(2026, 10, 13));
      expect(week.start, LocalDate(2026, 10, 10));
      expect(week.end, LocalDate(2026, 10, 16));
      expect(
        calendar.weekStartOf(LocalDate(2026, 10, 10)),
        LocalDate(2026, 10, 10),
      );
      expect(
        calendar.weekStartOf(LocalDate(2026, 10, 16)),
        LocalDate(2026, 10, 10),
      );
      expect(calendar.daysInOrder, [
        DayOfWeek.saturday,
        DayOfWeek.sunday,
        DayOfWeek.monday,
        DayOfWeek.tuesday,
        DayOfWeek.wednesday,
        DayOfWeek.thursday,
        DayOfWeek.friday,
      ]);
    });

    test('LC-021 week start is configurable', () {
      const monday = WeekCalendar(weekStart: DayOfWeek.monday);
      const sunday = WeekCalendar(weekStart: DayOfWeek.sunday);
      final tuesday = LocalDate(2026, 10, 13);
      expect(monday.weekStartOf(tuesday), LocalDate(2026, 10, 12));
      expect(sunday.weekStartOf(tuesday), LocalDate(2026, 10, 11));
      expect(monday.daysInOrder.first, DayOfWeek.monday);
      expect(monday.daysInOrder.last, DayOfWeek.sunday);
      expect(sunday.daysInOrder.last, DayOfWeek.saturday);
      expect(monday, const WeekCalendar(weekStart: DayOfWeek.monday));
      expect(monday.hashCode, DayOfWeek.monday.hashCode);
      expect(monday == sunday, isFalse);
    });
  });

  group('LC-021 property: week start', () {
    Glados2(any.localDate, any.dayOfWeek, propertyRuns).test(
      'weekStartOf(d) ≤ d < weekStartOf(d)+7 and falls on the chosen weekday',
      (date, weekStart) {
        final calendar = WeekCalendar(weekStart: weekStart);
        final start = calendar.weekStartOf(date);
        expect(start.weekday, weekStart);
        expect(start.daysUntil(date), inInclusiveRange(0, 6));
        expect(calendar.weekOf(date).end, start.plusDays(6));
        expect(calendar.daysInOrder.toSet(), DayOfWeek.values.toSet());
      },
    );
  });
}
