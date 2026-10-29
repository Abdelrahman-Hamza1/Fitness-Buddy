import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/core/changes/change_providers.dart';
import 'package:fb_mobile/core/ids/id_generator.dart';
import 'package:fb_mobile/core/settings/setting_key.dart';
import 'package:fb_mobile/core/settings/settings_store.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/core/undo/undo_stack.dart';
import 'package:fb_mobile/features/body/body.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:fb_mobile/features/targets/application/setup_input.dart';
import 'package:fb_mobile/features/targets/data/targets_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'targets_actions.g.dart';

/// The profile fields an edit changes; null fields stay as stored.
/// Sensitive: [toString] shows no values.
final class ProfilePatch {
  /// Changes the given fields.
  const new({
    this.sex,
    this.birthYear,
    this.heightCm,
    this.heightInputUnit,
    this.activity,
  });

  /// New formula sex.
  final FormulaSex? sex;

  /// New birth year.
  final int? birthYear;

  /// New height, cm.
  final double? heightCm;

  /// How the new height was typed.
  final HeightInputUnit? heightInputUnit;

  /// New activity category.
  final ActivityLevel? activity;

  /// [record] with this patch applied.
  ProfileRecord applyTo(ProfileRecord record) => record.copyWith(
    sex: sex,
    birthYear: birthYear,
    heightCm: heightCm,
    heightInputUnit: heightInputUnit,
    activity: activity,
  );

  @override
  String toString() => 'ProfilePatch';
}

/// Every targets write (A13 §3.3, D5, D10, D11, D13): one change set
/// through the single writer per command, one undo entry, typed outcomes
/// with content-free `toString` (PA14). One command runs at a time; a
/// second one meanwhile gets [TargetsPending].
///
/// Revise commands take the row the screen showed (a [VersionedId], or the
/// profile's row version); a row that changed since is refused with
/// [TargetsFailure.changed], a missing one with [TargetsFailure.removed].
/// Settings changes follow the D5 revision rule
/// ([TargetSettingsRevision.next]); profile, goal and phase saves recompute
/// a generated base in the same change set (D5, PA1) and never block on an
/// unresolvable goal (PA3).
final class TargetsActions {
  /// Dependencies are explicit for deterministic tests.
  new({
    required this.apply,
    required this.undoStack,
    required this.ids,
    required this.clock,
    required this.read,
    required this.settings,
    required this.bodyWeightKg,
    this.defaults = const TargetDefaults(),
  });

  /// The single writer port (`ChangeSetApplier.apply`).
  final Future<ApplyResult> Function(ChangeSet) apply;

  /// Session undo history.
  final UndoStack undoStack;

  /// New phase and version IDs (UUIDv7).
  final IdGenerator ids;

  /// Today, in the device zone.
  final Clock clock;

  /// A fresh snapshot of the targets tables.
  final Future<TargetsData> Function() read;

  /// The stored preferences (setup writes only changed ones).
  final SettingsStore settings;

  /// The trend weight on or before a date, or null (D8 seam); null falls
  /// back to the current version's basis weight.
  final Future<double?> Function(LocalDate date) bodyWeightKg;

  /// The engine defaults.
  final TargetDefaults defaults;

  bool _busy = false;

  /// Saves setup (D10) as one change set: the profile, the first weigh-in
  /// (A14's `CreateWeighIn`: the typed value and unit, measured now; WB-001,
  /// TD-090), the first goal phase (from today), the first target settings
  /// version (effective today, generated from the typed weight, which is its
  /// basis weight; weekly, rebalancing on, default macros) and the
  /// preferences that differ from the stored ones. One undo entry removes
  /// them all. Refused with [TargetsFailure.alreadySetUp] when a profile
  /// (readable or not) or a version exists.
  Future<TargetsOutcome> completeSetup(SetupInput input) =>
      _run(TargetsChangeKind.targetsSet, (today) => _setup(input, today));

