import 'package:fb_domain/src/diary/intake_totals.dart';
import 'package:fb_domain/src/insights/progress_series.dart';
import 'package:fb_domain/src/insights/query_plan.dart';
import 'package:fb_domain/src/math/rounding.dart';
import 'package:fb_domain/src/nutrition/nutrient_field.dart';
import 'package:fb_domain/src/time/local_date.dart';
import 'package:fb_domain/src/time/week_calendar.dart';
import 'package:fb_domain/src/workouts/exercise_type.dart';
import 'package:fb_domain/src/workouts/muscle.dart';
import 'package:fb_domain/src/workouts/workout_history.dart';
import 'package:fb_domain/src/workouts/workout_set.dart';

/// The unit a [QueryClaim] is in (canonical: kcal, g, kg, cm).
enum QueryUnit {
  /// Energy.
  kcal,

  /// Grams (nutrients).
  g,

  /// Kilograms (weight, loads, volume).
  kg,

  /// Centimetres (length measurements).
  cm,

  /// Percent (body fat).
  percent,

  /// A count.
  count,

  /// A date (the claim's [QueryClaim.date]; no value).
  date,
}

/// One number (or, for `last`, a date) the engine computed (AQ-09, AI-111):
/// the server labels it from metric, op and the plan's period and the
/// model refers to it by ID only. Content-free [toString].
final class QueryClaim {
  /// A claim.
  const new({
    required this.metric,
    required this.op,
    required this.unit,
    this.value,
    this.date,
    this.workoutId,
    this.exerciseRef,
    this.muscleGroup,
  });

  /// The metric.
  final QueryMetric metric;

  /// The operation.
  final QueryOp op;

  /// The value in [unit], rounded by code; `null` for a date claim.
  final double? value;

  /// The day it refers to (latest, max, min, last), or `null`.
  final LocalDate? date;

  /// The unit.
  final QueryUnit unit;

  /// For `last`: the session found.
  final String? workoutId;

  /// For `last` and PRs: the exercise.
  final String? exerciseRef;

  /// For `last`: the exercise's muscle group.
  final MuscleGroup? muscleGroup;

  @override
  bool operator ==(Object other) =>
      other is QueryClaim &&
      other.metric == metric &&
      other.op == op &&
      other.value == value &&
      other.date == date &&
      other.unit == unit &&
      other.workoutId == workoutId &&
      other.exerciseRef == exerciseRef &&
      other.muscleGroup == muscleGroup;

  @override
  int get hashCode => Object.hash(
    metric,
    op,
    value,
    date,
    unit,
    workoutId,
    exerciseRef,
    muscleGroup,
  );

  @override
  String toString() => 'QueryClaim(${metric.name}, ${op.name})';
}

/// The screens an answer can link to (AI-112).
enum QueryLinkScreen {
  /// A diary day ([QueryLink.date]).
  diary,

  /// The weight graph.
  weightGraph,

  /// The Progress tab.
  progress,

  /// An exercise page ([QueryLink.exerciseRef]).
  exercise,

  /// A logged session ([QueryLink.workoutId]).
  workout,
}

/// Where an answer's link goes (AI-112). Content-free [toString].
final class QueryLink {
  /// A link.
  const new(
    this.screen, {
    this.date,
    this.from,
    this.to,
    this.exerciseRef,
    this.workoutId,
  });

  /// The screen.
  final QueryLinkScreen screen;

  /// For [QueryLinkScreen.diary].
  final LocalDate? date;

  /// The period's first day, for charts.
  final LocalDate? from;

  /// The period's last day, for charts.
  final LocalDate? to;

  /// For [QueryLinkScreen.exercise].
  final String? exerciseRef;

  /// For [QueryLinkScreen.workout].
  final String? workoutId;

  /// The JSON form (kept with the reply on the phone).
  Map<String, Object?> toJson() => {
    'screen': screen.name,
    if (date != null) 'date': '$date',
    if (from != null) 'from': '$from',
    if (to != null) 'to': '$to',
    if (exerciseRef != null) 'exerciseRef': exerciseRef,
    if (workoutId != null) 'workoutId': workoutId,
  };

