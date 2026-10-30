import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/progress/application/progress_period.dart';
import 'package:fb_mobile/features/progress/application/weight_chart_parts.dart';
import 'package:fb_mobile/features/targets/targets.dart';
import 'package:flutter_test/flutter_test.dart';

String _id(int n) =>
    '0199e3c2-5b1a-7000-8000-${n.toRadixString(16).padLeft(12, '0')}';

Versioned<GoalPhaseRecord> _phase(
  int n,
  LocalDate start,
  GoalExpression expression,
) => Versioned(
  GoalPhaseRecord(
    id: _id(n),
    revision: 1,
    start: start,
    type: GoalType.lose,
    expression: expression,
    weightInputUnit: MassUnit.kilogram,
  ),
  1,
);

void main() {
  test("IN-009 IN-004 the weight chart's goal line follows the selected "
      'phase', () {
    final today = LocalDate(2026, 10, 28);
    // A cut to 84 kg from March, then a cut to 78 kg from 10 August (the
    // first ends the day before, TG-012), then a rate-only phase planned
    // for December.
    final phases = GoalPhases([
      _phase(1, LocalDate(2026, 3, 1), GoalExpression.targetRate(84, .5)),
      _phase(
        2,
        LocalDate(2026, 8, 10),
        GoalExpression.targetDate(78, LocalDate(2027, 3, 1)),
      ),
      _phase(3, LocalDate(2026, 12, 1), GoalExpression.weekly(-.25)),
    ]);

    // Each phase period resolves its own goal and boundaries.
    expect(periodGoalKg(PhasePeriod(_id(1)), phases, today), 84);
    expect(periodGoalKg(PhasePeriod(_id(2)), phases, today), 78);
    expect(PhasePeriod(_id(1)).range(today, phases), (
      from: LocalDate(2026, 3, 1),
      end: LocalDate(2026, 8, 9),
    ));
    // Today's active phase would say 78 for every period; a past week and
    // month use the phase at their end.
    expect(periodGoalKg(WeekPeriod(LocalDate(2026, 6, 6)), phases, today), 84);
    expect(periodGoalKg(const MonthPeriod(2026, 7), phases, today), 84);
    // August ends in the second phase.
    expect(periodGoalKg(const MonthPeriod(2026, 8), phases, today), 78);
    // The current week ends after today: today's phase.
    expect(
      periodGoalKg(WeekPeriod(LocalDate(2026, 10, 24)), phases, today),
      78,
    );
    // Before any phase: no goal line.
    expect(periodGoalKg(const MonthPeriod(2026, 1), phases, today), isNull);
    // A rate-only phase has no goal weight.
    expect(
      periodGoalKg(PhasePeriod(_id(3)), phases, LocalDate(2026, 12, 20)),
      isNull,
    );
  });
}