  /// Saves profile fields against the shown row [expectedVersion];
  /// recomputes a generated base in the same change set (D5).
  Future<TargetsOutcome> saveProfile(ProfilePatch patch, int expectedVersion) =>
      _run(TargetsChangeKind.profileUpdated, (today) async {
        final data = await read();
        final shown = data.profile;
        if (shown == null) return _refuse(TargetsFailure.removed);
        if (shown.version != expectedVersion) {
          return _refuse(TargetsFailure.changed);
        }
        final updated = patch.applyTo(shown.value);
        if (updated == shown.value) return const _Write([]);
        if (TargetRules.input
            .profile(updated, today: today, before: shown.value)
            .isNotEmpty) {
          return _refuse(TargetsFailure.invalid);
        }
        final recompute = await _recompute(
          data,
          today,
          profile: updated,
          goals: _values(data.phases),
        );
        return _Write(
          [
            PutProfile(updated, expectedVersion: expectedVersion),
            ...recompute.ops,
          ],
          recomputedKcal: recompute.kcal,
          warnings: recompute.warnings,
        );
      });

  /// Replaces the goal of the shown phase (bumping its domain revision);
  /// recomputes a generated base when it is today's phase (D5).
  Future<TargetsOutcome> saveGoal(GoalInput goal, VersionedId shown) =>
      _run(TargetsChangeKind.goalUpdated, (today) async {
        final data = await read();
        final stored = _phase(data, shown.id);
        if (stored == null) return _refuse(TargetsFailure.removed);
        if (stored.version != shown.expectedVersion) {
          return _refuse(TargetsFailure.changed);
        }
        final before = stored.value;
        final edited = before.copyWith(
          type: goal.type,
          expression: goal.expression,
          weightInputUnit: goal.weightInputUnit,
        );
        if (edited == before) return const _Write([]);
        final updated = edited.copyWith(revision: before.revision + 1);
        if (TargetRules.input
            .goalPhase(updated, today: today, before: before)
            .isNotEmpty) {
          return _refuse(TargetsFailure.invalid);
        }
        final goals = [
          for (final g in _values(data.phases))
            if (g.id == updated.id) updated else g,
        ];
        final active = TargetsTimeline.phaseOn(goals, today)?.id == updated.id;
        final profile = data.profile?.value;
        final current = _current(data, today);
        if (active && profile != null && current != null) {
          final weight = await _weight(today, current.value);
          if (weight != null &&
              TargetsTimeline.resolve(updated, weightKg: weight, date: today) ==
                  null) {
            return _refuse(TargetsFailure.goalUnresolvable);
          }
        }
        final recompute = active && profile != null
            ? await _recompute(data, today, profile: profile, goals: goals)
            : _Recompute.none;
        return _Write(
          [
            PutGoalPhase(updated, expectedVersion: stored.version),
            ...recompute.ops,
          ],
          recomputedKcal: recompute.kcal,
          warnings: recompute.warnings,
        );
      });

  /// Starts a new goal today (D13): live phases that started before today
  /// and cover today or later end yesterday; a phase that started today is
  /// edited in place; when live phases start after today, the new phase
  /// ends the day before the earliest of them. Recomputes a generated base
  /// in the same change set (D5).
  Future<TargetsOutcome> startPhase(GoalInput goal, {String? name}) => _run(
    TargetsChangeKind.phaseStarted,
    (today) async {
      final data = await read();
      final profile = data.profile?.value;
      final current = _current(data, today);
      if (profile == null || current == null) {
        return _refuse(TargetsFailure.notSetUp);
      }
      final (:valid, :normalized) = _name(name);
      if (!valid) return _refuse(TargetsFailure.invalid);
      final plan = _phasePlan(data.phases, today, goal, normalized);
      if (TargetRules.input.goalPhase(plan.record, today: today).isNotEmpty) {
        return _refuse(TargetsFailure.invalid);
      }
      final weight = await _weight(today, current.value);
      if (weight != null &&
          TargetsTimeline.resolve(plan.record, weightKg: weight, date: today) ==
              null) {
        return _refuse(TargetsFailure.goalUnresolvable);
      }
      final recompute = await _recompute(
        data,
        today,
        profile: profile,
        goals: plan.after,
      );
      return _Write(
        [...plan.ops, ...recompute.ops],
        recomputedKcal: recompute.kcal,
        warnings: recompute.warnings,
      );
    },
  );

  /// Renames the shown phase; a null or blank [name] means the default
  /// label. The domain revision is kept (a name doesn't change the
  /// timeline).
  Future<TargetsOutcome> renamePhase(VersionedId shown, String? name) =>
      _run(TargetsChangeKind.goalUpdated, (today) async {
        final (:valid, :normalized) = _name(name);
        if (!valid) return _refuse(TargetsFailure.invalid);
        final stored = _phase(await read(), shown.id);
        if (stored == null) return _refuse(TargetsFailure.removed);
        if (stored.version != shown.expectedVersion) {
          return _refuse(TargetsFailure.changed);
        }
        if (stored.value.name == normalized) return const _Write([]);
        return _Write([
          PutGoalPhase(
            stored.value.withName(normalized),
            expectedVersion: stored.version,
          ),
        ]);
      });