  /// The link of [json], or `null` when it isn't one.
  static QueryLink? fromJson(Object? json) {
    if (json is! Map<String, Object?>) return null;
    final screen = QueryLinkScreen.values
        .where((s) => s.name == json['screen'])
        .firstOrNull;
    if (screen == null) return null;
    LocalDate? date(String key) => switch (json[key]) {
      final String s => LocalDate.tryParse(s),
      _ => null,
    };
    String? text(String key) => switch (json[key]) {
      final String s when s.isNotEmpty && s.length <= 64 => s,
      _ => null,
    };
    final link = QueryLink(
      screen,
      date: date('date'),
      from: date('from'),
      to: date('to'),
      exerciseRef: text('exerciseRef'),
      workoutId: text('workoutId'),
    );
    return switch (screen) {
      QueryLinkScreen.diary when link.date == null => null,
      QueryLinkScreen.exercise when link.exerciseRef == null => null,
      QueryLinkScreen.workout when link.workoutId == null => null,
      _ => link,
    };
  }

  @override
  bool operator ==(Object other) =>
      other is QueryLink &&
      other.screen == screen &&
      other.date == date &&
      other.from == from &&
      other.to == to &&
      other.exerciseRef == exerciseRef &&
      other.workoutId == workoutId;

  @override
  int get hashCode =>
      Object.hash(screen, date, from, to, exerciseRef, workoutId);

  @override
  String toString() => 'QueryLink(${screen.name})';
}

/// What the engine answered: its claims (none when the data can't tell),
/// how many days the period covered and how many held data of the metric,
/// and the screen to open.
final class QueryAnswer {
  /// An answer.
  new({
    required List<QueryClaim> claims,
    required this.days,
    required this.loggedDays,
    this.link,
  }) : claims = List.unmodifiable(claims);

  /// The computed claims.
  final List<QueryClaim> claims;

  /// Days in the period (after the weekday filter), ≤ 400.
  final int days;

  /// Of [days], those with data of the metric (food, a weigh-in, a value,
  /// a session).
  final int loggedDays;

  /// The screen to open, or `null`.
  final QueryLink? link;

  @override
  String toString() =>
      'QueryAnswer(${claims.length} claims, $loggedDays/$days)';
}

/// A dated value (a day weight, a measurement in canonical units).
typedef QueryValue = ({LocalDate date, double value});

/// A session exercise as the engine reads it: its exercise, what it logs
/// and trains (null when the library no longer knows it) and its sets.
typedef QueryExercise = ({
  String ref,
  ExerciseType? type,
  Muscle? primary,
  List<SetValues> sets,
});

/// A logged session.
typedef QuerySession = ({
  String id,
  LocalDate date,
  List<QueryExercise> exercises,
});

/// The data a plan reads ([QueryEngine.needs]); what it doesn't need may
/// stay empty.
enum QueryInput {
  /// [QueryData.days].
  days,

  /// [QueryData.slotIntake].
  slotIntake,

  /// [QueryData.weights].
  weights,

  /// [QueryData.trendOn].
  trend,

  /// [QueryData.values].
  measurements,

  /// [QueryData.sessions].
  sessions,
}

double? _noTrend(LocalDate date) => null;

/// The local data behind one answer, already read for the plan's window
/// (sessions may reach back further: PR changes compare with earlier ones).
/// Holds user data: content-free [toString].
final class QueryData {
  /// The data.
  const new({
    this.days = const [],
    this.slotIntake,
    this.weights = const [],
    this.trendOn = _noTrend,
    this.values = const [],
    this.sessions = const [],
  });

  /// The window's days from the Progress series (G10).
  final List<ProgressDay> days;

  /// With a slot filter: that slot's intake per date (dates without an
  /// entry in it are absent).
  final Map<LocalDate, IntakeTotals>? slotIntake;

  /// Day weights.
  final List<QueryValue> weights;

  /// The trend weight on a date.
  final double? Function(LocalDate date) trendOn;

