import 'dart:convert' show jsonDecode, jsonEncode;
import 'dart:math' as math;

import 'package:fb_domain/src/ids/uuid_v7.dart';
import 'package:fb_domain/src/targets/adaptive_expenditure.dart';
import 'package:fb_domain/src/targets/goals.dart';
import 'package:fb_domain/src/targets/target_calculator.dart';
import 'package:fb_domain/src/targets/target_profile.dart';
import 'package:fb_domain/src/targets/target_records.dart';
import 'package:fb_domain/src/targets/targets_timeline.dart';
import 'package:fb_domain/src/time/local_date.dart';

/// The `proposals.kind` of a weekly check-in (AI-056, A38 D3).
const targetChangeKind = 'targetChange';

/// The `proposals.kind` of an answered incomplete-day suggestion (DY-004).
const dayIncompleteKind = 'dayIncomplete';

/// The engine JSON version of both kinds' drafts.
const adaptiveDraftCodecVersion = 1;

/// Why a week's check-in proposes nothing (A38 D2).
enum CheckInSkip {
  /// Not enough data yet (TG-031).
  notReady,

  /// No profile or no targets version in effect.
  noTargets,

  /// The goal can't be resolved: the user updates it first.
  goalNeedsUpdate,

  /// An acknowledged manual target below the floor: never touched.
  belowFloor,

  /// The recommendation is within 50 kcal/day of the current target, or
  /// the floor leaves nothing to change (TG-034).
  withinThreshold,
}

/// Why an automatic check-in waits for the user (A38 review round 2).
enum CheckInHold {
  /// Some days' logged intake looks like an error (unconfirmed).
  anomaly,

  /// The estimate's confidence is low.
  lowConfidence,
}

/// What a week's check-in found: a change to propose, or why not.
/// Content-free [toString].
final class CheckInDecision {
  const new _({
    this.skip,
    this.currentKcal,
    this.recommendedKcal,
    this.proposedKcal,
    this.floorKcal,
  });

  /// Why nothing is proposed, or null with a proposal.
  final CheckInSkip? skip;

  /// Today's base as the plan uses it (raised to the floor).
  final double? currentKcal;

  /// The uncapped recommendation (floored, SF-011 capped).
  final double? recommendedKcal;

  /// The proposed base: within ±150 of [currentKcal], never below
  /// [floorKcal]; null when skipped.
  final double? proposedKcal;

  /// Today's SF-010 floor.
  final double? floorKcal;

  /// Whether a change is proposed.
  bool get proposes => skip == null;

  @override
  String toString() => 'CheckInDecision(${skip?.name ?? 'propose'})';
}

/// The weekly check-in rule (TG-034, TG-035, TG-036, SF-010; A38 D2).
abstract final class AdaptiveCheckIn {
  /// A proposed base is a multiple of this many kcal (rounded toward the
  /// current base), unless the floor applies.
  static const double stepKcal = 10;

  /// The proposal from [current] (≥ [floor]) toward [recommended]: the
  /// difference clamped to ±[TargetDefaults.checkInMaxChangeKcal], rounded
  /// toward [current] to a multiple of [stepKcal], never below [floor].
  /// Null when the difference is within
  /// [TargetDefaults.checkInThresholdKcal] or nothing is left to change.
  static double? propose({
    required double current,
    required double recommended,
    required double floor,
    TargetDefaults defaults = const TargetDefaults(),
  }) {
    if (current < floor) return null;
    final diff = recommended - current;
    if (diff.abs() <= defaults.checkInThresholdKcal) return null;
    final cap = defaults.checkInMaxChangeKcal;
    final target = current + diff.clamp(-cap, cap);
    // A round number, rounded toward the current base so the step never
    // grows past the cap.
    final rounded = diff < 0
        ? (target / stepKcal).ceil() * stepKcal
        : (target / stepKcal).floor() * stepKcal;
    final proposed = math.max(rounded, floor);
    if ((proposed - current).abs() < 1) return null;
    return proposed;
  }

