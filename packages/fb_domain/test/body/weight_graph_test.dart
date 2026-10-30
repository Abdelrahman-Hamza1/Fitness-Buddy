import 'dart:math' as math;

import 'package:fb_domain/fb_domain.dart';
import 'package:glados/glados.dart';

import '../helpers/body.dart';
import '../helpers/property.dart';

/// Weigh-ins on [days] (offsets from [day0]) with [kg] of each offset.
WeightTrend _trend(Iterable<int> days, double Function(int day) kg) =>
    TrendWeight().compute([
      for (final day in days) storedOn(dayN(day), kg(day), id: weighInId(day)),
    ]);

/// 60 daily weigh-ins losing 0.1 kg/day with ±0.3 kg alternating noise.
final WeightTrend _losing = _trend(
  List.generate(60, (i) => i),
  (i) => 90 - 0.1 * i + (i.isEven ? 0.3 : -0.3),
);

WeightProjection _shown(ProjectionOutcome outcome) {
  expect(outcome, isA<WeightProjection>());
  return outcome as WeightProjection;
}

GoalPhase _phase(LocalDate start) => GoalPhase(
  id: weighInId(999),
  name: 'Cut',
  start: start,
  type: GoalType.lose,
  expression: GoalExpression.weekly(-0.5),
);