  /// Weekly budget or the same every day (TG-044). Switching to weekly is
  /// refused for an acknowledged below-floor fixed manual target (PA7).
  Future<TargetsOutcome> setMode(VersionedId shown, TargetMode mode) =>
      _settings(
        shown,
        weeklyOnly: mode == TargetMode.weekly,
        (current) => current.copyWith(mode: mode),
      );

  /// Rebalancing on or off (TG-042); refused under PA7.
  // One value, like the other typed setting commands.
  // ignore: avoid_positional_boolean_parameters
  Future<TargetsOutcome> setRebalancing(VersionedId shown, bool on) =>
      _settings(
        shown,
        weeklyOnly: true,
        (current) => current.copyWith(rebalancing: on),
      );

  /// Weekday shifting weights (TG-043): each given day is set (null or 1.0
  /// = no shift); other days stay. Each weight is 1.0–2.0. Refused under
  /// PA7.
  Future<TargetsOutcome> setShifting(
    VersionedId shown,
    Map<DayOfWeek, double?> weights,
  ) {
    if (weights.values.any((w) => w != null && !TargetRules.input.shift(w))) {
      return Future.value(const TargetsFailed(TargetsFailure.invalid));
    }
    return _settings(shown, weeklyOnly: true, (current) {
      final shifts = {...current.shifts};
      for (final MapEntry(key: day, value: weight) in weights.entries) {
        if (weight == null || weight == 1) {
          shifts.remove(day);
        } else {
          shifts[day] = weight;
        }
      }
      return current.copyWith(shifts: shifts);
    });
  }

  /// Macro settings (TG-054).
  Future<TargetsOutcome> setMacros(VersionedId shown, MacroSettings macros) =>
      _settings(shown, (current) => current.copyWith(macros: macros));

  /// A generated version from the current trend weight (D5, "Recalculate
  /// with your current weight"). A manual version is left as it is
  /// ([TargetsUnchanged]); an unresolvable goal is refused with
  /// [TargetsFailure.goalNeedsUpdate].
  Future<TargetsOutcome> recalculate(VersionedId shown) =>
      _generatedVersion(shown, fromManual: false);

  /// Back to the generated target (TG-021) from a manual one, at the
  /// current trend weight; [TargetsUnchanged] when not manual. An
  /// unresolvable goal is refused with [TargetsFailure.goalNeedsUpdate]
  /// (PA3).
  Future<TargetsOutcome> useCalculatedTarget(VersionedId shown) =>
      _generatedVersion(shown, fromManual: true);

  /// The user's own daily target (SF-012, D11), 500–10,000 kcal. Limits are
  /// checked against today's floor and the 1%/week loss rate at the
  /// current weight (the goal can't change them; an unresolvable goal is
  /// read as maintain, PA3). Breaking a limit without [acknowledged] →
  /// [TargetsNeedsAcknowledgement], nothing written. With it, below the
  /// floor → manual, acknowledged, fixed; beyond only the loss rate →
  /// manual, mode unchanged and **not** stored as acknowledged (an
  /// acknowledgement only ever means "below the floor, seen", so a floor
  /// that later rises above the value is flagged, never honoured
  /// silently). Within the limits → manual, not acknowledged, mode
  /// unchanged.
  Future<TargetsOutcome> setManualTarget(
    VersionedId shown,
    double kcal, {
    bool acknowledged = false,
  }) {
    if (!TargetRules.input.manualKcal(kcal)) {
      return Future.value(const TargetsFailed(TargetsFailure.invalid));
    }
    return _settingsPlan(shown, (data, current, today) async {
      final weight = await _weight(today, current.value);
      if (weight == null) return _refuse(TargetsFailure.invalid);
      final profile = data.profile!.value;
      final goal = _activeGoal(data, today, weight) ?? _maintain(weight, today);
      final calc = TargetCalculator.calculate(
        profile: profile.toProfile(weight),
        goal: goal,
        date: today,
        manualKcal: kcal,
        acknowledged: true,
        defaults: defaults,
      );
      final warnings = calc.warnings.intersection(const {
        TargetWarning.manualBelowFloor,
        TargetWarning.manualLossRateExceeded,
      });
      if (warnings.isNotEmpty && !acknowledged) {
        return _Refuse(
          TargetsNeedsAcknowledgement(
            floorKcal: calc.floorKcal,
            impliedKgPerWeek: calc.achievableKgPerWeek,
            warnings: warnings,
          ),
        );
      }
      // An acknowledgement only ever means "below the floor, seen": a
      // rate-only warning is confirmed here but not stored.
      final below = warnings.contains(TargetWarning.manualBelowFloor);
      return _revision(
        current,
        today,
        (r) => r.copyWith(
          baseKcal: kcal,
          basisWeightKg: weight,
          manual: true,
          acknowledged: below,
          mode: below ? TargetMode.fixed : null,
        ),
        warnings: warnings,
      );
    });
  }

