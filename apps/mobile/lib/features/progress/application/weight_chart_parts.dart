import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/body/body.dart';
import 'package:fb_mobile/features/progress/application/progress_period.dart';
import 'package:fb_mobile/features/progress/application/weight_graph_providers.dart';
import 'package:fb_mobile/features/targets/targets.dart';

// The weight chart's building blocks, shared by the full graph (A15a) and
// the Progress tab's compact chart (A16 D8), so both draw the same series.

/// The weigh-ins as faint, selectable dots keyed by ID, in [unit].
FbSeries weighInSeries(
  List<WeighIn> weighIns,
  MassUnit unit, {
  String? semanticLabel,
  bool selectable = true,
}) => FbSeries(
  style: FbSeriesStyle.points,
  tone: FbSeriesTone.muted,
  selectable: selectable,
  semanticLabel: semanticLabel,
  points: [
    for (final w in weighIns)
      FbPoint(chartTimeOf(w), weightIn(w.kg, unit), key: w.id),
  ],
);

/// The trend as the main line, in [unit].
FbSeries trendSeries(
  WeightTrend trend,
  MassUnit unit, {
  String? semanticLabel,
}) => FbSeries(
  style: FbSeriesStyle.line,
  semanticLabel: semanticLabel,
  points: [
    for (final p in trend.points)
      FbPoint(chartDay(p.localDate), weightIn(p.trendKg, unit)),
  ],
);

/// The target weight of [expression]: target-date and target-rate goals
/// have one; rate-only goals (weekly, monthly) don't.
double? goalKgOf(GoalExpression? expression) => switch (expression) {
  TargetDateGoal(:final targetKg) ||
  TargetRateGoal(:final targetKg) => targetKg,
  _ => null,
};

/// The phase whose goal a chart of [period] shows (A16 PA4): the selected
/// phase for a phase period; for a week or a month the phase in effect on
/// the period's last shown day (its end, or today for the current one).
/// Null in a gap or without phases.
GoalPhase? periodPhase(
  ProgressPeriod period,
  GoalPhases phases,
  LocalDate today,
) {
  if (period is PhasePeriod) {
    return phases.history.phases
        .where((p) => p.id == period.phaseId)
        .firstOrNull;
  }
  final end = period.range(today, phases).end;
  return phases.history.at(end.isAfter(today) ? today : end);
}

/// The goal weight a chart of [period] draws (A16 PA4), from
/// [periodPhase]'s stored expression, not from today's active phase.
double? periodGoalKg(
  ProgressPeriod period,
  GoalPhases phases,
  LocalDate today,
) {
  final phase = periodPhase(period, phases, today);
  return phase == null ? null : goalKgOf(phase.expression);
}
