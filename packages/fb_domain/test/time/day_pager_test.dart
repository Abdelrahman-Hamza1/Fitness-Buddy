import 'package:fb_domain/fb_domain.dart';
import 'package:fb_domain/testing.dart';
import 'package:test/test.dart';

void main() {
  test('HM-009 pager round trips, clamps and bounds the prefetch window', () {
    final today = LocalDate(2026, 10, 23);
    final pager = DayPager(today);
    expect(pager.pageCount, 3651);
    for (var i = 0; i < pager.pageCount; i++) {
      expect(pager.indexOf(pager.dateAt(i)), i);
    }
    expect(pager.indexOf(today.plusDays(1)), 3650);
    expect(pager.indexOf(today.plusDays(-4000)), 0);
    expect(pager.dateAt(-1), today.plusDays(-3650));
    expect(pager.dateAt(4000), today);
    expect(pager.canGoNext(today), isFalse);
    expect(pager.canGoNext(today.plusDays(-1)), isTrue);
    expect(pager.window(today), {today.plusDays(-1), today});
    expect(pager.window(today.plusDays(-2)), {
      today.plusDays(-3),
      today.plusDays(-2),
      today.plusDays(-1),
    });
    expect(pager.window(today.plusDays(-3650)), {
      today.plusDays(-3650),
      today.plusDays(-3649),
    });
    expect(DayPager(today, maxDays: 0).window(today), {today});
    expect(() => DayPager(today, maxDays: -1), throwsArgumentError);
  });

  test(
    'DY-001 Palestine DST: next midnight uses the offset of that instant',
    () {
      final transition = DateTime.utc(2026, 10, 23, 23);
      final clock = ManualClock(
        DateTime.utc(2026, 10, 23, 12),
        zone: (utc) => utc.isBefore(transition) ? 180 : 120,
      );
      expect(
        nextDayStartUtc(LocalDate(2026, 10, 23), clock),
        DateTime.utc(2026, 10, 23, 21),
      );
      expect(
        nextDayStartUtc(LocalDate(2026, 10, 24), clock),
        DateTime.utc(2026, 10, 24, 22),
      );
      final spring = DateTime.utc(2026, 3, 28);
      clock.zone = (utc) => utc.isBefore(spring) ? 120 : 180;
      expect(
        nextDayStartUtc(LocalDate(2026, 3, 28), clock),
        DateTime.utc(2026, 3, 28, 21),
      );
    },
  );
}