  // ---------------------------------------------------------------------
  // Plans.

  Future<_Plan> _setup(SetupInput input, LocalDate today) async {
    final data = await read();
    if (data.profile != null ||
        data.profileUnreadable ||
        data.settings.isNotEmpty) {
      return _refuse(TargetsFailure.alreadySetUp);
    }
    // The first weigh-in follows A14's rules (WB-003, A14 D6).
    final weighIn = WeighInDraft(
      time: EntryTime.now(clock),
      input: input.weighIn,
    );
    if (weighIn.validate() != null) return _refuse(TargetsFailure.invalid);
    final (:valid, :normalized) = _name(input.goalName);
    final preview = SetupPreview.of(input, today, defaults: defaults);
    if (preview.issue == SetupPreviewIssue.goalUnresolvable) {
      return _refuse(TargetsFailure.goalUnresolvable);
    }
    final calc = preview.calculation;
    if (!valid || calc == null) return _refuse(TargetsFailure.invalid);
    final preferences = await _preferenceOps(input.preferences);
    if (preferences == null) return _refuse(TargetsFailure.invalid);
    final phases = _phasePlan(data.phases, today, input.goal, normalized);
    final version = TargetSettingsRecord(
      id: ids.next(),
      revision: 1,
      effectiveFrom: today,
      baseKcal: calc.kcal,
      basisWeightKg: input.weightKg,
    );
    return _Write(
      [
        PutProfile(input.profile),
        CreateWeighIn(ids.next(), weighIn),
        ...phases.ops,
        PutTargetSettings(version),
        ...preferences,
      ],
      recomputedKcal: calc.kcal,
      warnings: calc.warnings,
    );
  }

  /// The settings ops for the preferences that differ from the stored
  /// ones, or null for an invalid city.
  Future<List<ChangeOp>?> _preferenceOps(SetupPreferences chosen) async {
    final city = chosen.cityId;
    if (city != null && !AppSettings.isCityId(city)) return null;
    Future<ChangeOp?> put<T>(SettingKey<T> key, T value) async {
      if (await settings.read(key) == value) return null;
      return value == null
          ? SettingsOp.reset(key.name)
          : SettingsOp.put(key.name, key.codec.encode(value));
    }

    return [
      ?await put(AppSettings.unitSystem, chosen.unitSystem),
      ?await put(AppSettings.weekStart, chosen.weekStart),
      ?await put(AppSettings.halal, chosen.halal),
      ?await put(AppSettings.cityId, city),
    ];
  }

  /// The D13 new-phase rule over the live [phases]: the ops, the new (or
  /// edited) record, and every phase after the change (for the recompute).
  _PhasePlan _phasePlan(
    List<Versioned<GoalPhaseRecord>> phases,
    LocalDate today,
    GoalInput goal,
    String? name,
  ) {
    final yesterday = today.plusDays(-1);
    final ops = <ChangeOp>[];
    final after = <GoalPhaseRecord>[];
    Versioned<GoalPhaseRecord>? startedToday;
    LocalDate? earliestFuture;
    for (final stored in phases) {
      final phase = stored.value;
      if (phase.start.isAfter(today)) {
        if (earliestFuture == null || phase.start.isBefore(earliestFuture)) {
          earliestFuture = phase.start;
        }
        after.add(phase);
      } else if (phase.start == today) {
        // Several same-day rows only arrive by sync: edit the one the
        // projection shows (higher revision, then ID) and keep the others.
        final shown = startedToday?.value;
        if (shown == null ||
            phase.revision > shown.revision ||
            (phase.revision == shown.revision &&
                phase.id.compareTo(shown.id) > 0)) {
          if (shown != null) after.add(shown);
          startedToday = stored;
        } else {
          after.add(phase);
        }
      } else if (phase.end == null || !phase.end!.isBefore(today)) {
        final ended = phase
            .withEnd(yesterday)
            .copyWith(revision: phase.revision + 1);
        ops.add(PutGoalPhase(ended, expectedVersion: stored.version));
        after.add(ended);
      } else {
        after.add(phase);
      }
    }
    final end = earliestFuture?.plusDays(-1);
    final edit = startedToday;
    final record = goal.toRecord(
      id: edit?.value.id ?? ids.next(),
      start: today,
      name: name,
      end: end,
    );
    final GoalPhaseRecord put;
    if (edit == null) {
      put = record;
      ops.add(PutGoalPhase(put));
    } else {
      put = record.copyWith(revision: edit.value.revision + 1);
      ops.add(PutGoalPhase(put, expectedVersion: edit.version));
    }
    return (ops: ops, record: put, after: [...after, put]);
  }

