import 'package:fb_domain/fb_domain.dart';
import 'package:test/test.dart';

import '../helpers/body.dart';

final _trend = TrendWeight();

/// Weigh-ins of [kgs] on the days [days] after [day0].
List<WeighIn> _on(List<int> days, List<double> kgs, {MassUnit? unit}) => [
  for (var i = 0; i < days.length; i++)
    storedOn(
      dayN(days[i]),
      kgs[i],
      id: weighInId(i),
      unit: unit ?? MassUnit.kilogram,
    ),
];

WeightReading? _read(List<WeighIn> weighIns, int day) => WeightReading.of(
  trend: _trend.compute(weighIns),
  weighIns: weighIns,
  date: dayN(day),
);

// Covers: WB-011
void main() {
  test('WB-011 no weigh-in on or before the day reads nothing', () {
    expect(_read(const [], 0), isNull);
    expect(_read(_on([5], [80]), 4), isNull);
  });

  test('WB-011 a single weigh-in is the latest, with no change', () {
    final reading = _read(_on([0], [107.7]), 3)! as LatestWeightReading;
    expect(reading.mainKg, 107.7);
    expect(reading.lastDate, dayN(0));
    expect(reading.changeKg, isNull);
    expect(reading.daysSincePrevious, isNull);
  });

  test('WB-011 weekly weigh-ins show the latest and the change since the one '
      'before; the rate stays the trend', () {
    final weighIns = _on([0, 7, 14, 21, 31], [110, 109.5, 109.2, 108.8, 107.7]);
    final trend = _trend.compute(weighIns);
    final reading = _read(weighIns, 31)! as LatestWeightReading;
    expect(reading.mainKg, 107.7);
    expect(reading.lastInput, const WeighInInput(107.7, MassUnit.kilogram));
    expect(reading.changeKg, closeTo(107.7 - 108.8, 1e-9));
    expect(reading.daysSincePrevious, 10);
    expect(reading.weeklyRateKg, trend.asOf(dayN(31)).weeklyRateKg);
    expect(reading.weeklyRateKg, isNotNull);
  });

  test('WB-011 daily weigh-ins show the trend and the latest next to it', () {
    final days = [for (var d = 0; d < 20; d++) d];
    final kgs = [for (var d = 0; d < 20; d++) 109 - d * .05];
    final weighIns = _on(days, kgs);
    final asOf = _trend.compute(weighIns).asOf(dayN(19));
    final reading = _read(weighIns, 19)! as TrendWeightReading;
    expect(reading.mainKg, asOf.trendKg);
    expect(reading.lastKg, kgs.last);
    expect(reading.lastDate, dayN(19));
    expect(reading.weeklyRateKg, asOf.weeklyRateKg);
  });

  test('WB-011 the threshold is 3 weigh-in days in the day and the 13 '
      'before', () {
    // Days 0, 6 and 13: three in the window of day 13 (days 0–13).
    final weighIns = _on([0, 6, 13], [100, 99, 98]);
    expect(_read(weighIns, 13), isA<TrendWeightReading>());
    // On day 14 day 0 has left the window: two remain.
    expect(_read(weighIns, 14), isA<LatestWeightReading>());
    // Only two days before day 13: latest.
    expect(_read(weighIns, 12), isA<LatestWeightReading>());
  });

  test('WB-011 mixed: daily then a pause turns back to the latest', () {
    final weighIns = _on([0, 1, 2, 3, 4, 20], [100, 100, 99.8, 99.6, 99.5, 98]);
    expect(_read(weighIns, 4), isA<TrendWeightReading>());
    final later = _read(weighIns, 20)! as LatestWeightReading;
    expect(later.mainKg, 98);
    expect(later.daysSincePrevious, 16);
    expect(later.changeKg, closeTo(98 - 99.5, 1e-9));
  });

  test('WB-011 a gap of more than 14 days reads the old weigh-in as the '
      'latest, stale after 28 days', () {
    final weighIns = _on([0, 1, 2], [90, 90.2, 90.4]);
    final soon = _read(weighIns, 20)! as LatestWeightReading;
    expect(soon.mainKg, 90.4);
    expect(soon.lastDate, dayN(2));
    expect(soon.isStale, isFalse);
    final stale = _read(weighIns, 40)!;
    expect(stale, isA<LatestWeightReading>());
    expect(stale.isStale, isTrue);
    expect(stale.weeklyRateKg, isNull);
  });

  test('WB-011 WB-003 several weigh-ins on a day count once and the day '
      'choice is the number', () {
    final weighIns = [
      storedOn(dayN(0), 100, id: weighInId(1)),
      storedOn(dayN(0), 101, id: weighInId(2), hour: 9),
      storedOn(dayN(0), 102, id: weighInId(3), hour: 20),
      storedOn(dayN(5), 99, id: weighInId(4)),
      storedOn(dayN(5), 98.5, id: weighInId(5), hour: 21, preferred: true),
    ];
    final reading = _read(weighIns, 5)! as LatestWeightReading;
    final choice = DayChoice.of(weighIns).last;
    expect(reading.mainKg, choice.kg);
    expect(reading.mainKg, 98.5);
    expect(reading.daysSincePrevious, 5);
  });

  test('WB-011 TD-017 a weigh-in typed in lb keeps its typed value', () {
    final weighIns = _on([0, 9], [240, 237.4], unit: MassUnit.pound);
    final reading = _read(weighIns, 9)! as LatestWeightReading;
    expect(reading.lastInput, const WeighInInput(237.4, MassUnit.pound));
    expect(reading.mainKg, const WeighInInput(237.4, MassUnit.pound).kg);
  });

  test('WB-011 toString shows no values', () {
    final reading = _read(_on([0], [107.7]), 0)!;
    expect(reading.toString(), isNot(contains('107')));
  });
}