void main() {
  group('projection', () {
    test('WB-021 the projection starts at the latest trend point and follows '
        'the weekly rate', () {
      final p = _shown(
        WeightProjection.of(trend: _losing, today: dayN(59), goalKg: 80),
      );
      final asOf = _losing.asOf(dayN(59));
      expect(p.anchorDate, dayN(59));
      expect(p.anchorKg, asOf.trendKg);
      expect(p.kgPerWeek, asOf.weeklyRateKg);
      final start = p.at(dayN(59));
      expect(start.centre, p.anchorKg);
      expect(start.lower, p.anchorKg);
      expect(start.upper, p.anchorKg);
      expect(p.at(dayN(66)).centre, closeTo(p.anchorKg + p.kgPerWeek, 1e-9));
    });

    test('WB-021 σ is the OLS slope standard error of the day choices in the '
        '56 days ending at the anchor, at least 0.1 kg/week', () {
      const config = ProjectionConfig();
      final points = _losing.points.where((p) => p.localDate.isAfter(dayN(3)));
      final xs = [
        for (final p in points) dayN(59).daysUntil(p.localDate) * -1.0,
      ];
      final ys = [for (final p in points) p.rawKg];
      final n = xs.length;
      final mx = xs.reduce((a, b) => a + b) / n;
      final my = ys.reduce((a, b) => a + b) / n;
      var sxx = 0.0;
      var sxy = 0.0;
      for (var i = 0; i < n; i++) {
        sxx += (xs[i] - mx) * (xs[i] - mx);
        sxy += (xs[i] - mx) * (ys[i] - my);
      }
      final b = sxy / sxx;
      var sse = 0.0;
      for (var i = 0; i < n; i++) {
        sse += math.pow(ys[i] - (my - b * mx) - b * xs[i], 2);
      }
      final expected = math.sqrt(sse / (n - 2) / sxx) * 7;
      expect(n, 56);
      expect(
        WeightProjection.slopeStandardError(_losing, dayN(59), config),
        closeTo(expected, 1e-9),
      );
      final p = _shown(
        WeightProjection.of(trend: _losing, today: dayN(59), goalKg: 80),
      );
      expect(p.sigmaKgPerWeek, math.max(expected, 0.1));
    });

    test('WB-021 the edges are centre ± 1.28·σ·t/7; the cone edges stop at '
        'the goal', () {
      final p = _shown(
        WeightProjection.of(trend: _losing, today: dayN(59), goalKg: 80),
      );
      final week = p.at(dayN(66));
      expect(week.upper - week.centre, closeTo(1.28 * p.sigmaKgPerWeek, 1e-9));
      expect(week.centre - week.lower, closeTo(1.28 * p.sigmaKgPerWeek, 1e-9));
      final far = p.at(dayN(59 + 700));
      expect(far.lower, 80);
      expect(far.centre, 80);
      expect(far.upper, 80);
    });

    test('WB-021 the cone is drawn until the slow edge reaches the goal or the '
        'horizon; the reach date is where the centre meets the goal', () {
      final p = _shown(
        WeightProjection.of(trend: _losing, today: dayN(59), goalKg: 80),
      );
      final reach = p.reachDate!;
      expect(p.at(reach).centre, 80);
      expect(p.at(reach.plusDays(-1)).centre, greaterThan(80));
      // The slow (upper) edge reaches the goal on drawUntil, not before.
      expect(p.at(p.drawUntil).upper, 80);
      expect(p.at(p.drawUntil.plusDays(-1)).upper, greaterThan(80));
      expect(p.drawUntil.isAfter(reach), isTrue);
    });

    test('WB-021 past 730 days a projection but no date', () {
      // About −0.1 kg/week, 20 kg to go: ~200 weeks.
      final slow = _trend(List.generate(60, (i) => i), (i) => 90 - i * 0.1 / 7);
      final p = _shown(
        WeightProjection.of(trend: slow, today: dayN(59), goalKg: 70),
      );
      expect(p.reachDate, isNull);
      expect(p.drawUntil, dayN(59 + 730));
      expect(p.toString(), isNot(contains('90')));
    });

    test('WB-021 a gain projection clamps at the goal from below', () {
      final gaining = _trend(List.generate(60, (i) => i), (i) => 70 + 0.1 * i);
      final p = _shown(
        WeightProjection.of(trend: gaining, today: dayN(59), goalKg: 78),
      );
      final far = p.at(dayN(59 + 400));
      expect(far.upper, 78);
      expect(far.lower, lessThanOrEqualTo(78));
    });

    group('WB-021 no projection', () {
      ProjectionAbsence? reason(ProjectionOutcome outcome) =>
          outcome is NoProjection ? outcome.reason : null;

      test('no goal weight', () {
        expect(
          reason(WeightProjection.of(trend: _losing, today: dayN(59))),
          ProjectionAbsence.noGoal,
        );
      });

      test('a stale trend or no weigh-ins', () {
        expect(
          reason(
            WeightProjection.of(trend: _losing, today: dayN(90), goalKg: 80),
          ),
          ProjectionAbsence.stale,
        );
        expect(
          reason(
            WeightProjection.of(
              trend: TrendWeight().compute(const []),
              today: dayN(1),
              goalKg: 80,
            ),
          ),
          ProjectionAbsence.stale,
        );
      });

      test('no rate', () {
        final short = _trend([0, 1, 2, 3, 4], (i) => 90 - i * 0.1);
        expect(
          reason(WeightProjection.of(trend: short, today: dayN(4), goalKg: 80)),
          ProjectionAbsence.noRate,
        );
      });

      test('under 0.05 kg/week', () {
        final flat = _trend(List.generate(60, (i) => i), (_) => 90);
        expect(
          reason(WeightProjection.of(trend: flat, today: dayN(59), goalKg: 80)),
          ProjectionAbsence.flat,
        );
      });

      test('moving away from the goal', () {
        expect(
          reason(
            WeightProjection.of(trend: _losing, today: dayN(59), goalKg: 95),
          ),
          ProjectionAbsence.awayFromGoal,
        );
      });

      test('goal reached', () {
        final kg = _losing.latest!.trendKg;
        expect(
          reason(
            WeightProjection.of(trend: _losing, today: dayN(59), goalKg: kg),
          ),
          ProjectionAbsence.reached,
        );
      });

      test('fewer than 4 day choices in 56 days', () {
        final sparse = _trend([0, 20, 40, 60, 80], (i) => 90 - i * 0.1);
        final outcome = WeightProjection.of(
          trend: sparse,
          today: dayN(80),
          goalKg: 70,
        );
        expect(reason(outcome), ProjectionAbsence.tooFewPoints);
        expect(outcome.toString(), 'NoProjection(tooFewPoints)');
      });

      test('4 day choices spanning under 14 days', () {
        final early = _trend([0, 30, 50, 52, 54, 56], (i) => 90 - i * 0.1);
        expect(
          WeightProjection.slopeStandardError(
            early,
            dayN(56),
            const ProjectionConfig(seWindowDays: 10),
          ),
          isNull,
        );
      });
    });

    Glados2(any.intInRange(-20, 21), any.intInRange(0, 10), propertyRuns).test(
      'WB-021 property: the cone contains the centre and its width never '
      'shrinks until the goal clamp',
      (rateTenths, noiseTenths) {
        final perDay = rateTenths / 70;
        final trend = _trend(
          List.generate(60, (i) => i),
          (i) => 90 + perDay * i + (i.isEven ? 1 : -1) * noiseTenths / 10,
        );
        final goal = perDay < 0 ? 80.0 : 100.0;
        final outcome = WeightProjection.of(
          trend: trend,
          today: dayN(59),
          goalKg: goal,
        );
        if (outcome is! WeightProjection) return;
        var width = 0.0;
        for (
          var d = 0;
          d <= outcome.anchorDate.daysUntil(outcome.drawUntil);
          d += 7
        ) {
          final e = outcome.at(outcome.anchorDate.plusDays(d));
          expect(e.lower, lessThanOrEqualTo(e.centre));
          expect(e.centre, lessThanOrEqualTo(e.upper));
          if (e.lower == goal || e.upper == goal) break;
          expect(e.upper - e.lower, greaterThanOrEqualTo(width - 1e-9));
          width = e.upper - e.lower;
        }
      },
    );
  });

  group('stats', () {
    test('WB-023 without an active phase the stats count from the first '
        'weigh-in and there is no monthly target', () {
      final stats = WeightStats.of(
        trend: _losing,
        today: dayN(59),
        monthTargetKgPerWeek: -0.5,
      );
      expect(stats.startDate, day0);
      expect(stats.startKg, _losing.points.first.trendKg);
      expect(stats.changeKg, _losing.latest!.trendKg - stats.startKg!);
      expect(stats.monthTargetKg, isNull);
      // day 59 = 1 March 2026: this month starts on the 1st, measured from
      // the trend on 28 February.
      expect(stats.monthFrom, LocalDate(2026, 3, 1));
      expect(
        stats.monthChangeKg,
        _losing.latest!.trendKg - _losing.trendOn(LocalDate(2026, 2, 28))!,
      );
    });

    test('WB-023 change since the phase start uses the trend at the start; a '
        'stale or missing start uses the first trend point after it', () {
      final gap = _trend([
        for (var i = 0; i <= 10; i++) i,
        for (var i = 60; i <= 90; i++) i,
      ], (i) => 90 - i * 0.05);
      final atStart = WeightStats.of(
        trend: gap,
        today: dayN(90),
        history: GoalHistory([_phase(dayN(5))]),
      );
      expect(atStart.startDate, dayN(5));
      final stale = WeightStats.of(
        trend: gap,
        today: dayN(90),
        history: GoalHistory([_phase(dayN(50))]),
      );
      expect(stale.startDate, dayN(60));
      expect(stale.startKg, gap.trendOn(dayN(60)));
      final missing = WeightStats.of(
        trend: gap,
        today: dayN(90),
        history: GoalHistory([_phase(dayN(-30))]),
      );
      expect(missing.startDate, day0);
      // A stale start whose next weigh-in is after today: no start at all.
      final future = WeightStats.of(
        trend: gap,
        today: dayN(45),
        history: GoalHistory([_phase(dayN(40))]),
      );
      expect(future.startKg, isNull);
      expect(future.changeKg, isNull);
      expect(future.averageWeeklyKg, isNull);
    });

    test('WB-023 TG-011 a phase starting this month is measured from its '
        'start against a pro-rated monthly target', () {
      final today = LocalDate(2026, 3, 20);
      final trend = _trend(List.generate(79, (i) => i), (i) => 90 - i * 0.05);
      final stats = WeightStats.of(
        trend: trend,
        today: today,
        history: GoalHistory([_phase(LocalDate(2026, 3, 11))]),
        monthTargetKgPerWeek: -0.5,
      );
      expect(stats.monthFrom, LocalDate(2026, 3, 11));
      expect(stats.monthChangeKg, stats.changeKg);
      // 11–31 March: 21 of 31 days of −0.5 kg/week over March.
      expect(stats.monthTargetKg, closeTo(-0.5 * 31 / 7 * 21 / 31, 1e-9));
    });

    test('WB-023 TG-011 a phase from an earlier month gets the whole month of '
        'the rate', () {
      final stats = WeightStats.of(
        trend: _losing,
        today: dayN(59),
        history: GoalHistory([_phase(day0)]),
        monthTargetKgPerWeek: -0.5,
      );
      expect(
        stats.monthTargetKg,
        closeTo(monthlyKgFromWeeklyRate(-0.5, dayN(59)), 1e-9),
      );
    });

    test('WB-023 the average weekly rate needs 14 days and is labelled from '
        'its start date', () {
      final short = _trend(List.generate(10, (i) => i), (i) => 90 - i * 0.1);
      final none = WeightStats.of(trend: short, today: dayN(9));
      expect(none.averageSince, isNull);
      expect(none.averageWeeklyKg, isNull);
      final stats = WeightStats.of(trend: _losing, today: dayN(59));
      expect(stats.averageSince, day0);
      expect(stats.averageWeeklyKg, closeTo(stats.changeKg! * 7 / 59, 1e-9));
    });

    test('WB-023 a month whose last weigh-in is long gone has no month '
        'change', () {
      final old = _trend([0, 1, 2], (i) => 90);
      final stats = WeightStats.of(trend: old, today: LocalDate(2026, 3, 20));
      expect(stats.monthChangeKg, isNull);
    });

    test('no weigh-ins give empty stats; toString carries no values', () {
      expect(
        WeightStats.of(trend: TrendWeight().compute(const []), today: day0),
        same(WeightStats.empty),
      );
      final text = WeightStats.of(trend: _losing, today: dayN(59)).toString();
      expect(text, isNot(contains('90')));
      expect(text, isNot(contains('8')));
    });
  });
}