  /// D5 recompute: with a generated version in effect [today], a revised
  /// version with the base for [profile] and [goals] at the trend weight
  /// (else the basis weight). Nothing for a manual version, without a
  /// version, when the goal can't be resolved (PA3) or when the base and
  /// basis weight stay the same.
  Future<_Recompute> _recompute(
    TargetsData data,
    LocalDate today, {
    required ProfileRecord profile,
    required List<GoalPhaseRecord> goals,
  }) async {
    final current = _current(data, today);
    if (current == null || current.value.manual) return _Recompute.none;
    final weight = await _weight(today, current.value);
    if (weight == null) return _Recompute.none;
    final calc = _generated(profile, goals, weight, today);
    if (calc == null) return _Recompute.none;
    if (calc.kcal == current.value.baseKcal &&
        weight == current.value.basisWeightKg) {
      return _Recompute.none;
    }
    final next = TargetSettingsRevision.next(
      current: current.value,
      currentVersion: current.version,
      today: today,
      newId: ids.next(),
      change: (r) => r.copyWith(
        baseKcal: calc.kcal,
        basisWeightKg: weight,
        manual: false,
        acknowledged: false,
      ),
    );
    return _Recompute(
      [PutTargetSettings(next.record, expectedVersion: next.expectedVersion)],
      kcal: calc.kcal,
      warnings: calc.warnings,
    );
  }

  Future<TargetsOutcome> _generatedVersion(
    VersionedId shown, {
    required bool fromManual,
  }) => _settingsPlan(shown, (data, current, today) async {
    if (current.value.manual != fromManual) return const _Write([]);
    final weight = await _weight(today, current.value);
    if (weight == null) return _refuse(TargetsFailure.invalid);
    final calc = _generated(
      data.profile!.value,
      _values(data.phases),
      weight,
      today,
    );
    if (calc == null) return _refuse(TargetsFailure.goalNeedsUpdate);
    return _revision(
      current,
      today,
      (r) => r.copyWith(
        baseKcal: calc.kcal,
        basisWeightKg: weight,
        manual: false,
        acknowledged: false,
      ),
      recomputedKcal: calc.kcal,
      warnings: calc.warnings,
    );
  });

  /// A settings change through the D5 revision rule.
  Future<TargetsOutcome> _settings(
    VersionedId shown,
    TargetSettingsRecord Function(TargetSettingsRecord current) change, {
    bool weeklyOnly = false,
  }) => _settingsPlan(shown, (data, current, today) async {
    if (weeklyOnly && await _fixedBelowFloor(data, current.value, today)) {
      return _refuse(TargetsFailure.fixedBelowFloor);
    }
    final updated = change(current.value);
    if (TargetRules.input
        .targetSettings(updated, before: current.value)
        .isNotEmpty) {
      return _refuse(TargetsFailure.invalid);
    }
    return _revision(current, today, change);
  });

  /// Checks the shown version is the one in effect today, at its version,
  /// then plans with it.
  Future<TargetsOutcome> _settingsPlan(
    VersionedId shown,
    Future<_Plan> Function(
      TargetsData data,
      Versioned<TargetSettingsRecord> current,
      LocalDate today,
    )
    plan,
  ) => _run(TargetsChangeKind.targetsUpdated, (today) async {
    final data = await read();
    final current = _current(data, today);
    if (data.profile == null || current == null) {
      return _refuse(TargetsFailure.notSetUp);
    }
    if (_version(data, shown.id) == null) {
      return _refuse(TargetsFailure.removed);
    }
    if (current.value.id != shown.id ||
        current.version != shown.expectedVersion) {
      return _refuse(TargetsFailure.changed);
    }
    return await plan(data, current, today);
  });

