import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/body/body.dart';
import 'package:fb_mobile/features/progress/application/graph_window.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:fb_mobile/features/targets/targets.dart';
import 'package:fb_mobile/features/today/today.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'weight_graph_providers.g.dart';

/// The weight graph's range and pan position (A15 D5/PA4): session-only,
/// changed by the range chips and once per drag (on drag end).
typedef WeightGraphWindow = ({GraphRange range, DateTime? panStart});

/// Holds the [WeightGraphWindow]; survives leaving and returning.
@Riverpod(keepAlive: true)
class WeightGraphWindowController extends _$WeightGraphWindowController {
  @override
  WeightGraphWindow build() => (range: GraphRange.m3, panStart: null);

  /// Picks [range] and returns to today.
  void setRange(GraphRange range) => state = (range: range, panStart: null);

  /// Moves the window to start at [start] (a drag ended).
  void setPanStart(DateTime start) =>
      state = (range: state.range, panStart: start);

  /// Back to the window ending today.
  void reset() => state = (range: state.range, panStart: null);
}

/// Highlighted periods for every chart (WB-021): empty for now. **A41
/// supplies Ramadan periods here**, labelled "Ramadan" by the screen.
@riverpod
List<({LocalDate start, LocalDate end})> chartHighlightPeriods(Ref ref) =>
    const [];

/// Everything the weight graph draws, independent of the window (A15 PA4):
/// recomputed once per data change, never per drag.
final class WeightGraphModel {
  /// The model.
  const new({
    required this.today,
    required this.weighIns,
    required this.trend,
    required this.projection,
    required this.stats,
    required this.phases,
    required this.monthlyRate,
    required this.unit,
    this.goalKg,
  });

  /// Today (local).
  final LocalDate today;

  /// Live weigh-ins (readable), oldest first.
  final List<WeighIn> weighIns;

  /// The trend.
  final WeightTrend trend;

  /// The projection, or why there is none.
  final ProjectionOutcome projection;

  /// The summary numbers.
  final WeightStats stats;

  /// Goal phases with their display names resolved by the screen.
  final List<Versioned<GoalPhaseRecord>> phases;

  /// The rate behind this month's target, or why there is none.
  final MonthlyTargetRate monthlyRate;

  /// The active goal weight, or null.
  final double? goalKg;

  /// The display unit.
  final MassUnit unit;

  @override
  String toString() => 'WeightGraphModel(${weighIns.length})';
}

/// The [WeightGraphModel] from the weigh-ins, the trend, the goal phases and
/// the targets' TG-011 rate. Follows Today's local date
/// ([todayProvider]: refreshed after midnight and on resume). No automatic
/// retry: the screen shows the error with Try again (UX-052).
@Riverpod(retry: _noAutomaticRetry)
Future<WeightGraphModel> weightGraph(Ref ref) async {
  final today = await ref.watch(todayProvider.future);
  final weighInsFuture = ref.watch(weighInsProvider.future);
  final trendFuture = ref.watch(weightTrendProvider.future);
  final goalsFuture = ref.watch(goalHistoryProvider.future);
  final explanationFuture = ref.watch(targetsExplanationProvider(today).future);
  final unitsFuture = ref.watch(unitSystemProvider.future);
  final weighIns = chartOrdered(await weighInsFuture);
  final trend = await trendFuture;
  final goals = await goalsFuture;
  final explanation = await explanationFuture;
  final units = await unitsFuture;
  final active = goals.history.at(today);
  final goalKg = switch (active?.expression) {
    TargetDateGoal(:final targetKg) => targetKg,
    TargetRateGoal(:final targetKg) => targetKg,
    _ => null,
  };
  final monthlyRate = MonthlyTargetRate.of(explanation);
  return WeightGraphModel(
    today: today,
    weighIns: weighIns,
    trend: trend,
    projection: WeightProjection.of(trend: trend, today: today, goalKg: goalKg),
    stats: WeightStats.of(
      trend: trend,
      today: today,
      history: goals.history,
      monthTargetKgPerWeek: monthlyRate.kgPerWeek,
    ),
    phases: goals.records,
    monthlyRate: monthlyRate,
    goalKg: goalKg,
    unit: units.bodyMass,
  );
}

Duration? _noAutomaticRetry(int retryCount, Object error) => null;

/// The selected weigh-in's ID on the weight graph, or null.
@riverpod
class SelectedWeighIn extends _$SelectedWeighIn {
  @override
  String? build() => null;

  /// Selects [id] (null clears).
  // A method, not a setter: the screen passes it as a callback.
  // ignore: use_setters_to_change_properties
  void select(String? id) => state = id;
}

/// A chart point's naive wall-clock time for [date] (A15 PA7).
DateTime chartDay(LocalDate date) =>
    DateTime.utc(date.year, date.month, date.day);

/// The chart time of a weigh-in: its local day and clock time.
DateTime chartTimeOf(WeighIn weighIn) {
  final local = weighIn.time.localDateTime;
  return DateTime.utc(
    weighIn.localDate.year,
    weighIn.localDate.month,
    weighIn.localDate.day,
    local.hour,
    local.minute,
  );
}

/// The readable [weighIns] in chart order: by [chartTimeOf] (the local
/// wall clock the chart's x uses), then the instant, then the ID. The
/// repository orders by date and UTC instant, which differs from the wall
/// clock after a clock rollback or a time-zone change on the same day
/// (02:50 at +03:00 is earlier than 02:10 at +02:00); the chart's binary
/// search and hit-testing need x order (A15a review).
List<WeighIn> chartOrdered(Iterable<WeighIn> weighIns) {
  final keyed =
      [
        for (final w in weighIns)
          if (w.isReadable) (chartTimeOf(w), w),
      ]..sort((a, b) {
        final byX = a.$1.compareTo(b.$1);
        if (byX != 0) return byX;
        final byInstant = a.$2.time.occurredAtUtc.compareTo(
          b.$2.time.occurredAtUtc,
        );
        return byInstant != 0 ? byInstant : a.$2.id.compareTo(b.$2.id);
      });
  return [for (final (_, w) in keyed) w];
}

/// The DS periods of the goal phases overlapping the chart.
List<FbPeriod> phasePeriods(
  List<Versioned<GoalPhaseRecord>> phases,
  GoalHistory history,
  LocalDate until,
  String Function(GoalPhaseRecord record) label,
) {
  final records = {for (final r in phases) r.value.id: r.value};
  return [
    for (final (i, phase) in history.phases.indexed)
      FbPeriod(
        start: chartDay(phase.start),
        end: chartDay((phase.end ?? until).plusDays(1)),
        tone: i.isEven ? FbPeriodTone.phaseA : FbPeriodTone.phaseB,
        label: records[phase.id] == null ? null : label(records[phase.id]!),
      ),
  ];
}
