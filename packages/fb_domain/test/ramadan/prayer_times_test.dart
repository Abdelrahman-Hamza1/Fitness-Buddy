import 'package:fb_domain/fb_domain.dart';
import 'package:test/test.dart';

/// Ramallah (GeoNames 282239, the owner's city in the bundled list).
final _ramallah = GeoPoint(31.89964, 35.20422);

/// A published Ramallah timetable (A41a D2, exit criterion 2): IslamicFinder,
/// Ramallah (geonames 282239), method Muslim World League (Fajr 18°),
/// https://www.islamicfinder.org/world/palestine/282239/ramallah-prayer-times/
/// monthly pages for 2026, fetched 2026-10-31. Local time, Asia/Hebron:
/// UTC+2, and UTC+3 from 2026-03-28 to 2026-10-23 (tzdata 2026e).
/// (date, UTC offset h, Fajr, Maghrib).
const _timetable = [
  ('2026-02-18', 2, '04:58', '17:29'), // 1 Ramadan 1447
  ('2026-02-25', 2, '04:51', '17:34'),
  ('2026-03-05', 2, '04:42', '17:41'),
  ('2026-03-19', 2, '04:24', '17:51'), // last day of Ramadan 1447
  ('2026-03-28', 3, '05:10', '18:58'), // DST starts
  ('2026-03-29', 3, '05:09', '18:58'),
  ('2026-06-15', 3, '03:54', '19:48'),
  ('2026-07-15', 3, '04:08', '19:48'),
  ('2026-10-01', 3, '05:13', '18:26'),
  ('2026-10-24', 2, '04:28', '17:00'), // DST ended overnight
  ('2026-10-31', 2, '04:33', '16:53'),
  ('2026-12-15', 2, '05:05', '16:38'),
];

DateTime _utc(String date, int offsetHours, String hhmm) {
  final d = LocalDate.parse(date);
  final [h, m] = hhmm.split(':').map(int.parse).toList();
  return DateTime.utc(
    d.year,
    d.month,
    d.day,
    h,
    m,
  ).subtract(Duration(hours: offsetHours));
}

void main() {
  group('LC-033 prayer times match a published Ramallah timetable', () {
    for (final (date, offset, fajr, maghrib) in _timetable) {
      test('$date: Fajr and Maghrib within ±2 minutes', () {
        final day = PrayerTimes.on(LocalDate.parse(date), _ramallah)!;
        final fajrDiff = day.fajrUtc.difference(_utc(date, offset, fajr));
        final maghribDiff = day.maghribUtc.difference(
          _utc(date, offset, maghrib),
        );
        expect(fajrDiff.inMinutes.abs(), lessThanOrEqualTo(2));
        expect(maghribDiff.inMinutes.abs(), lessThanOrEqualTo(2));
      });
    }
  });

  test('times are whole UTC minutes, in order, on the date', () {
    final day = PrayerTimes.on(LocalDate(2027, 2, 8), _ramallah)!;
    for (final t in [day.fajrUtc, day.sunriseUtc, day.maghribUtc]) {
      expect(t.isUtc, isTrue);
      expect(t.second, 0);
    }
    expect(day.fajrUtc.isBefore(day.sunriseUtc), isTrue);
    expect(day.sunriseUtc.isBefore(day.maghribUtc), isTrue);
    expect(day.date, LocalDate(2027, 2, 8));
  });

  test(
    'a larger Fajr angle is earlier; Jordan adds five minutes to Maghrib',
    () {
      final date = LocalDate(2026, 3, 1);
      final mwl = PrayerTimes.on(date, _ramallah)!;
      final egypt = PrayerTimes.on(date, _ramallah, method: .egypt)!;
      final jordan = PrayerTimes.on(date, _ramallah, method: .jordan)!;
      expect(egypt.fajrUtc.isBefore(mwl.fajrUtc), isTrue);
      expect(jordan.maghribUtc.difference(mwl.maghribUtc).inMinutes, 5);
      expect(jordan.fajrUtc, mwl.fajrUtc);
    },
  );

  group(
    'high latitudes: the middle of the night rule, applied consistently',
    () {
      final oslo = GeoPoint(59.91, 10.75);
      // Half the night before sunrise, from the day's own sunrise and sunset.
      Duration halfNight(PrayerDay d) =>
          (const Duration(hours: 24) - d.maghribUtc.difference(d.sunriseUtc)) ~/
          2;

      test('Fajr is never earlier than the middle of the night, and equals it '
          'when 18° is not reached', () {
        for (var i = 0; i < 120; i++) {
          final d = PrayerTimes.on(LocalDate(2026, 3, 1).plusDays(i), oslo)!;
          final bound = d.sunriseUtc.subtract(halfNight(d));
          expect(
            d.fajrUtc.difference(bound).inMinutes,
            greaterThanOrEqualTo(-2),
            reason: '${d.date}',
          );
        }
        final june = PrayerTimes.on(LocalDate(2026, 6, 21), oslo)!;
        expect(
          june.fajrUtc
              .difference(june.sunriseUtc.subtract(halfNight(june)))
              .inMinutes
              .abs(),
          lessThanOrEqualTo(2),
        );
      });

      test('Fajr moves smoothly across the days the rule starts to apply', () {
        for (var i = 0; i < 120; i++) {
          final a = PrayerTimes.on(LocalDate(2026, 3, 1).plusDays(i), oslo)!;
          final b = PrayerTimes.on(LocalDate(2026, 3, 2).plusDays(i), oslo)!;
          final change =
              b.fajrUtc.difference(a.fajrUtc) - const Duration(hours: 24);
          // The 18° time speeds up as it nears the bound (33 min on
          // 2026-04-21 in Oslo), then joins it: no jump of hours (the old
          // mismatched bounds jumped 2.6 h from 04-21 to 04-22).
          expect(change.inMinutes.abs(), lessThan(45), reason: '${a.date}');
        }
      });
    },
  );

  test('polar day has no times', () {
    expect(
      PrayerTimes.on(LocalDate(2026, 6, 21), GeoPoint(78.22, 15.65)),
      isNull,
    );
  });

  test('stored method names round-trip; unknown names read as null', () {
    for (final m in PrayerMethod.values) {
      expect(PrayerMethod.fromName(m.name), m);
    }
    expect(PrayerMethod.fromName('palestine2'), isNull);
  });

  test('GeoPoint rejects impossible coordinates', () {
    expect(() => GeoPoint(91, 0), throwsArgumentError);
    expect(() => GeoPoint(0, 181), throwsArgumentError);
    expect(() => GeoPoint(double.nan, 0), throwsArgumentError);
  });
}
