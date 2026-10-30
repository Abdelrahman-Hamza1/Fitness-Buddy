import 'package:fb_domain/fb_domain.dart';
import 'package:test/test.dart';

import '../helpers/body.dart';

/// Daily weigh-ins on [days] (offsets from [day0]) with [kg] of each offset.
WeightTrend _trend(Iterable<int> days, double Function(int day) kg) =>
    TrendWeight().compute([
      for (final day in days) storedOn(dayN(day), kg(day), id: weighInId(day)),
    ]);

GoalPhase _phase(
  GoalExpression expression, {
  int start = 0,
  int? end,
  GoalType type = GoalType.lose,
}) => GoalPhase(
  id: weighInId(900),
  name: 'Phase',
  start: dayN(start),
  end: end == null ? null : dayN(end),
  type: type,
  expression: expression,
);

void main() {
  test('IN-007 goal progress: loss and gain, clamped at 0 and 1, reached, '
      'no target or no trend, past phase ends at its end', () {
    // Loss: 90 → 80 kg, losing 0.1 kg a day for 60 days (trend lags).
    final losing = _trend(List.generate(61, (i) => i), (i) => 90 - 0.1 * i);
    final cut = GoalProgress.of(
      phase: _phase(GoalExpression.targetRate(80, 0.5)),
      trend: losing,
      today: dayN(60),
    );
    expect(cut.startKg, 90);
    expect(cut.startDate, dayN(0));
    expect(cut.targetKg, 80);
    final latest = losing.trendOn(dayN(60))!;
    expect(cut.latestKg, latest);
    expect(cut.fraction, closeTo((90 - latest) / 10, 1e-9));
    expect(cut.fraction, inInclusiveRange(0, 1));
    expect(cut.reached, isFalse);
    expect(cut.changeKg, closeTo(latest - 90, 1e-9));
    expect(cut.weeklyKg, closeTo((latest - 90) * 7 / 60, 1e-9));

    // Gain: 60 → 65 kg by a date.
    final gaining = _trend(List.generate(30, (i) => i), (i) => 60 + 0.05 * i);
    final bulk = GoalProgress.of(
      phase: _phase(
        GoalExpression.targetDate(65, dayN(200)),
        type: GoalType.gain,
      ),
      trend: gaining,
      today: dayN(29),
    );
    expect(bulk.fraction, closeTo((bulk.latestKg! - 60) / 5, 1e-9));
    expect(bulk.fraction, greaterThan(0));

    // Moving away from the target is 0, never negative (IN-020).
    final away = GoalProgress.of(
      phase: _phase(GoalExpression.targetRate(80, 0.5)),
      trend: _trend(List.generate(30, (i) => i), (i) => 90 + 0.1 * i),
      today: dayN(29),
    );
    expect(away.fraction, 0);
    expect(away.reached, isFalse);

    // Past the target: clamped at 1 and reached.
    final past = GoalProgress.of(
      phase: _phase(GoalExpression.targetRate(87, 0.5)),
      trend: losing,
      today: dayN(60),
    );
    expect(past.fraction, 1);
    expect(past.reached, isTrue);

    // A rate-only goal: no target, no fraction; change and rate still show.
    final weekly = GoalProgress.of(
      phase: _phase(GoalExpression.weekly(-0.5)),
      trend: losing,
      today: dayN(60),
    );
    expect(weekly.targetKg, isNull);
    expect(weekly.fraction, isNull);
    expect(weekly.reached, isFalse);
    expect(weekly.changeKg, isNotNull);

    // No weigh-ins: nothing but the target.
    final none = GoalProgress.of(
      phase: _phase(GoalExpression.targetRate(80, 0.5)),
      trend: _trend(const [], (_) => 0),
      today: dayN(60),
    );
    expect(none.startKg, isNull);
    expect(none.latestKg, isNull);
    expect(none.fraction, isNull);
    expect(none.targetKg, 80);

    // Start equal to the target: no fraction.
    final same = GoalProgress.of(
      phase: _phase(GoalExpression.targetRate(90, 0.5)),
      trend: _trend(List.generate(10, (i) => i), (_) => 90),
      today: dayN(9),
    );
    expect(same.fraction, isNull);

    // A past phase (days 0–30) is measured to its end, not to today.
    final ended = GoalProgress.of(
      phase: _phase(GoalExpression.targetRate(80, 0.5), end: 30),
      trend: losing,
      today: dayN(60),
    );
    expect(ended.latestKg, losing.trendOn(dayN(30)));
    expect(ended.fraction, lessThan(cut.fraction!));

    // A phase that starts after today has no progress yet.
    final future = GoalProgress.of(
      phase: _phase(GoalExpression.targetRate(80, 0.5), start: 90),
      trend: losing,
      today: dayN(60),
    );
    expect(future.startKg, isNull);
    expect(future.fraction, isNull);
  });
}
