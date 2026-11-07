import 'package:fb_domain/src/nutrition/nutrient_field.dart';
import 'package:fb_domain/src/time/local_date.dart';
import 'package:fb_domain/src/workouts/muscle.dart';

/// What a question about the user's data measures (`06` §6.3, frozen in
/// B25's handoff): the QueryPlan grammar's metrics.
enum QueryMetric {
  /// Energy eaten.
  kcal(NutrientField.kcal),

  /// Protein eaten.
  protein(NutrientField.protein),

  /// Carbohydrate eaten.
  carbs(NutrientField.carbs),

  /// Fat eaten.
  fat(NutrientField.fat),

  /// Fiber eaten.
  fiber(NutrientField.fiber),

  /// Day weights (each day's weigh-in).
  weight(null),

  /// The smoothed trend weight.
  weightTrend(null),

  /// A body measurement (its type in [QueryPlan.measurementType]).
  measurement(null),

  /// Workout sessions.
  workouts(null),

  /// Logged sets.
  sets(null),

  /// Training volume (kg × reps).
  volume(null),

  /// The last day an exercise or muscle group was trained.
  exerciseLastDate(null),

  /// An exercise's heaviest weight.
  exercisePr(null),

  /// Days with a weigh-in.
  weighIns(null),

  /// Days with logged food.
  loggedDays(null);

  new(this.field);

  /// The nutrient, for the five nutrient metrics; `null` otherwise.
  final NutrientField? field;

  /// Whether it is one of the five nutrients.
  bool get isNutrient => field != null;
}

/// What a QueryPlan computes over its metric.
enum QueryOp {
  /// The sum over the period.
  total,

  /// The mean per day (nutrients) or per session (sets, volume).
  average,

  /// Today's target minus today's intake.
  remaining,

  /// The latest value in the period.
  latest,

  /// The change over the period.
  change,

  /// How many.
  count,

  /// The highest day or session.
  max,

  /// The lowest day or session.
  min,

  /// The last date (exerciseLastDate only).
  last,
}

/// How a QueryPlan names its period.
enum QueryPeriodKind {
  /// Today.
  today,

  /// Yesterday.
  yesterday,

  /// The current week (D-070 week start) up to today.
  thisWeek,

  /// The previous whole week.
  lastWeek,

  /// The current calendar month up to today.
  thisMonth,

  /// The previous whole calendar month.
  lastMonth,

  /// The last [QueryPeriod.days] days, today included.
  lastNDays,

  /// From an event ([QueryPeriod.since]) to today.
  since,

  /// From [QueryPeriod.from] to [QueryPeriod.to].
  range,
}

/// The event a `since` period starts from.
enum QuerySince {
  /// The latest Ramadan's first day.
  ramadanStart,

  /// The current goal phase's first day.
  phaseStart,

  /// The date in [QueryPeriod.from].
  date,
}

/// A QueryPlan's period, as the model wrote it (members a kind doesn't use
/// are ignored).
final class QueryPeriod {
  /// A period of [kind].
  const new(this.kind, {this.days, this.since, this.from, this.to});

  /// Its kind.
  final QueryPeriodKind kind;

  /// With [QueryPeriodKind.lastNDays]: 1–400.
  final int? days;

  /// With [QueryPeriodKind.since].
  final QuerySince? since;

  /// With [QueryPeriodKind.range], or `since` [QuerySince.date].
  final LocalDate? from;

  /// With [QueryPeriodKind.range].
  final LocalDate? to;

  @override
  String toString() => 'QueryPeriod(${kind.name})';
}

/// A QueryPlan's filters (all optional).
final class QueryFilters {
  /// The filters.
  const new({
    this.slot,
    this.exerciseRef,
    this.muscleGroup,
    this.completeDaysOnly,
    this.weekdays = const {},
  });

  /// A meal slot (its ID or name), for the nutrients.
  final String? slot;

  /// An exercise (library ID or custom exercise ID).
  final String? exerciseRef;

  /// A muscle group or muscle ("legs", "chest", "quadriceps").
  final String? muscleGroup;

  /// Whether only complete days count; `null` is the default (true for
  /// averages, max and min; false for totals and counts).
  final bool? completeDaysOnly;

  /// ISO weekdays (1 Monday – 7 Sunday); empty is every day.
  final Set<int> weekdays;

  @override
  String toString() => 'QueryFilters()';
}

/// One question about the user's data in the closed QueryPlan grammar
/// (`06` §6.3): a metric, an operation, a period and filters. Content-free
/// [toString] (a slot name is user content).
final class QueryPlan {
  /// A plan.
  const new({
    required this.metric,
    required this.op,
    required this.period,
    this.measurementType,
    this.filters = const QueryFilters(),
  });

  /// What is measured.
  final QueryMetric metric;

  /// With [QueryMetric.measurement]: a built-in kind code or a custom type
  /// ID.
  final String? measurementType;

  /// What is computed.
  final QueryOp op;

  /// Over which days.
  final QueryPeriod period;

  /// Narrowing.
  final QueryFilters filters;

  @override
  String toString() => 'QueryPlan(${metric.name}, ${op.name}, $period)';
}

/// The inclusive dates a plan's period covers, never after today.
typedef QueryWindow = ({LocalDate from, LocalDate to});

/// The muscles a `muscleGroup` filter names (A68 D2): a [MuscleGroup]
/// ("legs"), a [Muscle] code ("quadriceps", "upper_back"), "arms", or a
/// common singular or short form; `null` for anything else.
Set<Muscle>? musclesNamed(String name) {
  final key = name.trim().toLowerCase().replaceAll(RegExp('[ -]+'), '_');
  final word = _muscleAliases[key] ?? key;
  if (word == 'arms') {
    return {Muscle.biceps, Muscle.triceps, Muscle.forearms};
  }
  for (final group in MuscleGroup.values) {
    if (group.name == word) {
      return {
        for (final m in Muscle.values)
          if (m.group == group) m,
      };
    }
  }
  for (final m in Muscle.values) {
    if (m.code == word) return {m};
  }
  return null;
}

const Map<String, String> _muscleAliases = {
  'leg': 'legs',
  'arm': 'arms',
  'shoulder': 'shoulders',
  'delts': 'shoulders',
  'bicep': 'biceps',
  'tricep': 'triceps',
  'forearm': 'forearms',
  'quads': 'quadriceps',
  'quad': 'quadriceps',
  'hamstring': 'hamstrings',
  'glute': 'glutes',
  'calf': 'calves',
  'lats': 'upper_back',
  'trapezius': 'traps',
  'pecs': 'chest',
  'abdominals': 'abs',
};