  /// The measurement type's values (cm, or percent for body fat).
  final List<QueryValue> values;

  /// Logged sessions.
  final List<QuerySession> sessions;

  @override
  String toString() => 'QueryData()';
}

/// The device's QueryEngine (A68, AQ-09, `06` §6.3): answers a question
/// about the user's data with numbers computed here, never by a model.
/// Pure: the caller resolves the window ([window]) and reads the data
/// ([needs]) first. A plan outside the grammar's valid combinations is
/// unsupported ([supports]).
abstract final class QueryEngine {
  /// The longest period a plan may cover (`06` §4.2).
  static const int maxDays = 400;

  /// Whether [plan] is a valid combination (`06` §6.3) with what its
  /// metric needs, and filters that apply to it.
  static bool supports(QueryPlan plan) {
    final m = plan.metric;
    final f = plan.filters;
    final combination = switch (plan.op) {
      QueryOp.remaining =>
        m.isNutrient && plan.period.kind == QueryPeriodKind.today,
      QueryOp.total || QueryOp.average || QueryOp.max || QueryOp.min =>
        m.isNutrient || m == QueryMetric.sets || m == QueryMetric.volume,
      QueryOp.latest || QueryOp.change =>
        m == QueryMetric.weight ||
            m == QueryMetric.weightTrend ||
            m == QueryMetric.measurement ||
            m == QueryMetric.exercisePr,
      QueryOp.count =>
        m == QueryMetric.workouts ||
            m == QueryMetric.sets ||
            m == QueryMetric.weighIns ||
            m == QueryMetric.loggedDays,
      QueryOp.last => m == QueryMetric.exerciseLastDate,
    };
    if (!combination || !_periodValid(plan.period)) return false;
    final exercise = f.exerciseRef != null && f.exerciseRef!.trim().isNotEmpty;
    final muscles = f.muscleGroup == null ? null : musclesNamed(f.muscleGroup!);
    if (f.muscleGroup != null && muscles == null) return false;
    if (f.weekdays.any((d) => d < 1 || d > 7)) return false;
    // The trend is one smoothed line: a weekday filter has no meaning.
    if (m == QueryMetric.weightTrend && f.weekdays.isNotEmpty) return false;
    if (f.slot != null && (!m.isNutrient || plan.op == QueryOp.remaining)) {
      return false;
    }
    final trained = {
      QueryMetric.workouts,
      QueryMetric.sets,
      QueryMetric.volume,
      QueryMetric.exerciseLastDate,
      QueryMetric.exercisePr,
    };
    if ((exercise || muscles != null) && !trained.contains(m)) return false;
    return switch (m) {
      QueryMetric.measurement =>
        plan.measurementType != null && plan.measurementType!.isNotEmpty,
      QueryMetric.exercisePr => exercise && muscles == null,
      QueryMetric.exerciseLastDate => exercise || muscles != null,
      _ => true,
    };
  }

  static bool _periodValid(QueryPeriod p) => switch (p.kind) {
    QueryPeriodKind.lastNDays =>
      p.days != null && p.days! >= 1 && p.days! <= maxDays,
    QueryPeriodKind.since => switch (p.since) {
      null => false,
      QuerySince.date => p.from != null,
      _ => true,
    },
    QueryPeriodKind.range => p.from != null && p.to != null,
    _ => true,
  };