  /// The D5 revision of [current] by [change]; nothing when it changes no
  /// field.
  _Write _revision(
    Versioned<TargetSettingsRecord> current,
    LocalDate today,
    TargetSettingsRecord Function(TargetSettingsRecord) change, {
    double? recomputedKcal,
    Set<TargetWarning> warnings = const {},
  }) {
    if (change(current.value) == current.value) return const _Write([]);
    final next = TargetSettingsRevision.next(
      current: current.value,
      currentVersion: current.version,
      today: today,
      newId: ids.next(),
      change: change,
    );
    return _Write(
      [PutTargetSettings(next.record, expectedVersion: next.expectedVersion)],
      recomputedKcal: recomputedKcal,
      warnings: warnings,
    );
  }

  // ---------------------------------------------------------------------
  // Engine helpers.

  /// The generated calculation for [profile] at [weight] on [today] with
  /// the goal in effect then (maintain in a gap), or null when the goal
  /// can't be resolved or the profile can't be evaluated (PA3).
  TargetCalculation? _generated(
    ProfileRecord profile,
    List<GoalPhaseRecord> goals,
    double weight,
    LocalDate today,
  ) {
    final phase = TargetsTimeline.phaseOn(goals, today);
    final goal = phase == null
        ? _maintain(weight, today)
        : TargetsTimeline.resolve(phase, weightKg: weight, date: today);
    if (goal == null) return null;
    try {
      return TargetCalculator.calculate(
        profile: profile.toProfile(weight),
        goal: goal,
        date: today,
        defaults: defaults,
      );
    }
    // The engine's content-free signal for an impossible input (PA3).
    // ignore: avoid_catching_errors
    on ArgumentError {
      return null;
    }
  }

  ResolvedGoal? _activeGoal(TargetsData data, LocalDate today, double weight) {
    final phase = TargetsTimeline.phaseOn(_values(data.phases), today);
    return phase == null
        ? null
        : TargetsTimeline.resolve(phase, weightKg: weight, date: today);
  }

  static ResolvedGoal _maintain(double weight, LocalDate today) =>
      ResolvedGoal.resolve(
        type: GoalType.maintain,
        expression: GoalExpression.weekly(0),
        currentKg: weight,
        date: today,
      );

  /// PA7: [current] is an acknowledged fixed manual target below today's
  /// floor (an unusable weight or uncomputable floor counts as below:
  /// refusing is the safe side).
  Future<bool> _fixedBelowFloor(
    TargetsData data,
    TargetSettingsRecord current,
    LocalDate today,
  ) async {
    if (!current.mayStayBelowFloor) return false;
    final weight = await _weight(today, current);
    if (weight == null) return true;
    try {
      final floor = TargetCalculator.floor(
        data.profile!.value.toProfile(weight),
        today,
        defaults: defaults,
      );
      return current.baseKcal < floor;
    }
    // The engine's content-free signal for an impossible input.
    // ignore: avoid_catching_errors
    on ArgumentError {
      return true;
    }
  }

  /// The trend weight on [today], else [current]'s basis weight (D8); a
  /// weight outside [TargetRules.input] (a synced outlier) is unusable, and
  /// with neither usable the result is null.
  Future<double?> _weight(LocalDate today, TargetSettingsRecord current) async {
    final trend = await bodyWeightKg(today);
    if (trend != null && TargetRules.input.weight(trend)) return trend;
    final basis = current.basisWeightKg;
    return TargetRules.input.weight(basis) ? basis : null;
  }

  // ---------------------------------------------------------------------
  // Running.

