import 'dart:math' as math;

import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/features/body/body.dart';
import 'package:fb_mobile/features/buddy/buddy.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:fb_mobile/features/targets/application/body_weight.dart';
import 'package:fb_mobile/features/targets/application/setup_input.dart';
import 'package:fb_mobile/features/targets/application/target_form_input.dart';
import 'package:fb_mobile/features/targets/application/targets_providers.dart';
import 'package:fb_mobile/features/targets/data/targets_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

// The screens' sheets take a row with its version.
export 'package:fb_mobile/features/targets/data/targets_repository.dart'
    show Versioned;

part 'targets_screens.g.dart';

// The view models of Me › Profile & goal and Me › Targets (A13c, D13, D14):
// read-only projections of the stored rows through the A12 engine. Every
// write stays a `TargetsActions` command; nothing here decides a limit.

/// Today in the device zone, read once per screen (the `SetupFlow` rule;
/// the targets feature doesn't import Today's date provider).
@riverpod
LocalDate targetsToday(Ref ref) =>
    EntryTime.now(ref.watch(clockProvider)).localDate;

/// What Me › Profile & goal shows (D13). Sensitive: content-free
/// [toString].
final class ProfileGoalView {
  /// The view on [today].
  new({
    required this.today,
    required this.profile,
    required this.units,
    required this.weightKg,
    required this.currentWeightKg,
    required this.active,
    required Iterable<Versioned<GoalPhaseRecord>> past,
    this.goalProblem,
    this.goalCalculation,
  }) : past = List.unmodifiable(past);

  /// Today.
  final LocalDate today;

  /// The stored profile with its row version.
  final Versioned<ProfileRecord> profile;

  /// The unit setting (weights in kg or lb, TG-002).
  final UnitSystem units;

  /// The weight the goal line is computed at: A14's trend, else the basis
  /// weight of the version in effect today (D8), else null.
  final double? weightKg;

  /// A14's latest trend weight, or null before the first weigh-in.
  final double? currentWeightKg;

  /// The phase in effect today, or null in a gap.
  final Versioned<GoalPhaseRecord>? active;

  /// Phases that ended before today, newest first (TG-012). Unmodifiable.
  final List<Versioned<GoalPhaseRecord>> past;

  /// Why the active goal can't be resolved any more (PA3), or null.
  final GoalProblem? goalProblem;

  /// The engine's calculation for the active goal (the TG-011 line), or
  /// null when it can't be computed.
  final TargetCalculation? goalCalculation;

  @override
  String toString() => 'ProfileGoalView(past: ${past.length})';
}

/// The live [ProfileGoalView], or null before setup.
@riverpod
Future<ProfileGoalView?> profileGoalView(Ref ref) async {
  final dataFuture = ref.watch(targetsDataProvider.future);
  final unitsFuture = ref.watch(unitSystemProvider.future);
  final currentFuture = ref.watch(currentWeightKgProvider.future);
  final today = ref.watch(targetsTodayProvider);
  final trendFuture = ref.watch(bodyWeightProvider(today).future);
  final data = await dataFuture;
  final units = await unitsFuture;
  final current = await currentFuture;
  final trend = await trendFuture;
  final profile = data.profile;
  if (profile == null) return null;
  final phases = GoalPhases(data.phases);
  final active = phases.activeOn(today);
  final version = TargetsTimeline.versionOn([
    for (final s in data.settings) s.value,
  ], today);
  final weightKg = usableWeight(trend) ?? version?.basisWeightKg;
  final past = [
    for (final record in phases.records)
      if (record.value.end case final end? when end.isBefore(today)) record,
  ]..sort((a, b) => b.value.start.compareTo(a.value.start));
  GoalProblem? problem;
  TargetCalculation? calculation;
  if (active != null && weightKg != null) {
    final goal = goalInputOf(active.value);
    problem = GoalProblem.of(goal, currentKg: weightKg, today: today);
    if (problem == null) {
      calculation = goalPreviewOf(
        profile.value,
        weightKg,
        goal,
        today,
      ).calculation;
    }
  }
  return ProfileGoalView(
    today: today,
    profile: profile,
    units: units,
    weightKg: weightKg,
    currentWeightKg: current,
    active: active,
    past: past,
    goalProblem: problem,
    goalCalculation: calculation,
  );
}

