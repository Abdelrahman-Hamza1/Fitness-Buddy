import 'package:fb_domain/fb_domain.dart';
import 'package:test/test.dart';

LocalDate _d(int y, int m, int d) => LocalDate(y, m, d);

RamadanCalendar _cal([Iterable<RamadanSeason> seasons = const []]) =>
    RamadanCalendar(RamadanSettings(seasons));

void main() {
  group('LC-030 Umm al-Qura dates', () {
    // van Gent's published list (1447–1450) and hijri-converter (1451–1457).
    const expected = {
      1447: ('2026-02-18', '2026-03-19', 30),
      1448: ('2027-02-08', '2027-03-08', 29),
      1449: ('2028-01-28', '2028-02-25', 29),
      1450: ('2029-01-16', '2029-02-13', 29),
      1451: ('2030-01-05', '2030-02-03', 30),
      1452: ('2030-12-26', '2031-01-23', 29),
      1453: ('2031-12-15', '2032-01-13', 30),
      1454: ('2032-12-04', '2033-01-01', 29),
      1455: ('2033-11-23', '2033-12-22', 30),
      1456: ('2034-11-12', '2034-12-11', 30),
      1457: ('2035-11-01', '2035-11-30', 30),
    };
    for (final MapEntry(key: year, value: (start, end, days))
        in expected.entries) {
      test('$year: $start to $end', () {
        final p = _cal().calendarPeriod(year)!;
        expect(p.start, LocalDate.parse(start));
        expect(p.end, LocalDate.parse(end));
        expect(p.days, days);
      });
    }

    test('every year of the table has 29 or 30 days, about 354 days apart', () {
      final years = UmmAlQura.ramadan.keys.toList()..sort();
      expect(years.first, lessThanOrEqualTo(1446));
      expect(years.last, greaterThanOrEqualTo(1457));
      for (final y in years) {
        expect(_cal().calendarPeriod(y)!.days, inInclusiveRange(29, 30));
        if (UmmAlQura.ramadan.containsKey(y + 1)) {
          final gap = _cal()
              .calendarPeriod(y)!
              .start
              .daysUntil(_cal().calendarPeriod(y + 1)!.start);
          expect(gap, inInclusiveRange(353, 356));
        }
      }
    });

    test('outside the table there is no Ramadan', () {
      expect(_cal().calendarPeriod(1300), isNull);
      expect(_cal().relevant(_d(2090, 1, 1)), isNull);
    });
  });

  group('LC-030 the ±1-day shift and the on/off decision', () {
    test('shifts move the start and end independently', () {
      final cal = _cal([
        RamadanSeason(hijriYear: 1447, on: true, startShift: 1, endShift: -1),
      ]);
      final p = cal.period(1447)!;
      expect(p.start, _d(2026, 2, 19));
      expect(p.end, _d(2026, 3, 18));
      expect(cal.isOn(_d(2026, 2, 18)), isFalse);
      expect(cal.isOn(_d(2026, 2, 19)), isTrue);
      expect(cal.isOn(_d(2026, 3, 18)), isTrue);
      expect(cal.isOn(_d(2026, 3, 19)), isFalse);
      expect(p.dayOf(_d(2026, 2, 19)), 1);
    });

    test('an earlier start (−1) and a later end (+1)', () {
      final cal = _cal([
        RamadanSeason(hijriYear: 1448, on: true, startShift: -1, endShift: 1),
      ]);
      expect(cal.isOn(_d(2027, 2, 6)), isFalse);
      expect(cal.isOn(_d(2027, 2, 7)), isTrue);
      expect(cal.isOn(_d(2027, 3, 9)), isTrue);
      expect(cal.isOn(_d(2027, 3, 10)), isFalse);
      expect(cal.period(1448)!.days, 31);
    });

    test('mode off or undecided: no Ramadan days, normal slots', () {
      for (final cal in [
        _cal(),
        _cal([RamadanSeason(hijriYear: 1447, on: false)]),
      ]) {
        expect(cal.isOn(_d(2026, 3, 1)), isFalse);
        expect(cal.slotModeOn(_d(2026, 3, 1)), SlotMode.normal);
        expect(cal.onPeriods, isEmpty);
      }
    });

    test('LC-034 a not-fasting day uses normal slots and no maintain', () {
      final day = _d(2026, 3, 1);
      final season = RamadanSeason(hijriYear: 1447, on: true, maintain: true);
      final fasting = _cal([season]);
      expect(fasting.slotModeOn(day), SlotMode.ramadan);
      expect(fasting.maintainOn(day), isTrue);
      final cal = RamadanCalendar(RamadanSettings([season]), notFasting: [day]);
      expect(cal.notFastingOn(day), isTrue);
      expect(cal.slotModeOn(day), SlotMode.normal);
      expect(cal.maintainOn(day), isFalse);
      expect(cal.isFastingDay(day), isFalse);
      expect(cal.isOn(day), isTrue, reason: 'charts still shade the day');
      expect(cal.slotModeOn(day.plusDays(1)), SlotMode.ramadan);
      // A mark outside a Ramadan with the mode on means nothing.
      final off = RamadanCalendar(RamadanSettings.none, notFasting: [day]);
      expect(off.notFastingOn(day), isFalse);
    });

    test('TG-061 maintain stops after Ramadan', () {
      final cal = _cal([
        RamadanSeason(hijriYear: 1447, on: true, maintain: true),
      ]);
      expect(cal.maintainOn(_d(2026, 3, 19)), isTrue);
      expect(cal.maintainOn(_d(2026, 3, 20)), isFalse);
      expect(cal.slotModeOn(_d(2026, 3, 20)), SlotMode.normal);
    });

    test('on periods list only the seasons switched on', () {
      final cal = _cal([
        RamadanSeason(hijriYear: 1447, on: true),
        RamadanSeason(hijriYear: 1448, on: false),
        RamadanSeason(hijriYear: 1449, on: true, endShift: 1),
      ]);
      expect(cal.onPeriods.map((p) => p.hijriYear), [1447, 1449]);
      expect(cal.onPeriods.last.end, _d(2028, 2, 26));
    });
  });

  group('LC-031 the switch-on proposal', () {
    test('appears three days before and lasts until the end', () {
      final cal = _cal();
      expect(cal.proposalOn(_d(2027, 2, 4)), isNull);
      expect(cal.proposalOn(_d(2027, 2, 5))?.hijriYear, 1448);
      expect(cal.proposalOn(_d(2027, 2, 6))?.hijriYear, 1448, reason: 'J11');
      expect(cal.proposalOn(_d(2027, 3, 8))?.hijriYear, 1448);
      expect(cal.proposalOn(_d(2027, 3, 9)), isNull);
    });

    test('LC-030 on the calendar first day of Shawwal the ended Ramadan can '
        'still be extended to include today; the proposal is not shown', () {
      final shawwal1 = _d(2026, 3, 20);
      final cal = _cal([RamadanSeason(hijriYear: 1447, on: true)]);
      expect(cal.isOn(shawwal1), isFalse);
      final extended = _cal([cal.settings[1447]!.copyWith(endShift: 1)]);
      expect(extended.relevant(shawwal1)?.end, shawwal1);
      expect(extended.isFastingDay(shawwal1), isTrue);
      expect(_cal().proposalOn(shawwal1), isNull);
    });

    test('a decision either way is never asked again', () {
      for (final on in [true, false]) {
        final cal = _cal([RamadanSeason(hijriYear: 1448, on: on)]);
        expect(cal.proposalOn(_d(2027, 2, 7)), isNull);
      }
    });

    test('the relevant Ramadan is the current one, else the next', () {
      final cal = _cal();
      expect(cal.relevant(_d(2026, 3, 19))?.hijriYear, 1447);
      expect(
        cal.relevant(_d(2026, 3, 20))?.hijriYear,
        1447,
        reason: 'the day after the end can still be added (+1)',
      );
      expect(cal.relevant(_d(2026, 3, 21))?.hijriYear, 1448);
      expect(cal.relevant(_d(2026, 10, 31))?.hijriYear, 1448);
    });
  });

  test('TG-060 the targets offer: the first seven days until answered', () {
    final on = _cal([RamadanSeason(hijriYear: 1447, on: true)]);
    expect(on.targetsOfferOn(LocalDate(2026, 2, 17)), isNull);
    expect(on.targetsOfferOn(LocalDate(2026, 2, 18))?.hijriYear, 1447);
    expect(on.targetsOfferOn(LocalDate(2026, 2, 24))?.hijriYear, 1447);
    expect(on.targetsOfferOn(LocalDate(2026, 2, 25)), isNull);
    final answered = _cal([
      RamadanSeason(hijriYear: 1447, on: true, targetsAnswered: true),
    ]);
    expect(answered.targetsOfferOn(LocalDate(2026, 2, 20)), isNull);
    expect(_cal().targetsOfferOn(LocalDate(2026, 2, 20)), isNull);
  });

  group('settings JSON', () {
    test('round-trips and keeps only non-default fields', () {
      final settings = RamadanSettings([
        RamadanSeason(
          hijriYear: 1447,
          on: true,
          startShift: 1,
          maintain: true,
          targetsAnswered: true,
        ),
        RamadanSeason(hijriYear: 1448, on: false),
      ]);
      expect(settings.toJson(), {
        '1447': {
          'on': true,
          'startShift': 1,
          'maintain': true,
          'targetsAnswered': true,
        },
        '1448': {'on': false},
      });
      expect(RamadanSettings.fromJson(settings.toJson()), settings);
    });

    test('A41a fix 2: a fasting mark is its own key per date; the marks of '
        'a Ramadan cover its days and one either side', () {
      expect(
        RamadanFasting.keyName(_d(2027, 2, 11)),
        'ramadan.fasting.d20270211',
      );
      expect(SettingsOp.isKey(RamadanFasting.keyName(_d(2027, 2, 11))), isTrue);
      final dates = RamadanFasting.datesOf(_cal().calendarPeriod(1448)!);
      expect(dates.first, _d(2027, 2, 7));
      expect(dates.last, _d(2027, 3, 9));
      expect(dates, hasLength(31));
      expect(FastingMark.values.map((m) => m.name), ['notFasting', 'fasting']);
    });

    test('unreadable years are skipped, never an error', () {
      final read = RamadanSettings.fromJson({
        '1447': {'on': true},
        'x': {'on': true},
        '1448': {'on': 'yes'},
        '1449': {'on': true, 'startShift': 2},
        '1450': 7,
      });
      expect(read.seasons.map((s) => s.hijriYear), [1447]);
      expect(RamadanSettings.fromJson('nope'), RamadanSettings.none);
      expect(RamadanSettings.fromJson(null), RamadanSettings.none);
    });

    test('withSeason replaces that year', () {
      final s = RamadanSettings.none
          .withSeason(RamadanSeason(hijriYear: 1448, on: true))
          .withSeason(RamadanSeason(hijriYear: 1448, on: false));
      expect(s[1448]!.on, isFalse);
      expect(s.seasons, hasLength(1));
    });

    test('shifts beyond one day are rejected', () {
      expect(
        () => RamadanSeason(hijriYear: 1448, on: true, startShift: 2),
        throwsRangeError,
      );
    });
  });
}