  /// The dates [period] covers on [today] with weeks starting per
  /// [calendar] (D-070), ending no later than today; `null` when it
  /// starts after its end, covers more than [maxDays] days, or names an
  /// event that isn't known ([ramadanStart], [phaseStart]).
  static QueryWindow? window(
    QueryPeriod period, {
    required LocalDate today,
    WeekCalendar calendar = const WeekCalendar(),
    LocalDate? ramadanStart,
    LocalDate? phaseStart,
  }) {
    if (!_periodValid(period)) return null;
    final month = LocalDate(today.year, today.month, 1);
    final (LocalDate from, LocalDate to) = switch (period.kind) {
      QueryPeriodKind.today => (today, today),
      QueryPeriodKind.yesterday => (today.plusDays(-1), today.plusDays(-1)),
      QueryPeriodKind.thisWeek => (calendar.weekStartOf(today), today),
      QueryPeriodKind.lastWeek => (
        calendar.weekStartOf(today).plusDays(-7),
        calendar.weekStartOf(today).plusDays(-1),
      ),
      QueryPeriodKind.thisMonth => (month, today),
      QueryPeriodKind.lastMonth => (
        month.month == 1
            ? LocalDate(month.year - 1, 12, 1)
            : LocalDate(month.year, month.month - 1, 1),
        month.plusDays(-1),
      ),
      QueryPeriodKind.lastNDays => (today.plusDays(-(period.days! - 1)), today),
      QueryPeriodKind.since => switch (period.since!) {
        QuerySince.ramadanStart => (ramadanStart ?? today.plusDays(1), today),
        QuerySince.phaseStart => (phaseStart ?? today.plusDays(1), today),
        QuerySince.date => (period.from!, today),
      },
      QueryPeriodKind.range => (
        period.from!,
        period.to!.isAfter(today) ? today : period.to!,
      ),
    };
    if (from.isAfter(to) || from.daysUntil(to) + 1 > maxDays) return null;
    return (from: from, to: to);
  }

  /// What [plan] reads.
  static Set<QueryInput> needs(QueryPlan plan) => switch (plan.metric) {
    QueryMetric.kcal ||
    QueryMetric.protein ||
    QueryMetric.carbs ||
    QueryMetric.fat ||
    QueryMetric.fiber => {
      QueryInput.days,
      if (plan.filters.slot != null) QueryInput.slotIntake,
    },
    QueryMetric.loggedDays => {QueryInput.days},
    QueryMetric.weight || QueryMetric.weighIns => {QueryInput.weights},
    QueryMetric.weightTrend => {QueryInput.trend},
    QueryMetric.measurement => {QueryInput.measurements},
    QueryMetric.workouts ||
    QueryMetric.sets ||
    QueryMetric.volume ||
    QueryMetric.exerciseLastDate ||
    QueryMetric.exercisePr => {QueryInput.sessions},
  };

  /// The answer to [plan] over [window] from [data]; `null` when the plan
  /// isn't supported. No data for a claim → no claim.
  static QueryAnswer? answer(
    QueryPlan plan, {
    required QueryWindow window,
    required QueryData data,
  }) {
    if (!supports(plan)) return null;
    final f = plan.filters;
    bool inWindow(LocalDate d) =>
        !d.isBefore(window.from) &&
        !d.isAfter(window.to) &&
        (f.weekdays.isEmpty || f.weekdays.contains(d.weekday.isoNumber));
    var days = 0;
    for (var d = window.from; !d.isAfter(window.to); d = d.plusDays(1)) {
      if (inWindow(d)) days++;
    }
    final m = plan.metric;
    switch (m) {
      case QueryMetric.weight || QueryMetric.weighIns:
        final weights = _sorted(data.weights.where((v) => inWindow(v.date)));
        final claims = m == QueryMetric.weighIns
            ? [_count(plan, weights.length)]
            : _latestOrChange(plan, weights, QueryUnit.kg);
        return QueryAnswer(
          claims: claims,
          days: days,
          loggedDays: weights.map((v) => v.date).toSet().length,
          link: QueryLink(
            QueryLinkScreen.weightGraph,
            from: window.from,
            to: window.to,
          ),
        );
      case QueryMetric.weightTrend:
        return QueryAnswer(
          claims: _trend(plan, window, data.trendOn),
          days: days,
          loggedDays: 0,
          link: QueryLink(
            QueryLinkScreen.weightGraph,
            from: window.from,
            to: window.to,
          ),
        );
      case QueryMetric.measurement:
        final values = _sorted(data.values.where((v) => inWindow(v.date)));
        final unit = plan.measurementType == 'bodyFat'
            ? QueryUnit.percent
            : QueryUnit.cm;
        return QueryAnswer(
          claims: _latestOrChange(plan, values, unit),
          days: days,
          loggedDays: values.map((v) => v.date).toSet().length,
        );
      case QueryMetric.workouts ||
          QueryMetric.sets ||
          QueryMetric.volume ||
          QueryMetric.exerciseLastDate ||
          QueryMetric.exercisePr:
        return _training(plan, window, data, inWindow, days);
      case QueryMetric.kcal ||
          QueryMetric.protein ||
          QueryMetric.carbs ||
          QueryMetric.fat ||
          QueryMetric.fiber ||
          QueryMetric.loggedDays:
        return _nutrients(plan, window, data, inWindow, days);
    }
  }