  /// The check-in on [today] for the expenditure estimate [expenditureKcal]
  /// (`ExpenditureEstimate.kcal`; null: not ready) against the
  /// [settings] version in effect today, [profile], [goals] and the body
  /// weight [weightKg] (the trend, else the version's basis weight).
  static CheckInDecision decide({
    required LocalDate today,
    required double? expenditureKcal,
    required Iterable<TargetSettingsRecord> settings,
    required ProfileRecord? profile,
    required Iterable<GoalPhaseRecord> goals,
    required double? weightKg,
    TargetDefaults defaults = const TargetDefaults(),
  }) {
    final version = TargetsTimeline.versionOn(settings, today);
    if (profile == null || version == null) {
      return const CheckInDecision._(skip: CheckInSkip.noTargets);
    }
    if (expenditureKcal == null) {
      return const CheckInDecision._(skip: CheckInSkip.notReady);
    }
    final weight = weightKg ?? version.basisWeightKg;
    final phase = TargetsTimeline.phaseOn(goals, today);
    final ResolvedGoal? goal;
    try {
      goal = phase == null
          ? ResolvedGoal.resolve(
              type: GoalType.maintain,
              expression: GoalExpression.weekly(0),
              currentKg: weight,
              date: today,
            )
          : TargetsTimeline.resolve(phase, weightKg: weight, date: today);
    }
    // The engine's content-free signal for impossible input (PA3).
    // ignore: avoid_catching_errors
    on ArgumentError {
      return const CheckInDecision._(skip: CheckInSkip.noTargets);
    }
    if (goal == null) {
      return const CheckInDecision._(skip: CheckInSkip.goalNeedsUpdate);
    }
    final TargetCalculation calc;
    try {
      calc = TargetCalculator.calculate(
        profile: profile.toProfile(weight),
        goal: goal,
        date: today,
        expenditureKcal: expenditureKcal,
        defaults: defaults,
      );
    }
    // The engine's content-free signal for impossible input (PA3).
    // ignore: avoid_catching_errors
    on ArgumentError {
      return const CheckInDecision._(skip: CheckInSkip.noTargets);
    }
    final floor = calc.floorKcal;
    final current = version.toPlan(floor).baseKcal;
    if (current < floor) {
      return CheckInDecision._(
        skip: CheckInSkip.belowFloor,
        currentKcal: current,
        floorKcal: floor,
      );
    }
    final proposed = propose(
      current: current,
      recommended: calc.kcal,
      floor: floor,
      defaults: defaults,
    );
    return CheckInDecision._(
      skip: proposed == null ? CheckInSkip.withinThreshold : null,
      currentKcal: current,
      recommendedKcal: calc.kcal,
      proposedKcal: proposed,
      floorKcal: floor,
    );
  }
}

/// A weekly check-in proposal's draft (`targetChange`, A38 D3). Holds user
/// data: content-free [toString].
final class TargetChangeDraft {
  /// The draft.
  new({
    required this.weekStart,
    required this.versionId,
    required this.versionRevision,
    required this.fromKcal,
    required this.toKcal,
    required this.recommendedKcal,
    required this.expenditureKcal,
    required this.confidence,
    this.fromManual = false,
    this.fromAcknowledged = false,
    this.automatic = false,
    this.seen = false,
    this.appliedVersionId,
    this.appliedRevision,
    this.hold,
    List<LocalDate> anomalyDates = const [],
  }) : anomalyDates = List.unmodifiable(anomalyDates);

  /// Decodes [json], or null when it isn't a valid draft.
  static TargetChangeDraft? tryParse(String json) {
    try {
      final map = jsonDecode(json);
      if (map is! Map<String, Object?>) return null;
      final week = map['weekStart'];
      final id = map['versionId'];
      final revision = map['versionRevision'];
      final confidence = map['confidence'];
      double? number(String key) {
        final v = map[key];
        return v is num && v.isFinite && v > 0 ? v.toDouble() : null;
      }

      final from = number('fromKcal');
      final to = number('toKcal');
      final recommended = number('recommendedKcal');
      final expenditure = number('expenditureKcal');
      final manual = map['fromManual'];
      final acknowledged = map['fromAcknowledged'];
      final automatic = map['automatic'] ?? false;
      final seen = map['seen'] ?? false;
      final appliedId = map['appliedVersionId'];
      final appliedRevision = map['appliedRevision'];
      final holdCode = map['hold'];
      final hold = CheckInHold.values
          .where((h) => h.name == holdCode)
          .firstOrNull;
      final anomalyList = map['anomalyDates'] ?? const <Object?>[];
      final anomalies = anomalyList is List<Object?>
          ? [
              for (final d in anomalyList)
                if (d is String) LocalDate.tryParse(d),
            ]
          : null;
      if (week is! String ||
          id is! String ||
          !isUuidV7(id) ||
          revision is! int ||
          revision < 1 ||
          confidence is! String ||
          from == null ||
          to == null ||
          recommended == null ||
          expenditure == null ||
          manual is! bool ||
          acknowledged is! bool ||
          automatic is! bool ||
          seen is! bool ||
          (appliedId != null &&
              (appliedId is! String || !isUuidV7(appliedId))) ||
          (appliedRevision != null &&
              (appliedRevision is! int || appliedRevision < 1)) ||
          (holdCode != null && hold == null) ||
          anomalies == null ||
          anomalies.contains(null)) {
        return null;
      }
      final level = ExpenditureConfidence.values
          .where((c) => c.name == confidence)
          .firstOrNull;
      if (level == null) return null;
      return TargetChangeDraft(
        weekStart: LocalDate.parse(week),
        versionId: id,
        versionRevision: revision,
        fromKcal: from,
        toKcal: to,
        recommendedKcal: recommended,
        expenditureKcal: expenditure,
        confidence: level,
        fromManual: manual,
        fromAcknowledged: acknowledged,
        automatic: automatic,
        seen: seen,
        appliedVersionId: appliedId as String?,
        appliedRevision: appliedRevision as int?,
        hold: hold,
        anomalyDates: [for (final d in anomalies) d!],
      );
    } on FormatException {
      return null;
    }
  }