  Future<TargetsOutcome> _run(
    TargetsChangeKind kind,
    Future<_Plan> Function(LocalDate today) build,
  ) async {
    if (_busy) return const TargetsPending();
    _busy = true;
    try {
      final today = EntryTime.now(clock).localDate;
      final _Plan plan;
      try {
        plan = await build(today);
      }
      // Residual engine errors are typed failures, never crashes (D11).
      // ignore: avoid_catching_errors
      on ArgumentError {
        return const TargetsFailed(TargetsFailure.invalid);
      }
      // A read that fails (database, weigh-ins) is typed too: nothing has
      // been written yet, and the UI never sees a throw.
      on Object {
        return const TargetsFailed(TargetsFailure.unavailable);
      }
      if (plan case _Refuse(:final outcome)) return outcome;
      final write = plan as _Write;
      if (write.ops.isEmpty) return const TargetsUnchanged();
      final ApplyResult result;
      try {
        result = await apply(ChangeSet(write.ops, origin: Origin.direct));
      } on ChangeRejected catch (rejection) {
        return _failure(rejection.failure);
      }
      // The single writer rolled back: nothing was written.
      on Object {
        return const TargetsFailed(TargetsFailure.unavailable);
      }
      if (result is Rejected) return _failure(result.failure);
      final applied = result as Applied;
      if (applied.inverse.isEmpty) return const TargetsUnchanged();
      final undo = undoStack.record(
        applied,
        UndoLabel(kind.name, args: {'kcal': ?write.recomputedKcal}),
      );
      return TargetsDone(
        undo.id,
        kind,
        recomputedKcal: write.recomputedKcal,
        warnings: write.warnings,
      );
    } finally {
      _busy = false;
    }
  }

  static TargetsFailed _failure(ChangeFailure failure) =>
      TargetsFailed(switch (failure) {
        VersionConflict() ||
        InvalidOp(code: 'phaseOverlap') ||
        InvalidOp(code: 'duplicateDate') => TargetsFailure.changed,
        RowNotFound() => TargetsFailure.removed,
        _ => TargetsFailure.invalid,
      });

  static _Refuse _refuse(TargetsFailure reason) =>
      _Refuse(TargetsFailed(reason));

  static Versioned<GoalPhaseRecord>? _phase(TargetsData data, String id) =>
      data.phases.where((p) => p.value.id == id).firstOrNull;

  static Versioned<TargetSettingsRecord>? _version(
    TargetsData data,
    String id,
  ) => data.settings.where((s) => s.value.id == id).firstOrNull;

  static List<GoalPhaseRecord> _values(List<Versioned<GoalPhaseRecord>> rows) =>
      [for (final row in rows) row.value];

  /// The version in effect on [today] with its row version, or null.
  static Versioned<TargetSettingsRecord>? _current(
    TargetsData data,
    LocalDate today,
  ) {
    final current = TargetsTimeline.versionOn([
      for (final s in data.settings) s.value,
    ], today);
    return current == null ? null : _version(data, current.id);
  }

  /// A trimmed phase name, null when blank (the default label).
  static ({bool valid, String? normalized}) _name(String? name) {
    final trimmed = name?.trim();
    final normalized = trimmed == null || trimmed.isEmpty ? null : trimmed;
    return (valid: TargetRules.input.name(normalized), normalized: normalized);
  }
}

typedef _PhasePlan = ({
  List<ChangeOp> ops,
  GoalPhaseRecord record,
  List<GoalPhaseRecord> after,
});

/// What a D5 recompute adds to a change set.
final class _Recompute {
  const new(this.ops, {this.kcal, this.warnings = const {}});

  /// Nothing recomputed.
  static const _Recompute none = _Recompute([]);

  final List<ChangeOp> ops;
  final double? kcal;
  final Set<TargetWarning> warnings;
}

sealed class _Plan {
  const new();
}

/// An outcome without a write.
final class _Refuse extends _Plan {
  const new(this.outcome);

  final TargetsOutcome outcome;
}

/// The ops of one change set (none: unchanged).
final class _Write extends _Plan {
  const new(this.ops, {this.recomputedKcal, this.warnings = const {}});

  final List<ChangeOp> ops;
  final double? recomputedKcal;
  final Set<TargetWarning> warnings;
}

/// Session-owned: a pending command survives route changes.
@Riverpod(keepAlive: true)
TargetsActions targetsActions(Ref ref) => TargetsActions(
  apply: ref.watch(changeSetApplierProvider).apply,
  undoStack: ref.watch(undoStackProvider),
  ids: ref.watch(idGeneratorProvider),
  clock: ref.watch(clockProvider),
  read: ref.watch(targetsRepositoryProvider).read,
  settings: ref.watch(settingsStoreProvider),
  // One read of the weigh-ins per command (A14's reader): no auto-disposed
  // provider is involved, so nothing can be disposed while it loads.
  bodyWeightKg: ref.watch(bodyWeightReaderProvider),
);