  static QueryAnswer _nutrients(
    QueryPlan plan,
    QueryWindow window,
    QueryData data,
    bool Function(LocalDate) inWindow,
    int days,
  ) {
    final slot = plan.filters.slot != null;
    final rows = [
      for (final d in data.days)
        if (inWindow(d.date)) d,
    ];
    IntakeTotals? intakeOf(ProgressDay d) {
      if (slot) return data.slotIntake?[d.date];
      return d.hasIntake ? d.intake : null;
    }

    final withIntake = [
      for (final d in rows)
        if (intakeOf(d) != null) d,
    ];
    final single = window.from == window.to;
    final link = single
        ? QueryLink(QueryLinkScreen.diary, date: window.from)
        : QueryLink(QueryLinkScreen.progress, from: window.from, to: window.to);
    final complete = plan.filters.completeDaysOnly;
    final claims = <QueryClaim>[];
    if (plan.metric == QueryMetric.loggedDays) {
      final logged = complete ?? false
          ? withIntake.where((d) => d.counted).length
          : withIntake.length;
      claims.add(_count(plan, logged));
    } else {
      final field = plan.metric.field!;
      final unit = field == NutrientField.kcal ? QueryUnit.kcal : QueryUnit.g;
      if (plan.op == QueryOp.remaining) {
        final today = rows.where((d) => d.date == window.to).firstOrNull;
        final target = today == null ? null : _targetOf(today, field);
        final intake = today?.intake ?? IntakeTotals.empty;
        // Exact only: a macro some entry doesn't know gives no claim (the
        // coverage shows why).
        if (target != null && intake.coverage(field) == NutrientCoverage.full) {
          claims.add(
            _claim(plan, unit, target - (intake.sum.valueOf(field) ?? 0)),
          );
        }
      } else if (plan.op == QueryOp.total) {
        final counted = [
          for (final d in withIntake)
            if (!(complete ?? false) || d.counted) intakeOf(d)!,
        ];
        if (counted.isNotEmpty &&
            counted.every((i) => i.coverage(field) == NutrientCoverage.full)) {
          claims.add(
            _claim(
              plan,
              unit,
              counted.fold<double>(
                0,
                (sum, i) => sum + (i.sum.valueOf(field) ?? 0),
              ),
            ),
          );
        }
      } else {
        final values = [
          for (final d in withIntake)
            if (!(complete ?? true) || d.counted)
              if (intakeOf(d)! case final i
                  when field == NutrientField.kcal ||
                      i.coverage(field) == NutrientCoverage.full)
                (date: d.date, value: i.sum.valueOf(field) ?? 0),
        ];
        if (_aggregate(plan, values, unit) case final claim?) {
          claims.add(claim);
        }
      }
    }
    // A macro some entries don't know gives no exact claim; the coverage
    // counts only the days where it is fully known, so `loggedDays` < the
    // days with food says why (A68 review, no contract change).
    final field = plan.metric.field;
    final logged = field == null || field == NutrientField.kcal
        ? withIntake.length
        : withIntake
              .where(
                (d) => intakeOf(d)!.coverage(field) == NutrientCoverage.full,
              )
              .length;
    return QueryAnswer(
      claims: claims,
      days: days,
      loggedDays: logged,
      link: link,
    );
  }