  /// The first day of the check-in's week.
  final LocalDate weekStart;

  /// The settings version it was made against.
  final String versionId;

  /// That version's domain revision then.
  final int versionRevision;

  /// The base then (raised to the floor).
  final double fromKcal;

  /// The proposed (or, once resolved, the applied) base.
  final double toKcal;

  /// The uncapped recommendation.
  final double recommendedKcal;

  /// The expenditure estimate behind it.
  final double expenditureKcal;

  /// Its confidence.
  final ExpenditureConfidence confidence;

  /// Whether the base then was the user's own (Change back restores it).
  final bool fromManual;

  /// Whether that own target was acknowledged below the floor.
  final bool fromAcknowledged;

  /// Whether it was applied automatically (the "ask" setting off).
  final bool automatic;

  /// Whether the user dismissed the "Targets updated" note.
  final bool seen;

  /// Once applied: the settings version it wrote (Targets reads "Adjusted
  /// to your results" while that version is in effect).
  final String? appliedVersionId;

  /// That version's domain revision.
  final int? appliedRevision;

  /// Why the automatic setting didn't apply it, or null.
  final CheckInHold? hold;

  /// The unconfirmed anomaly days behind the estimate, oldest first (the
  /// card names them). Unmodifiable.
  final List<LocalDate> anomalyDates;

  /// A copy with the given fields replaced.
  TargetChangeDraft copyWith({
    double? toKcal,
    bool? automatic,
    bool? seen,
    String? appliedVersionId,
    int? appliedRevision,
    CheckInHold? hold,
  }) => TargetChangeDraft(
    weekStart: weekStart,
    versionId: versionId,
    versionRevision: versionRevision,
    fromKcal: fromKcal,
    toKcal: toKcal ?? this.toKcal,
    recommendedKcal: recommendedKcal,
    expenditureKcal: expenditureKcal,
    confidence: confidence,
    fromManual: fromManual,
    fromAcknowledged: fromAcknowledged,
    automatic: automatic ?? this.automatic,
    seen: seen ?? this.seen,
    appliedVersionId: appliedVersionId ?? this.appliedVersionId,
    appliedRevision: appliedRevision ?? this.appliedRevision,
  );

  /// The draft JSON.
  String toJson() => jsonEncode({
    'weekStart': '$weekStart',
    'versionId': versionId,
    'versionRevision': versionRevision,
    'fromKcal': fromKcal,
    'toKcal': toKcal,
    'recommendedKcal': recommendedKcal,
    'expenditureKcal': expenditureKcal,
    'confidence': confidence.name,
    'fromManual': fromManual,
    'fromAcknowledged': fromAcknowledged,
    'automatic': automatic,
    'seen': seen,
    'appliedVersionId': ?appliedVersionId,
    'appliedRevision': ?appliedRevision,
    'hold': ?hold?.name,
    if (anomalyDates.isNotEmpty)
      'anomalyDates': [for (final d in anomalyDates) '$d'],
  });

  @override
  bool operator ==(Object other) =>
      other is TargetChangeDraft && other.toJson() == toJson();

  @override
  int get hashCode => toJson().hashCode;

  @override
  String toString() => 'TargetChangeDraft($weekStart)';
}

/// An incomplete-day suggestion's draft (`dayIncomplete`, DY-004).
abstract final class DayIncompleteDraft {
  /// The draft JSON for [date].
  static String toJson(LocalDate date) => jsonEncode({'date': '$date'});

  /// The date in [json], or null.
  static LocalDate? dateOf(String json) {
    try {
      final map = jsonDecode(json);
      final date = map is Map<String, Object?> ? map['date'] : null;
      return date is String ? LocalDate.parse(date) : null;
    } on FormatException {
      return null;
    }
  }
}