/// [kg] when it is a plausible body weight (TargetRules.input), else null.
double? usableWeight(double? kg) =>
    kg != null && TargetRules.input.weight(kg) ? kg : null;

/// The stored goal of [phase] as a command input.
GoalInput goalInputOf(GoalPhaseRecord phase) => GoalInput(
  type: phase.type,
  expression: phase.expression,
  weightInputUnit: phase.weightInputUnit,
);

/// The engine's numbers for [goal] with [profile] at [weightKg] on [today]
/// (A13b's [SetupPreview], so Me and setup show the same line); a
/// [SetupPreview.issue] when the goal can't be resolved (PA3).
SetupPreview goalPreviewOf(
  ProfileRecord profile,
  double weightKg,
  GoalInput goal,
  LocalDate today,
) => SetupPreview.of(
  SetupInput(
    sex: profile.sex,
    birthYear: profile.birthYear,
    height: Length.centimeters(profile.heightCm),
    heightInputUnit: profile.heightInputUnit,
    weightValue: roundHalfAwayFromZero(weightKg, 1),
    weightUnit: MassUnit.kilogram,
    activity: profile.activity,
    goal: goal,
    preferences: const SetupPreferences(
      unitSystem: UnitSystem.metric,
      weekStart: DayOfWeek.saturday,
      halal: true,
    ),
  ),
  today,
);

/// The stored goal of [phase] as the form's draft, in the unit it was typed
/// in (TD-017): "Edit goal" starts from what the user chose.
GoalDraft goalDraftOf(GoalPhaseRecord phase) {
  final unit = phase.weightInputUnit;
  String text(double kg, {int decimals = 2}) {
    final value = roundHalfAwayFromZero(
      Mass.kilograms(kg.abs()).inUnit(unit),
      decimals,
    );
    return value == value.truncateToDouble()
        ? value.toInt().toString()
        : value.toString();
  }

  final type = phase.type;
  return switch (phase.expression) {
    _ when type == GoalType.maintain => GoalDraft(type: type, unit: unit),
    WeeklyGoal(:final kgPerWeek) => GoalDraft(
      type: type,
      unit: unit,
      rate: text(kgPerWeek),
    ),
    MonthlyGoal(:final kg) => GoalDraft(
      type: type,
      kind: GoalExpressionKind.monthly,
      unit: unit,
      month: text(kg, decimals: 1),
    ),
    TargetDateGoal(:final targetKg, :final date) => GoalDraft(
      type: type,
      kind: GoalExpressionKind.targetDate,
      unit: unit,
      targetWeight: text(targetKg, decimals: 1),
      targetDate: date,
    ),
    TargetRateGoal(:final targetKg, :final kgPerWeek) => GoalDraft(
      type: type,
      kind: GoalExpressionKind.targetRate,
      unit: unit,
      targetWeight: text(targetKg, decimals: 1),
      pace: text(kgPerWeek),
    ),
  };
}

/// What Me › Targets shows (D14). Content-free [toString].
final class TargetsView {
  /// The view on [today].
  new({
    required this.today,
    required this.shown,
    required this.day,
    required this.profile,
    required this.units,
    required this.calendar,
    required this.explanation,
    required this.trendKg,
    this.adapted = false,
  });

  /// Today.
  final LocalDate today;

  /// The version in effect today at its row version: every command takes
  /// it, so an edit made elsewhere meanwhile is refused (`changed`).
  final VersionedId shown;

  /// Today's targets from the engine (D6).
  final DayTargets day;

  /// The stored profile.
  final ProfileRecord profile;

  /// The unit setting.
  final UnitSystem units;

  /// The week the budget runs over (week start setting).
  final WeekCalendar calendar;

  /// The explanation of the version in effect today (TG-021), or null.
  final TargetExplanation? explanation;

  /// A14's trend weight today, or null.
  final double? trendKg;

  /// Whether today's version is the one a weekly check-in wrote (A38 D4):
  /// the base was adjusted to the user's results, not the formula's.
  final bool adapted;