  static double? _targetOf(ProgressDay day, NutrientField field) =>
      switch (field) {
        NutrientField.kcal => day.targetKcal,
        NutrientField.protein => day.targetMacros?.proteinGrams,
        NutrientField.carbs => day.targetMacros?.carbsGrams,
        NutrientField.fat => day.targetMacros?.fatGrams,
        NutrientField.fiber => day.targetMacros?.fiberGrams,
        _ => null,
      };

  static List<QueryClaim> _trend(
    QueryPlan plan,
    QueryWindow window,
    double? Function(LocalDate) trendOn,
  ) {
    final end = trendOn(window.to);
    if (end == null) return const [];
    if (plan.op == QueryOp.latest) {
      return [_claim(plan, QueryUnit.kg, end, date: window.to)];
    }
    // The change runs from the day before the window, as the weekly
    // summary's (A39a), else from its first day.
    final before = trendOn(window.from.plusDays(-1)) ?? trendOn(window.from);
    return before == null
        ? const []
        : [_claim(plan, QueryUnit.kg, end - before, date: window.to)];
  }

  static List<QueryClaim> _latestOrChange(
    QueryPlan plan,
    List<QueryValue> values,
    QueryUnit unit,
  ) {
    if (values.isEmpty) return const [];
    final last = values.last;
    if (plan.op == QueryOp.latest) {
      return [_claim(plan, unit, last.value, date: last.date)];
    }
    final first = values.first;
    return first.date == last.date
        ? const []
        : [_claim(plan, unit, last.value - first.value, date: last.date)];
  }

  static QueryAnswer _training(
    QueryPlan plan,
    QueryWindow window,
    QueryData data,
    bool Function(LocalDate) inWindow,
    int days,
  ) {
    final f = plan.filters;
    final ref = f.exerciseRef?.trim();
    final muscles = f.muscleGroup == null ? null : musclesNamed(f.muscleGroup!);
    bool matches(QueryExercise e) =>
        (ref == null || ref.isEmpty || e.ref == ref) &&
        (muscles == null || muscles.contains(e.primary));
    final sessions = [
      for (final s in data.sessions)
        if (inWindow(s.date)) s,
    ]..sort(_bySession);
    final matched = [
      for (final s in sessions)
        if (s.exercises.where(matches).toList() case final list
            when list.isNotEmpty)
          (session: s, exercises: list),
    ];
    final exerciseLink = ref == null || ref.isEmpty
        ? null
        : QueryLink(QueryLinkScreen.exercise, exerciseRef: ref);
    final claims = <QueryClaim>[];
    var link = exerciseLink;
    final m = plan.metric;
    if (m == QueryMetric.workouts) {
      claims.add(_count(plan, matched.length));
    } else if (m == QueryMetric.sets) {
      final perSession = [
        for (final (:session, :exercises) in matched)
          (
            date: session.date,
            value: exercises
                .fold<int>(0, (n, e) => n + e.sets.length)
                .toDouble(),
          ),
      ];
      if (plan.op == QueryOp.count || plan.op == QueryOp.total) {
        claims.add(
          _count(plan, perSession.fold<int>(0, (n, v) => n + v.value.round())),
        );
      } else if (_aggregate(plan, perSession, QueryUnit.count)
          case final claim?) {
        claims.add(claim);
      }
    } else if (m == QueryMetric.volume) {
      final perSession = [
        for (final (:session, :exercises) in matched)
          if (_volume(exercises) case final v when v > 0)
            (date: session.date, value: v),
      ];
      if (plan.op == QueryOp.total) {
        if (perSession.isNotEmpty) {
          claims.add(
            _claim(
              plan,
              QueryUnit.kg,
              perSession.fold<double>(0, (n, v) => n + v.value),
            ),
          );
        }
      } else if (_aggregate(plan, perSession, QueryUnit.kg) case final claim?) {
        claims.add(claim);
      }
    } else if (m == QueryMetric.exerciseLastDate) {
      if (matched.lastOrNull case (:final session, :final exercises)?) {
        final e = exercises.first;
        claims.add(
          QueryClaim(
            metric: plan.metric,
            op: plan.op,
            unit: QueryUnit.date,
            date: session.date,
            workoutId: session.id,
            exerciseRef: e.ref,
            muscleGroup: e.primary?.group,
          ),
        );
        link = QueryLink(QueryLinkScreen.workout, workoutId: session.id);
      }
    } else {
      // The heaviest weight in the window; the change is
      // over the best before it.
      final best = _heaviest(sessions, matches);
      if (best != null) {
        if (plan.op == QueryOp.latest) {
          claims.add(_claim(plan, QueryUnit.kg, best.value, date: best.date));
        } else {
          final earlier = [
            for (final s in data.sessions)
              if (s.date.isBefore(window.from)) s,
          ];
          final before = _heaviest(earlier, matches);
          if (before != null) {
            claims.add(
              _claim(
                plan,
                QueryUnit.kg,
                best.value - before.value,
                date: best.date,
              ),
            );
          }
        }
      }
    }
    return QueryAnswer(
      claims: claims,
      days: days,
      loggedDays: matched.map((m) => m.session.date).toSet().length,
      link: link,
    );
  }

