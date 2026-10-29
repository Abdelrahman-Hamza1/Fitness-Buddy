import 'dart:math' as math;

import 'package:fb_domain/fb_domain.dart';
import 'package:glados/glados.dart';

import '../helpers/body.dart';
import '../helpers/property.dart';

/// A step of a generated series: days since the previous weigh-in (1–60)
/// and the value (20.00–500.00 kg).
typedef _Step = (int gap, double kg);

/// A row of a generated series with same-day pairs: days since the previous
/// row (0–60; 0 is the same day), the hour, the value and the day's trend
/// pick (WB-003).
typedef _Row = (int gap, int hour, double kg, bool preferred);

extension on Any {
  Generator<double> get bodyKg =>
      intInRange(2000, 50001).map((hundredths) => hundredths / 100);

  Generator<int> get gapDays => intInRange(1, 61);

  /// A same-day row about one time in three.
  Generator<_Row> get row => combine4(
    intInRange(0, 3).bind((same) => same == 0 ? always(0) : gapDays),
    intInRange(0, 24),
    bodyKg,
    intInRange(0, 5).map((n) => n == 0),
    (gap, hour, kg, preferred) => (gap, hour, kg, preferred),
  );
}

/// The weigh-ins of [steps], the first on [day0] (its gap is ignored).
List<WeighIn> _series(List<_Step> steps) =>
    _rows([for (final (gap, kg) in steps) (gap, 7, kg, false)]);

/// The weigh-ins of [rows], the first on [day0] (its gap is ignored).
List<WeighIn> _rows(List<_Row> rows) {
  var day = 0;
  return [
    for (final (i, (gap, hour, kg, preferred)) in rows.indexed)
      storedOn(
        dayN(day += i == 0 ? 0 : gap),
        kg,
        id: weighInId(i),
        hour: hour,
        preferred: preferred,
      ),
  ];
}

/// Weigh-ins of [kgs] on the days [days] after [day0].
List<WeighIn> _on(List<int> days, List<double> kgs) => [
  for (var i = 0; i < days.length; i++)
    storedOn(dayN(days[i]), kgs[i], id: weighInId(i)),
];

final _trend = TrendWeight();
final double _daily = TrendWeightConfig.standard.alpha(1);