  /// The version in effect today.
  TargetSettingsRecord get version => day.version;

  /// An acknowledged fixed manual target below today's floor (PA7): mode,
  /// rebalancing and shifting are off.
  bool get forcedFixed =>
      version.manual &&
      version.acknowledged &&
      version.mode == TargetMode.fixed &&
      version.baseKcal < day.floorKcal;

  /// "Recalculate with your current weight" is offered (D5, D14): a
  /// generated version whose basis weight differs from the trend weight by
  /// at least 0.1 kg. Not for an [adapted] base: recalculating would throw
  /// away what the check-ins learned (A38 D4).
  bool get recalculateOffered {
    final trend = usableWeight(trendKg);
    return !version.manual &&
        !adapted &&
        trend != null &&
        (trend - version.basisWeightKg).abs() >= .05;
  }

  /// The base the plan uses today: the stored one, or the floor when it was
  /// raised (D6).
  double get effectiveBaseKcal => day.raisedToFloor
      ? math.max(version.baseKcal, day.floorKcal)
      : version.baseKcal;

  /// Each day's planned target this week with [weights] instead of the
  /// stored shifts and no rebalancing (the Higher-calorie days preview,
  /// TG-043), from the engine; empty in fixed mode.
  Map<LocalDate, double> plannedWith(Map<DayOfWeek, double> weights) {
    if (version.mode == TargetMode.fixed) return const {};
    try {
      return WeeklyBudget.calculate(
        baseKcal: effectiveBaseKcal,
        floorKcal: day.floorKcal,
        today: calendar.weekStartOf(today),
        weights: weights,
        rebalancing: false,
        calendar: calendar,
      ).planned;
    }
    // The engine's content-free signal for an impossible input.
    // ignore: avoid_catching_errors
    on ArgumentError {
      return const {};
    }
  }

  @override
  String toString() => 'TargetsView(${version.mode.name})';
}

/// The live [TargetsView], or null before setup (or when today's targets
/// can't be computed from the stored rows).
@riverpod
Future<TargetsView?> targetsView(Ref ref) async {
  final today = ref.watch(targetsTodayProvider);
  final dataFuture = ref.watch(targetsDataProvider.future);
  final dayFuture = ref.watch(dayTargetsProvider(today).future);
  final explanationFuture = ref.watch(targetsExplanationProvider(today).future);
  final unitsFuture = ref.watch(unitSystemProvider.future);
  final weekStartFuture = ref.watch(weekStartProvider.future);
  final trendFuture = ref.watch(bodyWeightProvider(today).future);
  final adaptedFuture = ref.watch(adaptedVersionsProvider.future);
  final data = await dataFuture;
  final day = await dayFuture;
  final explanation = await explanationFuture;
  final units = await unitsFuture;
  final weekStart = await weekStartFuture;
  final trend = await trendFuture;
  final profile = data.profile;
  if (day == null || profile == null) return null;
  final row = data.settings.where((s) => s.value.id == day.version.id);
  if (row.isEmpty) return null;
  return TargetsView(
    today: today,
    shown: VersionedId(day.version.id, row.first.version),
    day: day,
    profile: profile.value,
    units: units,
    calendar: WeekCalendar(weekStart: weekStart),
    explanation: explanation,
    trendKg: trend,
    adapted:
        !day.version.manual &&
        (await adaptedFuture).contains((day.version.id, day.version.revision)),
  );
}

/// The settings versions weekly check-ins wrote, as (ID, revision) (A38
/// D4): from the confirmed `targetChange` rows. Live.
@riverpod
Stream<Set<(String, int)>> adaptedVersions(Ref ref) => ref
    .watch(proposalRepositoryProvider)
    .watchKind(targetChangeKind)
    .map(
      (rows) => {
        for (final r in rows)
          if (r.status == ProposalStatus.confirmed)
            if (TargetChangeDraft.tryParse(r.draftJson) case TargetChangeDraft(
              :final appliedVersionId?,
              :final appliedRevision?,
            ))
              (appliedVersionId, appliedRevision),
      },
    );