  static int _bySession(QuerySession a, QuerySession b) {
    final byDate = a.date.compareTo(b.date);
    return byDate != 0 ? byDate : a.id.compareTo(b.id);
  }

  /// Σ kg × reps of the weight × reps sets (an unknown exercise's loaded
  /// sets count too).
  static double _volume(List<QueryExercise> exercises) {
    var sum = 0.0;
    for (final e in exercises) {
      if (e.type != null && e.type != ExerciseType.weightReps) continue;
      for (final set in e.sets) {
        final kg = set.kg;
        final reps = set.reps;
        if (kg != null && kg.isFinite && kg > 0 && reps != null && reps > 0) {
          sum += kg * reps;
        }
      }
    }
    return sum;
  }

  /// The heaviest record weight over [sessions]' matching exercises, with
  /// its date (the first session that reached it).
  static QueryValue? _heaviest(
    List<QuerySession> sessions,
    bool Function(QueryExercise) matches,
  ) {
    QueryValue? best;
    for (final s in [...sessions]..sort(_bySession)) {
      for (final e in s.exercises.where(matches)) {
        for (final set in e.sets) {
          final lifted = liftedSetOf(e.type ?? ExerciseType.weightReps, set);
          if (lifted == null || lifted.kg <= 0) continue;
          if (best == null || lifted.kg > best.value) {
            best = (date: s.date, value: lifted.kg);
          }
        }
      }
    }
    return best;
  }

  /// The average ([QueryOp.average]) or the highest or lowest value with
  /// its date ([QueryOp.max], [QueryOp.min]) of [values], or `null`
  /// without one.
  static QueryClaim? _aggregate(
    QueryPlan plan,
    List<QueryValue> values,
    QueryUnit unit,
  ) {
    if (values.isEmpty) return null;
    if (plan.op == QueryOp.average) {
      return _claim(
        plan,
        unit,
        values.fold<double>(0, (n, v) => n + v.value) / values.length,
      );
    }
    final max = plan.op == QueryOp.max;
    var pick = values.first;
    for (final v in values.skip(1)) {
      if (max ? v.value > pick.value : v.value < pick.value) pick = v;
    }
    return _claim(plan, unit, pick.value, date: pick.date);
  }

  static List<QueryValue> _sorted(Iterable<QueryValue> values) =>
      values.toList()..sort((a, b) => a.date.compareTo(b.date));

  static QueryClaim _count(QueryPlan plan, int n) =>
      _claim(plan, QueryUnit.count, n.toDouble());

  static QueryClaim _claim(
    QueryPlan plan,
    QueryUnit unit,
    double value, {
    LocalDate? date,
  }) {
    final decimals = switch (unit) {
      QueryUnit.kcal || QueryUnit.count => 0,
      _ => 1,
    };
    final rounded = roundHalfAwayFromZero(value, decimals);
    return QueryClaim(
      metric: plan.metric,
      op: plan.op,
      unit: unit,
      // No "-0".
      value: rounded == 0 ? 0 : rounded,
      date: date,
    );
  }
}