void main() {
  Glados(any.nonEmptyList(any.row), propertyRuns).test(
    'WB-010 property: the trend stays within the min and max of the '
    'inputs so far',
    (rows) {
      final weighIns = _rows(rows);
      final trend = _trend.compute(weighIns);
      expect(trend.points, hasLength(DayChoice.of(weighIns).length));
      var low = double.infinity;
      var high = double.negativeInfinity;
      for (final point in trend.points) {
        low = math.min(low, point.rawKg);
        high = math.max(high, point.rawKg);
        expect(point.trendKg, inInclusiveRange(low, high));
      }
    },
  );

  Glados2(any.list(any.gapDays), any.bodyKg, propertyRuns).test(
    'WB-010 property: a constant series gives that constant exactly',
    (gaps, c) {
      final trend = _trend.compute(
        _series([(0, c), for (final gap in gaps) (gap, c)]),
      );
      for (final point in trend.points) {
        expect(point.trendKg, c);
      }
    },
  );

  Glados3(any.bodyKg, any.bodyKg, any.intInRange(1, 61), propertyRuns).test(
    'WB-010 property: from a trend T₀ ≠ c, after n daily weigh-ins of c, '
    '|Tₙ − c| ≤ (1 − α(1))ⁿ · |T₀ − c|',
    (t0, c, n) {
      final start = t0 == c ? c + 1 : t0;
      final trend = _trend.compute(
        _series([(0, start), for (var i = 0; i < n; i++) (1, c)]),
      );
      expect(trend.points.first.trendKg, start);
      for (var i = 1; i <= n; i++) {
        final bound = math.pow(1 - _daily, i) * (start - c).abs();
        expect(
          (trend.points[i].trendKg - c).abs(),
          lessThanOrEqualTo(bound + 1e-9),
          reason: 'after $i',
        );
      }
    },
  );

  Glados3(
    any.combine2(any.bodyKg, any.list(any.gapDays), (c, g) {
      return (c, g);
    }),
    any.gapDays,
    any.bodyKg,
    propertyRuns,
  ).test('WB-010 property: one outlier in a constant series moves the trend by '
      'α(gap) of its distance, never more than 75 %', (constant, gap, outlier) {
    final (c, gaps) = constant;
    final steps = [(0, c), for (final g in gaps) (g, c), (gap, outlier)];
    final trend = _trend.compute(_series(steps));
    final moved = trend.latest!.trendKg - c;
    final alpha = TrendWeightConfig.standard.alpha(gap);
    expect(moved, closeTo(alpha * (outlier - c), 1e-9));
    expect(alpha, lessThanOrEqualTo(0.75));
    expect(moved.abs(), lessThanOrEqualTo(0.75 * (outlier - c).abs() + 1e-9));
  });

  Glados(
    any.nonEmptyList(
      any.combine3(any.row, any.int, any.bool, (row, key, dup) {
        return (row, key, dup);
      }),
    ),
    propertyRuns,
  ).test(
    "WB-010 property: input order and repeated rows don't change the result",
    (rows) {
      final weighIns = _rows([for (final (row, _, _) in rows) row]);
      final keyed = [
        for (var i = 0; i < rows.length; i++) (rows[i], weighIns[i]),
      ];
      final shuffled = [
        for (final ((_, _, dup), weighIn) in [
          ...keyed,
        ]..sort((a, b) => a.$1.$2.compareTo(b.$1.$2))) ...[
          weighIn,
          if (dup) weighIn,
        ],
      ];
      expect(_trend.compute(shuffled), _trend.compute(weighIns));
    },
  );

  test('WB-004 weekly weigh-ins each move the trend halfway', () {
    expect(TrendWeightConfig.standard.alpha(7), 0.5);
    final trend = _trend.compute(_on([0, 7, 14, 21], [80, 82, 78, 80]));
    expect([for (final p in trend.points) p.trendKg], [80, 81, 79.5, 79.75]);
  });

  test('WB-004 scenario: weekly weigh-ins losing 0.5 kg/week with '
      'alternating ±0.8 kg noise give a rate within 0.15 of −0.5 after '
      '8 weeks and smaller week-to-week steps than the raw values', () {
    final trend = _trend.compute(
      _on(
        [for (var week = 0; week <= 8; week++) 7 * week],
        [
          for (var week = 0; week <= 8; week++)
            100 - 0.5 * week + (week.isEven ? 0.8 : -0.8),
        ],
      ),
    );
    expect(trend.asOf(dayN(56)).weeklyRateKg, closeTo(-0.5, 0.15));
    for (var i = 1; i < trend.points.length; i++) {
      final raw = (trend.points[i].rawKg - trend.points[i - 1].rawKg).abs();
      final smooth = (trend.points[i].trendKg - trend.points[i - 1].trendKg)
          .abs();
      expect(smooth, lessThan(raw), reason: 'week $i');
    }
  });

  test('WB-010 scenario: daily alternating ±1 kg noise around 80 kg keeps '
      'the trend within 80 ± 0.5 after 21 days', () {
    final trend = _trend.compute(
      _on(
        [for (var day = 0; day < 60; day++) day],
        [
          for (var day = 0; day < 60; day++)
            if (day.isEven) 81 else 79,
        ],
      ),
    );
    for (final point in trend.points.skip(21)) {
      expect(point.trendKg, closeTo(80, 0.5), reason: '${point.localDate}');
    }
  });

  test('WB-004 scenario: after a 3-week gap the next weigh-in moves the '
      'trend 75 %, then weekly ones 50 %', () {
    final trend = _trend.compute(_on([0, 7, 28, 35], [80, 80, 84, 84]));
    expect(TrendWeightConfig.standard.alpha(21), 0.75);
    expect(trend.trendOn(dayN(28)), 83);
    expect(trend.trendOn(dayN(35)), 83.5);
  });

  test('WB-010 scenario: a single +3 kg outlier among daily weigh-ins moves '
      'the trend 0.28 kg and decays back', () {
    final days = [for (var day = 0; day < 45; day++) day];
    final trend = _trend.compute(
      _on(days, [
        for (final day in days)
          if (day == 14) 83 else 80,
      ]),
    );
    expect(trend.trendOn(dayN(13)), 80);
    final moved = trend.trendOn(dayN(14))! - 80;
    expect(moved, closeTo(0.28, 0.005));
    var previous = moved;
    for (var day = 15; day < 45; day++) {
      final now = trend.trendOn(dayN(day))! - 80;
      expect(now, lessThan(previous));
      expect(now, greaterThan(0));
      previous = now;
    }
    expect(previous, lessThan(0.02));
  });

  test('WB-004 scenario: after a 90-day gap a weigh-in 6 kg higher moves '
      'the trend 4.5 kg (75 %); before it, the rate as of a date in the gap '
      'is hidden (stale)', () {
    final days = [for (var day = 0; day < 30; day++) day, 29 + 90];
    final trend = _trend.compute(
      _on(days, [
        for (final day in days)
          if (day < 30) 80 else 86,
      ]),
    );
    expect(trend.trendOn(dayN(119)), 84.5);
    final inGapFresh = trend.asOf(dayN(29 + 27));
    expect(inGapFresh.weeklyRateKg, 0);
    expect(inGapFresh.isStale, isFalse);
    for (final day in [29 + 28, 29 + 60, 29 + 89]) {
      final inGap = trend.asOf(dayN(day));
      expect(inGap.weeklyRateKg, isNull, reason: '$day');
      expect(inGap.isStale, isTrue);
      expect(inGap.trendKg, 80);
      expect(inGap.lastWeighIn!.localDate, dayN(29));
    }
    final after = trend.asOf(dayN(119));
    expect(after.isStale, isFalse);
    expect(after.weeklyRateKg, closeTo(4.5 / 4, 1e-9));
  });

  test('WB-011 weekly rate: the 28-day trend change ÷ 4; a shorter history '
      'uses its span; under 14 days or 1 day choice: no rate', () {
    // A full window: T(D − 28) is the step value on that date (day 12 holds
    // day 10's trend).
    final full = _trend.compute(_on([0, 10, 20, 30, 40], [90, 89, 88, 87, 86]));
    final expected = (full.trendOn(dayN(40))! - full.trendOn(dayN(10))!) / 4;
    expect(full.asOf(dayN(40)).weeklyRateKg, closeTo(expected, 1e-12));
    expect(full.asOf(dayN(45)).weeklyRateKg, full.asOf(dayN(40)).weeklyRateKg);
    // As of day 35, D is day 30 and the window starts on day 2.
    expect(
      full.asOf(dayN(35)).weeklyRateKg,
      closeTo((full.trendOn(dayN(30))! - 90) / 4, 1e-12),
    );

    // A shorter history: (T(D) − T₁) · 7 / s.
    final short = _trend.compute(_on([0, 7, 14], [90, 89, 88]));
    expect(short.trendOn(dayN(14)), 88.75);
    expect(short.asOf(dayN(14)).weeklyRateKg, closeTo(-0.625, 1e-12));
    expect(short.asOf(dayN(13)).weeklyRateKg, isNull, reason: 'span 7 days');

    final thirteen = _trend.compute(_on([0, 13], [90, 89]));
    expect(thirteen.asOf(dayN(20)).weeklyRateKg, isNull);

    final oneDay = _trend.compute([
      storedOn(dayN(0), 90),
      storedOn(dayN(0), 89, id: weighInB, hour: 20),
    ]);
    expect(oneDay.points, hasLength(1));
    expect(oneDay.asOf(dayN(20)).weeklyRateKg, isNull);
    expect(_trend.compute(const []).asOf(dayN(20)), WeightAsOf.none);
  });

  test('WB-011 lb inputs give the same trend and rate as the equivalent kg '
      'inputs (within storage rounding)', () {
    const pounds = [214.0, 213.4, 213.8, 212.6, 212.0, 211.2, 211.8];
    final days = [0, 3, 7, 10, 14, 21, 28];
    final inLb = _trend.compute([
      for (var i = 0; i < days.length; i++)
        storedOn(
          dayN(days[i]),
          pounds[i],
          id: weighInId(i),
          unit: MassUnit.pound,
        ),
    ]);
    final inKg = _trend.compute([
      for (var i = 0; i < days.length; i++)
        storedOn(
          dayN(days[i]),
          pounds[i] * MassUnit.pound.grams / 1000,
          id: weighInId(i),
          kg: pounds[i] * MassUnit.pound.grams / 1000,
        ),
    ]);
    for (var i = 0; i < days.length; i++) {
      expect(
        inLb.points[i].trendKg,
        closeTo(inKg.points[i].trendKg, StoragePrecision.round(0.005)),
      );
    }
    expect(
      inLb.asOf(dayN(28)).weeklyRateKg,
      closeTo(inKg.asOf(dayN(28)).weeklyRateKg!, 0.005),
    );
  });

  test('WB-022 trendOn(date) is the trend of the last day choice on or '
      'before the date, null before the first', () {
    final trend = _trend.compute(_on([5, 12, 26], [90, 92, 88]));
    expect(trend.trendOn(dayN(4)), isNull);
    expect(trend.pointOn(dayN(4)), isNull);
    expect(trend.trendOn(dayN(5)), 90);
    expect(trend.trendOn(dayN(11)), 90);
    expect(trend.trendOn(dayN(12)), 91);
    expect(trend.trendOn(dayN(25)), 91);
    expect(trend.trendOn(dayN(26)), 88.75);
    expect(trend.trendOn(dayN(400)), 88.75);
    expect(trend.pointOn(dayN(13))!.weighInId, weighInId(1));
    expect(trend.latest, trend.points.last);
    expect(trend.latest!.trendKg, 88.75);
    expect(trend.latest!.rawKg, 88);
    expect(_trend.compute(const []).latest, isNull);
    expect(_trend.compute(const []).trendOn(dayN(1)), isNull);
  });

  test('WB-012 asOf(date): no weekly rate when the last weigh-in day is 28 '
      'or more days before the date (outside the last 4 weeks)', () {
    final trend = _trend.compute(_on([0, 7, 14, 21], [90, 89.5, 89, 88.5]));
    final fresh = trend.asOf(dayN(21 + 27));
    expect(fresh.isStale, isFalse);
    expect(fresh.weeklyRateKg, isNotNull);
    expect(fresh.weeklyRateKg, trend.asOf(dayN(21)).weeklyRateKg);
    // Exactly 28 days: outside the 4-week window, as the honesty line counts.
    expect(trend.asOf(dayN(21 + 28)).isStale, isTrue);
    expect(trend.asOf(dayN(21 + 28)).weeklyRateKg, isNull);
    expect(
      WeighInCadence.of([
        for (final p in trend.points) p.localDate,
      ], dayN(49)).kind,
      CadenceKind.stale,
    );
    final stale = trend.asOf(dayN(21 + 29));
    expect(stale.isStale, isTrue);
    expect(stale.weeklyRateKg, isNull);
    expect(stale.trendKg, trend.trendOn(dayN(21)));
    expect(stale.lastWeighIn, trend.points.last);
    // A past date sees the trend as it was then.
    expect(trend.asOf(dayN(10)).lastWeighIn, trend.points[1]);
  });

  test('synced rows with non-positive, non-finite or absurd kg are '
      'skipped', () {
    final valid = storedOn(dayN(1), 90, id: weighInB, hour: 9);
    final trend = _trend.compute([
      storedOn(dayN(0), 90, id: weighInId(10), kg: 0),
      storedOn(dayN(0), 90, id: weighInId(11), kg: -90),
      storedOn(dayN(0), 90, id: weighInId(12), kg: double.nan),
      storedOn(dayN(0), 90, id: weighInId(13), kg: double.infinity),
      storedOn(dayN(0), 90, id: weighInId(14), kg: 1e306),
      // A broken preferred row hands the day to the valid one.
      storedOn(dayN(1), 90, kg: double.nan, preferred: true),
      valid,
    ]);
    expect(trend.points, [
      TrendPoint(
        localDate: dayN(1),
        weighInId: weighInB,
        rawKg: 90,
        trendKg: 90,
      ),
    ]);
  });

  test('one weigh-in: the trend equals it and there is no rate', () {
    final trend = _trend.compute([storedOn(dayN(3), 97.4)]);
    expect(trend.latest!.trendKg, 97.4);
    final asOf = trend.asOf(dayN(10));
    expect(asOf.trendKg, 97.4);
    expect(asOf.weeklyRateKg, isNull);
    expect(asOf.isStale, isFalse);
    expect(asOf.lastWeighIn!.weighInId, weighInA);
    expect(trend.asOf(dayN(2)), WeightAsOf.none);
  });

  test('TrendWeightConfig: the A14 constants, checked values, value '
      'equality', () {
    final config = TrendWeightConfig.standard;
    expect(config.halfLifeDays, 7);
    expect(config.maxAlpha, 0.75);
    expect(config.rateWindowDays, 28);
    expect(config.minRateSpanDays, 14);
    expect(config.staleAfterDays, 28);
    expect(config.alpha(1), closeTo(0.0943, 0.0001));
    expect(config.alpha(7), 0.5);
    expect(config.alpha(14), 0.75);
    expect(config.alpha(60), 0.75);
    expect(TrendWeight().config, config);

    expect(config, TrendWeightConfig());
    expect(config.hashCode, TrendWeightConfig().hashCode);
    for (final other in [
      TrendWeightConfig(halfLifeDays: 5),
      TrendWeightConfig(maxAlpha: 0.6),
      TrendWeightConfig(rateWindowDays: 21),
      TrendWeightConfig(minRateSpanDays: 7),
      TrendWeightConfig(staleAfterDays: 35),
    ]) {
      expect(config == other, isFalse, reason: '$other');
    }
    expect(
      config.toString(),
      'TrendWeightConfig(halfLife 7.0 d, maxAlpha 0.75, rate 28 d from 14 d, '
      'stale after 28 d)',
    );

    for (final build in <TrendWeightConfig Function()>[
      () => TrendWeightConfig(halfLifeDays: 0),
      () => TrendWeightConfig(halfLifeDays: double.nan),
      () => TrendWeightConfig(halfLifeDays: double.infinity),
      () => TrendWeightConfig(maxAlpha: 0),
      () => TrendWeightConfig(maxAlpha: 1.01),
      () => TrendWeightConfig(maxAlpha: double.nan),
      () => TrendWeightConfig(rateWindowDays: 0),
      () => TrendWeightConfig(minRateSpanDays: 0),
      () => TrendWeightConfig(staleAfterDays: 0),
    ]) {
      expect(build, throwsArgumentError);
    }

    // Another configuration changes the trend, nothing else.
    final slow = TrendWeight(TrendWeightConfig(halfLifeDays: 14));
    expect(slow.compute(_on([0, 14], [80, 82])).latest!.trendKg, 81);
  });

  test('trend values: equality and content-free toString', () {
    final weighIns = _on([0, 7], [90, 88]);
    final trend = _trend.compute(weighIns);
    expect(trend, _trend.compute(weighIns.reversed));
    expect(trend.hashCode, _trend.compute(weighIns).hashCode);
    expect(trend == _trend.compute(weighIns.take(1)), isFalse);
    expect(trend == _trend.compute(_on([0, 7], [90, 88.5])), isFalse);
    expect(
      trend == TrendWeight(TrendWeightConfig(maxAlpha: 0.5)).compute(weighIns),
      isFalse,
    );
    expect(trend.config, TrendWeightConfig.standard);
    expect(trend.points.clear, throwsUnsupportedError);

    final point = trend.points.last;
    final same = TrendPoint(
      localDate: dayN(7),
      weighInId: weighInId(1),
      rawKg: 88,
      trendKg: 89,
    );
    expect(point, same);
    expect(point.hashCode, same.hashCode);
    for (final other in [
      TrendPoint(
        localDate: dayN(8),
        weighInId: weighInId(1),
        rawKg: 88,
        trendKg: 89,
      ),
      TrendPoint(
        localDate: dayN(7),
        weighInId: weighInA,
        rawKg: 88,
        trendKg: 89,
      ),
      TrendPoint(
        localDate: dayN(7),
        weighInId: weighInId(1),
        rawKg: 87,
        trendKg: 89,
      ),
      TrendPoint(
        localDate: dayN(7),
        weighInId: weighInId(1),
        rawKg: 88,
        trendKg: 88,
      ),
    ]) {
      expect(point == other, isFalse);
    }

    final asOf = trend.asOf(dayN(7));
    expect(asOf, trend.asOf(dayN(7)));
    expect(asOf.hashCode, trend.asOf(dayN(7)).hashCode);
    expect(asOf == trend.asOf(dayN(0)), isFalse);
    expect(asOf == trend.asOf(dayN(100)), isFalse);
    expect(
      asOf ==
          WeightAsOf(
            trendKg: asOf.trendKg,
            weeklyRateKg: 1,
            lastWeighIn: asOf.lastWeighIn,
          ),
      isFalse,
    );

    final texts = [
      trend.toString(),
      point.toString(),
      asOf.toString(),
      trend.asOf(dayN(30)).toString(),
      WeightAsOf.none.toString(),
    ];
    for (final text in texts) {
      expect(text, isNot(contains('88')), reason: text);
      expect(text, isNot(contains('89')), reason: text);
      expect(text, isNot(contains('90')), reason: text);
    }
    expect(trend.toString(), 'WeightTrend(2 points)');
    expect(point.toString(), 'TrendPoint(2026-01-08, ${weighInId(1)})');
    expect(
      WeightAsOf.none.toString(),
      'WeightAsOf(null, rate: none, stale: false)',
    );
  });
}
