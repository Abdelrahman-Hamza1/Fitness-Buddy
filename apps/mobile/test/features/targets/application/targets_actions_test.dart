import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/core/changes/row_ops.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/settings/settings_store.dart';
import 'package:fb_mobile/core/undo/undo_stack.dart';
import 'package:fb_mobile/features/body/data/weigh_in_repository.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:fb_mobile/features/targets/data/target_mappers.dart';
import 'package:fb_mobile/features/targets/targets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../core/changes/support/test_db.dart' show ScriptOp;
import 'targets_app_harness.dart';

/// The engine's generated base for [profile] at [weightKg] on [date].
double generated(
  ProfileRecord profile,
  double weightKg,
  GoalInput goal,
  LocalDate date,
) => TargetCalculator.calculate(
  profile: profile.toProfile(weightKg),
  goal: ResolvedGoal.resolve(
    type: goal.type,
    expression: goal.expression,
    currentKg: weightKg,
    date: date,
  ),
  date: date,
).kcal;

/// A synced phase row [id] (no targets rules on the way in).
ScriptOp syncedPhase(
  TargetsAppHarness h,
  String id,
  LocalDate start, {
  LocalDate? end,
}) => ScriptOp.rows([
  InsertRow(
    h.db.goalPhases,
    goalPhaseColumns(
      GoalPhaseRecord(
        id: id,
        revision: 1,
        start: start,
        end: end,
        type: GoalType.lose,
        expression: GoalExpression.weekly(-.25),
        weightInputUnit: MassUnit.kilogram,
      ),
    ),
  ),
]);

void main() {
  test('UX-060 WB-001 completeSetup writes profile, goal, settings and the '
      'first weigh-in in one change set; undo removes all', () async {
    // Also: the generated base, basis weight = the typed weight, and only
    // the preferences that differ from the stored ones.
    final h = TargetsAppHarness();
    final store = SettingsStore(db: h.db, applier: h.applier);
    final before = await h.state();
    final settingRowsBefore = await h.db.select(h.db.settingsKv).get();
    final done = await h.setUp(
      setupInput(
        goalName: '  Autumn  ',
        preferences: const SetupPreferences(
          unitSystem: UnitSystem.metric,
          weekStart: DayOfWeek.monday,
          halal: true,
          cityId: 'city:360630',
        ),
      ),
    );
    expect(done.kind, TargetsChangeKind.targetsSet);
    expect(done.recomputedKcal, setupBase);
    expect(done.warnings, isEmpty);
    expect(h.undo.entries, hasLength(1));
    expect(h.undo.entries.single.label.key, 'targetsSet');

    final data = await h.data();
    expect(data.profile!.value, setupInput().profile);
    final phase = data.phases.single.value;
    expect(
      (phase.start, phase.end, phase.revision, phase.name, phase.type),
      (today, null, 1, 'Autumn', GoalType.lose),
    );
    expect((phase.expression as WeeklyGoal).kgPerWeek, -.5);
    final version = data.settings.single.value;
    expect(version.effectiveFrom, today);
    expect(version.revision, 1);
    expect(version.baseKcal, setupBase);
    expect(version.basisWeightKg, 80);
    expect(
      (version.mode, version.rebalancing, version.manual, version.acknowledged),
      (TargetMode.weekly, true, false, false),
    );
    expect(version.shifts, isEmpty);
    expect(version.macros.protein, isNull);

    // The first weigh-in (A14): the typed value and unit, measured now.
    final weighIns = await WeighInRepository(h.db).watchLive().first;
    final weighIn = weighIns.single;
    expect(weighIn.input, const WeighInInput(80, MassUnit.kilogram));
    expect(weighIn.kg, 80);
    expect(weighIn.time, EntryTime.now(h.clock));

    // Only the week start and the city differ from the stored values.
    final settingRows = await h.db.select(h.db.settingsKv).get();
    expect(settingRows.length - settingRowsBefore.length, 2);
    expect(await store.read(AppSettings.weekStart), DayOfWeek.monday);
    expect(await store.read(AppSettings.cityId), 'city:360630');

    expect(await h.undo.undo(done.undoEntryId), UndoOutcome.undone);
    expect(await h.state(), before);
    expect(await store.read(AppSettings.weekStart), DayOfWeek.saturday);
    expect(await WeighInRepository(h.db).watchLive().first, isEmpty);
  });

  test(
    'WB-001 TD-090 completeSetup in lb stores the weigh-in as typed and '
    'its kg as the basis weight; a weight A14 rejects writes nothing',
    () async {
      final h = TargetsAppHarness();
      await h.setUp(setupInput(weight: 176, weightUnit: MassUnit.pound));
      final weighIn = (await WeighInRepository(h.db).watchLive().first).single;
      expect(weighIn.input, const WeighInInput(176, MassUnit.pound));
      expect((await h.currentVersion()).basisWeightKg, weighIn.kg);

      final fresh = TargetsAppHarness();
      final failed = await fresh.expectNoWrite<TargetsFailed>(
        () => fresh.actions.completeSetup(setupInput(weight: 19.99)),
      );
      expect(failed.reason, TargetsFailure.invalid);
    },
  );

  test('A13a security #3 completeSetup over a stored profile this version '
      "can't read → alreadySetUp, nothing written; setupStatus asks for an "
      'update', () async {
    final h = TargetsAppHarness();
    await h.apply([
      ScriptOp.rows([
        UpsertRow(
          h.db.profiles,
          profileColumns(setupInput().profile)
              .copyWith(sex: const Value('average')),
        ),
      ]),
    ]);
    final c = h.container()..listen(setupStatusProvider, (_, _) {});
    expect(
      await c.read(setupStatusProvider.future),
      SetupStatus.profileUnreadable,
    );
    final failed = await h.expectNoWrite<TargetsFailed>(
      () => h.actions.completeSetup(setupInput()),
    );
    expect(failed.reason, TargetsFailure.alreadySetUp);
  });

  test('UX-060 completeSetup when already set up → alreadySetUp, nothing '
      'written', () async {
    final h = TargetsAppHarness();
    await h.setUp();
    final failed = await h.expectNoWrite<TargetsFailed>(
      () => h.actions.completeSetup(setupInput(weight: 90)),
    );
    expect(failed.reason, TargetsFailure.alreadySetUp);
  });

  test('TG-013 SF-011 a requested loss above 1% of body weight a week stores '
      'the capped base and reports lossRateCapped', () async {
    final h = TargetsAppHarness();
    final done = await h.setUp(
      setupInput(
        goal: GoalInput(
          type: GoalType.lose,
          expression: GoalExpression.weekly(-1.2),
        ),
      ),
    );
    // 80 kg → at most 0.8 kg a week: 2,712.5 − 0.8 × 7,700 / 7.
    expect(done.warnings, {TargetWarning.lossRateCapped});
    expect((await h.currentVersion()).baseKcal, closeTo(1832.5, 1e-9));
  });

  test('SF-010 a raw target below the floor stores the floor and reports '
      'calorieFloorApplied', () async {
    final h = TargetsAppHarness();
    // Female, 160 cm, 50 kg, sedentary: resting 1,159, floor 1,200; raw
    // 1,390.8 − 550 = 840.8.
    final done = await h.setUp(
      setupInput(
        sex: FormulaSex.female,
        height: Length.centimeters(160),
        weight: 50,
        activity: ActivityLevel.sedentary,
      ),
    );
    expect(done.warnings, {TargetWarning.calorieFloorApplied});
    expect((await h.currentVersion()).baseKcal, 1200);
  });

  test('D5 saving sex, birth year, height or activity on a generated version '
      'recomputes the base with bodyWeightKg(today) in the same change set; '
      'a manual version is untouched', () async {
    for (final patch in const [
      ProfilePatch(sex: FormulaSex.female),
      ProfilePatch(birthYear: 1980),
      ProfilePatch(heightCm: 170),
      ProfilePatch(activity: ActivityLevel.high),
    ]) {
      final h = TargetsAppHarness();
      await h.setUp();
      final before = await h.state();
      h.trend = 78;
      final done = await h.actions.saveProfile(patch, 1) as TargetsDone;
      final profile = patch.applyTo(setupInput().profile);
      final expected = generated(profile, 78, loseHalf, today);
      expect(done.kind, TargetsChangeKind.profileUpdated);
      expect(done.recomputedKcal, expected);
      expect(h.undo.latest!.label.args, {'kcal': expected});
      final data = await h.data();
      expect(data.profile!.value, profile);
      // Effective today: the same row, revised (D5).
      final version = data.settings.single.value;
      expect(
        (version.revision, version.baseKcal, version.basisWeightKg),
        (2, expected, 78.0),
      );
      // One change set: one undo restores both.
      await h.undo.undo(done.undoEntryId);
      expect(await h.state(), before);
    }
    // Hand-checked: high activity at 78 kg = 1,730 × 1.725 − 550.
    expect(
      generated(
        const ProfilePatch(activity: ActivityLevel.high)
            .applyTo(setupInput().profile),
        78,
        loseHalf,
        today,
      ),
      closeTo(2434.25, 1e-9),
    );

    final h = TargetsAppHarness();
    await h.setUp();
    await h.actions.setManualTarget(await h.shownVersion(), 2300);
    final manual = await h.currentVersion();
    h.trend = 78;
    final done = await h.actions.saveProfile(
      const ProfilePatch(activity: ActivityLevel.high),
      1,
    ) as TargetsDone;
    expect(done.recomputedKcal, isNull);
    expect(await h.currentVersion(), manual);
    expect((await h.data()).profile!.value.activity, ActivityLevel.high);
  });

  test('D5 a new weigh-in alone never changes the stored base; recalculate() '
      'writes a generated version from the current trend weight', () async {
    final h = TargetsAppHarness();
    await h.setUp();
    final stored = await h.currentVersion();
    // A lower trend (a new weigh-in) moves no stored number.
    h
      ..trend = 75
      ..advanceDays(1);
    expect(await h.currentVersion(), stored);

    final done =
        await h.actions.recalculate(await h.shownVersion()) as TargetsDone;
    // 75 kg: resting 1,700 × 1.55 − 550.
    expect(done.recomputedKcal, closeTo(2085, 1e-9));
    expect(done.kind, TargetsChangeKind.targetsUpdated);
    final version = await h.currentVersion();
    // A new day: a new row effective today copying every other field.
    expect(version.id, isNot(stored.id));
    expect(
      version,
      stored.copyWith(
        id: version.id,
        effectiveFrom: h.date,
        baseKcal: done.recomputedKcal,
        basisWeightKg: 75,
      ),
    );
    // Same weight again: nothing to recalculate.
    await h.expectNoWrite<TargetsUnchanged>(
      () async => await h.actions.recalculate(await h.shownVersion()),
    );
  });

  test(
    'PA3 saving the profile while the goal deadline has passed applies the '
    'profile, keeps the current version and returns recomputedKcal null',
    () async {
      final h = TargetsAppHarness();
      await h.setUp(
        setupInput(
          goal: GoalInput(
            type: GoalType.lose,
            expression: GoalExpression.targetDate(75, LocalDate(2026, 12, 31)),
          ),
        ),
      );
      final stored = await h.currentVersion();
      h.advanceDays(77); // 2027-01-02: the deadline has passed.
      final done = await h.actions.saveProfile(
        const ProfilePatch(activity: ActivityLevel.high),
        1,
      ) as TargetsDone;
      expect(done.recomputedKcal, isNull);
      expect(await h.currentVersion(), stored);
      expect((await h.data()).profile!.value.activity, ActivityLevel.high);
    },
  );

  test('PA3 setManualTarget with an unresolvable goal checks limits against '
      'maintain', () async {
    final h = TargetsAppHarness();
    await h.setUp(
      setupInput(
        goal: GoalInput(
          type: GoalType.lose,
          expression: GoalExpression.targetDate(75, LocalDate(2026, 12, 31)),
        ),
      ),
    );
    h.advanceDays(77);
    // Age 37 in 2027: resting (= floor) 1,745, expenditure 2,704.75.
    final ack = await h.expectNoWrite<TargetsNeedsAcknowledgement>(
      () async => await h.actions.setManualTarget(await h.shownVersion(), 1500),
    );
    expect(ack.floorKcal, 1745);
    expect(ack.warnings, contains(TargetWarning.manualBelowFloor));
    final done = await h.actions.setManualTarget(await h.shownVersion(), 2600);
    expect(done, isA<TargetsDone>());
    final version = await h.currentVersion();
    expect(
      (version.manual, version.acknowledged, version.mode, version.baseKcal),
      (true, false, TargetMode.weekly, 2600.0),
    );
  });

  test('PA3 useCalculatedTarget with an unresolvable goal fails with a typed '
      'reason, nothing written', () async {
    final h = TargetsAppHarness();
    await h.setUp(
      setupInput(
        goal: GoalInput(
          type: GoalType.lose,
          expression: GoalExpression.targetDate(75, LocalDate(2026, 12, 31)),
        ),
      ),
    );
    await h.actions.setManualTarget(await h.shownVersion(), 2400);
    h.advanceDays(77);
    final failed = await h.expectNoWrite<TargetsFailed>(
      () async => await h.actions.useCalculatedTarget(await h.shownVersion()),
    );
    expect(failed.reason, TargetsFailure.goalNeedsUpdate);
    final recalc = await h.expectNoWrite<TargetsUnchanged>(
      () async => await h.actions.recalculate(await h.shownVersion()),
    );
    expect(recalc, isA<TargetsUnchanged>());
  });

  test('TG-012 startPhase ends every live phase covering today or later at '
      'yesterday and starts the new one today; a phase that started today is '
      'edited instead', () async {
    final h = TargetsAppHarness();
    await h.setUp();
    final setupPhase = (await h.phases()).single.value;
    // A synced overlap (B) and a past phase (C) that started earlier.
    final b = h.ids.next();
    final c = h.ids.next();
    await h.apply([
      syncedPhase(h, b, today.plusDays(1), end: today.plusDays(8)),
      syncedPhase(h, c, LocalDate(2026, 10, 1), end: LocalDate(2026, 10, 10)),
    ]);
    h.advanceDays(3); // Tuesday 2026-10-20.
    final yesterday = h.date.plusDays(-1);

    final done = await h.actions.startPhase(
      GoalInput.maintain(),
      name: 'Hold',
    ) as TargetsDone;
    expect(done.kind, TargetsChangeKind.phaseStarted);
    final phases = {for (final p in await h.phases()) p.value.id: p.value};
    expect(phases, hasLength(4));
    expect(
      (phases[setupPhase.id]!.end, phases[setupPhase.id]!.revision),
      (yesterday, 2),
    );
    expect((phases[b]!.end, phases[b]!.revision), (yesterday, 2));
    expect(phases[c]!.end, LocalDate(2026, 10, 10));
    expect(phases[c]!.revision, 1);
    final started = phases.values.singleWhere((p) => p.start == h.date);
    expect(
      (started.end, started.revision, started.type, started.name),
      (null, 1, GoalType.maintain, 'Hold'),
    );
    // The generated version is recomputed for maintain: a new row today.
    expect(done.recomputedKcal, 2712.5);
    final version = await h.currentVersion();
    expect((version.effectiveFrom, version.baseKcal), (h.date, 2712.5));

    final edited = await h.actions.startPhase(
      GoalInput(type: GoalType.gain, expression: GoalExpression.weekly(.25)),
    ) as TargetsDone;
    expect(edited.kind, TargetsChangeKind.phaseStarted);
    final after = {for (final p in await h.phases()) p.value.id: p.value};
    expect(after, hasLength(4));
    final again = after[started.id]!;
    expect(
      (again.start, again.revision, again.type, again.name),
      (h.date, 2, GoalType.gain, null),
    );
  });

  test('TG-012 D13 startPhase with live phases starting after today ends the '
      'new phase the day before the earliest of them', () async {
    final h = TargetsAppHarness();
    await h.setUp();
    final f = h.ids.next();
    final g = h.ids.next();
    await h.apply([
      syncedPhase(h, f, today.plusDays(8)),
      syncedPhase(h, g, today.plusDays(12), end: today.plusDays(20)),
    ]);
    h.advanceDays(3);
    await h.actions.startPhase(GoalInput.maintain());
    final phases = {for (final p in await h.phases()) p.value.id: p.value};
    final started = phases.values.singleWhere((p) => p.start == h.date);
    expect(started.end, today.plusDays(7));
    expect(phases[f]!.revision, 1);
    expect(phases[g]!.revision, 1);
  });

  test('TG-010 TG-012 saveGoal bumps the revision and recomputes; renamePhase '
      'keeps the revision and a blank name is the default label', () async {
    final h = TargetsAppHarness();
    await h.setUp();
    final shown = (await h.phases()).single;
    final id = VersionedId(shown.value.id, shown.version);
    final goal = GoalInput(
      type: GoalType.lose,
      expression: GoalExpression.weekly(-.25),
    );
    final done = await h.actions.saveGoal(goal, id) as TargetsDone;
    expect(done.kind, TargetsChangeKind.goalUpdated);
    expect(done.recomputedKcal, 2712.5 - 275);
    final saved = (await h.phases()).single;
    expect(saved.value.revision, 2);
    expect((saved.value.expression as WeeklyGoal).kgPerWeek, -.25);
    // The stale row is refused.
    expect(
      (await h.expectNoWrite<TargetsFailed>(
        () => h.actions.saveGoal(loseHalf, id),
      )).reason,
      TargetsFailure.changed,
    );
    // The same goal again writes nothing.
    final current = VersionedId(saved.value.id, saved.version);
    await h.expectNoWrite<TargetsUnchanged>(
      () => h.actions.saveGoal(goal, current),
    );

    expect(
      await h.actions.renamePhase(current, ' Spring '),
      isA<TargetsDone>(),
    );
    final renamed = (await h.phases()).single;
    expect((renamed.value.name, renamed.value.revision), ('Spring', 2));
    await h.actions.renamePhase(
      VersionedId(renamed.value.id, renamed.version),
      '   ',
    );
    expect((await h.phases()).single.value.name, isNull);
  });

  test('TG-041 TG-043 TG-044 TG-054 setMode, setRebalancing, setShifting and '
      'setMacros copy every other field; a stale version → changed, nothing '
      'written', () async {
    final h = TargetsAppHarness();
    await h.setUp();
    final original = await h.currentVersion();
    final first = await h.shownVersion();
    await h.actions.setMode(first, TargetMode.fixed);
    expect(
      await h.currentVersion(),
      original.copyWith(revision: 2, mode: TargetMode.fixed),
    );
    // The screen still shows version 1: refused.
    expect(
      (await h.expectNoWrite<TargetsFailed>(
        () => h.actions.setRebalancing(first, false),
      )).reason,
      TargetsFailure.changed,
    );

    h.advanceDays(1); // Sunday: the next change is a new row (D5).
    await h.actions.setRebalancing(await h.shownVersion(), false);
    final sunday = await h.currentVersion();
    expect(sunday.id, isNot(original.id));
    expect(
      sunday,
      original.copyWith(
        id: sunday.id,
        revision: 1,
        effectiveFrom: h.date,
        mode: TargetMode.fixed,
        rebalancing: false,
      ),
    );
    // Saturday's row is no longer the one in effect: refused.
    expect(
      (await h.expectNoWrite<TargetsFailed>(
        () => h.actions.setMode(VersionedId(original.id, 2), TargetMode.weekly),
      )).reason,
      TargetsFailure.changed,
    );

    await h.actions.setShifting(await h.shownVersion(), {
      DayOfWeek.friday: 1.3,
      DayOfWeek.saturday: null,
    });
    expect(
      await h.currentVersion(),
      sunday.copyWith(revision: 2, shifts: {DayOfWeek.friday: 1.3}),
    );
    final macros = MacroSettings(
      protein: MacroOverride.grams(150),
      fat: MacroOverride.percent(25),
      fiberGrams: 30,
    );
    await h.actions.setMacros(await h.shownVersion(), macros);
    expect(
      await h.currentVersion(),
      sunday.copyWith(
        revision: 3,
        shifts: {DayOfWeek.friday: 1.3},
        macros: macros,
      ),
    );
    // A shift back to 1.0 clears the day.
    await h.actions.setShifting(await h.shownVersion(), {DayOfWeek.friday: 1});
    expect((await h.currentVersion()).shifts, isEmpty);
    // A version that is gone is "removed".
    expect(
      (await h.expectNoWrite<TargetsFailed>(
        () =>
            h.actions.setMode(VersionedId(h.ids.next(), 1), TargetMode.weekly),
      )).reason,
      TargetsFailure.removed,
    );
  });

  test('SF-012 setManualTarget below the floor without acknowledgement → '
      'NeedsAcknowledgement with the floor, nothing written; with it → manual, '
      'acknowledged, fixed', () async {
    final h = TargetsAppHarness();
    await h.setUp();
    final shown = await h.shownVersion();
    final ack = await h.expectNoWrite<TargetsNeedsAcknowledgement>(
      () => h.actions.setManualTarget(shown, 1500),
    );
    expect(ack.floorKcal, 1750);
    expect(ack.impliedKgPerWeek, closeTo((1500 - 2712.5) * 7 / 7700, 1e-9));
    expect(ack.warnings, {
      TargetWarning.manualBelowFloor,
      TargetWarning.manualLossRateExceeded,
    });

    final done = await h.actions.setManualTarget(
      shown,
      1500,
      acknowledged: true,
    ) as TargetsDone;
    expect(done.kind, TargetsChangeKind.targetsUpdated);
    expect(done.recomputedKcal, isNull);
    final version = await h.currentVersion();
    expect(
      (version.baseKcal, version.manual, version.acknowledged, version.mode),
      (1500.0, true, true, TargetMode.fixed),
    );
    expect(version.mayStayBelowFloor, isTrue);
  });

  test('SF-011 SF-012 a manual target implying more than 1%/week loss needs '
      'acknowledgement; above the floor the mode is kept and nothing is '
      'stored as acknowledged', () async {
    final h = TargetsAppHarness();
    await h.setUp();
    final shown = await h.shownVersion();
    // 1,800 ≥ the 1,750 floor, but (1,800 − 2,712.5) × 7 / 7,700 < −0.8.
    final ack = await h.expectNoWrite<TargetsNeedsAcknowledgement>(
      () => h.actions.setManualTarget(shown, 1800),
    );
    expect(ack.warnings, {TargetWarning.manualLossRateExceeded});
    final done = await h.actions.setManualTarget(
      shown,
      1800,
      acknowledged: true,
    ) as TargetsDone;
    expect(done.warnings, {TargetWarning.manualLossRateExceeded});
    final version = await h.currentVersion();
    expect(
      (version.manual, version.acknowledged, version.mode),
      (true, false, TargetMode.weekly),
    );
    // Within the limits: manual, not acknowledged (even if passed).
    await h.actions.setManualTarget(
      await h.shownVersion(),
      2300,
      acknowledged: true,
    );
    final within = await h.currentVersion();
    expect(
      (within.manual, within.acknowledged, within.baseKcal),
      (true, false, 2300.0),
    );
  });

  test('SF-012 a rate-only acknowledgement is not stored: when the floor '
      'later rises above the manual value it is shown raised and flagged '
      'manualNeedsReview, never silently', () async {
    final h = TargetsAppHarness();
    // Female, 170 cm, 80 kg, high activity: floor 1,521.5, expenditure
    // 2,624.6; 1,600 is above the floor but implies −0.93 kg a week.
    await h.setUp(
      setupInput(
        sex: FormulaSex.female,
        height: Length.centimeters(170),
        activity: ActivityLevel.high,
      ),
    );
    final ack = await h.expectNoWrite<TargetsNeedsAcknowledgement>(
      () async => await h.actions.setManualTarget(await h.shownVersion(), 1600),
    );
    expect(ack.floorKcal, closeTo(1521.5, 1e-9));
    expect(ack.warnings, {TargetWarning.manualLossRateExceeded});
    await h.actions.setManualTarget(
      await h.shownVersion(),
      1600,
      acknowledged: true,
    );
    expect((await h.currentVersion()).acknowledged, isFalse);
    await h.actions.setMode(await h.shownVersion(), TargetMode.fixed);
    final saved = await h.actions.saveProfile(
      const ProfilePatch(sex: FormulaSex.male),
      1,
    ) as TargetsDone;
    expect(saved.recomputedKcal, isNull);
    final version = await h.currentVersion();
    expect(
      (version.baseKcal, version.manual, version.acknowledged, version.mode),
      (1600.0, true, false, TargetMode.fixed),
    );
    final data = await h.data();
    final day = TargetsTimeline.day(
      date: today,
      settings: [for (final s in data.settings) s.value],
      profile: data.profile!.value,
      goals: [for (final g in data.phases) g.value],
    )!;
    // Male: the floor is now 1,687.5, above the unacknowledged 1,600.
    expect(day.floorKcal, closeTo(1687.5, 1e-9));
    expect(day.day.kcal, closeTo(1687.5, 1e-9));
    expect(day.raisedToFloor, isTrue);
    expect(day.issues, {TargetIssue.manualNeedsReview});
  });

  test('PA7 SF-012 switching an acknowledged below-floor manual target to '
      'weekly budget is refused, nothing written (also rebalancing and '
      'shifting)', () async {
    final h = TargetsAppHarness();
    await h.setUp();
    await h.actions.setManualTarget(
      await h.shownVersion(),
      1500,
      acknowledged: true,
    );
    final shown = await h.shownVersion();
    for (final command in [
      () => h.actions.setMode(shown, TargetMode.weekly),
      () => h.actions.setRebalancing(shown, false),
      () => h.actions.setShifting(shown, {DayOfWeek.friday: 1.3}),
    ]) {
      expect(
        (await h.expectNoWrite<TargetsFailed>(command)).reason,
        TargetsFailure.fixedBelowFloor,
      );
    }
    await h.expectNoWrite<TargetsUnchanged>(
      () => h.actions.setMode(shown, TargetMode.fixed),
    );
    // Macros don't depend on the weekly budget.
    expect(
      await h.actions.setMacros(shown, MacroSettings(fiberGrams: 25)),
      isA<TargetsDone>(),
    );
    // Back on the calculated target, weekly is allowed again.
    await h.actions.useCalculatedTarget(await h.shownVersion());
    expect(
      await h.actions.setMode(await h.shownVersion(), TargetMode.weekly),
      isA<TargetsDone>(),
    );
  });

  test('TG-021 useCalculatedTarget restores the generated base', () async {
    final h = TargetsAppHarness();
    await h.setUp();
    await h.expectNoWrite<TargetsUnchanged>(
      () async => await h.actions.useCalculatedTarget(await h.shownVersion()),
    );
    await h.actions.setManualTarget(await h.shownVersion(), 2300);
    final done = await h.actions.useCalculatedTarget(
      await h.shownVersion(),
    ) as TargetsDone;
    expect(done.recomputedKcal, setupBase);
    final version = await h.currentVersion();
    expect(
      (version.baseKcal, version.manual, version.acknowledged),
      (setupBase, false, false),
    );
  });

  test('UX-030 every command records one undo entry; Pending while one is in '
      'flight', () async {
    final h = TargetsAppHarness();
    await h.setUp();
    final pending = Completer<void>();
    h.applyHook = (changes) async {
      await pending.future;
      return await h.applier.apply(changes);
    };
    final shown = await h.shownVersion();
    final first = h.actions.setMode(shown, TargetMode.fixed);
    expect(await h.actions.setRebalancing(shown, false), isA<TargetsPending>());
    expect(await h.actions.completeSetup(setupInput()), isA<TargetsPending>());
    pending.complete();
    expect(await first, isA<TargetsDone>());
    h.applyHook = null;

    final commands = <Future<TargetsOutcome> Function()>[
      () async => await h.actions.setRebalancing(await h.shownVersion(), false),
      () async => await h.actions.setShifting(await h.shownVersion(), {
        DayOfWeek.monday: 1.15,
      }),
      () async => await h.actions.setMacros(
        await h.shownVersion(),
        MacroSettings(caloriesProteinOnly: true),
      ),
      () async => await h.actions.setManualTarget(await h.shownVersion(), 2400),
      () async => await h.actions.useCalculatedTarget(await h.shownVersion()),
      () async => await h.actions.saveProfile(
        const ProfilePatch(heightCm: 181),
        (await h.data()).profile!.version,
      ),
      () async {
        final phase = (await h.phases()).single;
        return await h.actions.renamePhase(
          VersionedId(phase.value.id, phase.version),
          'Cut',
        );
      },
      () async => await h.actions.startPhase(GoalInput.maintain()),
    ];
    for (final command in commands) {
      final previous = h.undo.latest;
      final before = await h.state();
      final done = await command() as TargetsDone;
      expect(previous?.id, isNot(done.undoEntryId));
      expect(h.undo.latest!.id, done.undoEntryId);
      expect(h.undo.latest!.label.key, done.kind.name);
      // Each undo restores the exact prior state.
      expect(await h.undo.undo(done.undoEntryId), UndoOutcome.undone);
      expect(await h.state(), before);
      expect(await command(), isA<TargetsDone>());
    }
  });

  test('D11 rejections map to typed failures and engine refusals never '
      'crash', () async {
    final h = TargetsAppHarness();
    await h.setUp();
    final shown = await h.shownVersion();
    for (final (failure, reason) in <(ChangeFailure, TargetsFailure)>[
      (
        VersionConflict(
          entity: 'targetSettings',
          id: shown.id,
          expected: 1,
          actual: 2,
        ),
        TargetsFailure.changed,
      ),
      (
        RowNotFound(entity: 'targetSettings', id: shown.id),
        TargetsFailure.removed,
      ),
      (const InvalidOp('phaseOverlap'), TargetsFailure.changed),
      (const InvalidOp('duplicateDate'), TargetsFailure.changed),
      (const InvalidOp('invalid'), TargetsFailure.invalid),
    ]) {
      h.applyHook = (_) async => Rejected(failure);
      expect(
        ((await h.actions.setMode(
          shown,
          TargetMode.fixed,
        )) as TargetsFailed).reason,
        reason,
      );
      h.applyHook = (_) async => throw ChangeRejected(failure);
      expect(
        ((await h.actions.setMode(
          shown,
          TargetMode.fixed,
        )) as TargetsFailed).reason,
        reason,
      );
    }
    h.applyHook = null;

    // A profile that can't be evaluated on the date (born after it) is an
    // invalid input, not a crash.
    final fresh = TargetsAppHarness();
    final failed = await fresh.expectNoWrite<TargetsFailed>(
      () => fresh.actions.completeSetup(setupInput(birthYear: 2030)),
    );
    expect(failed.reason, TargetsFailure.invalid);
  });

  test('PA3 an implausible synced basis weight is unusable: limit checks '
      'and recalculation refuse, a profile save applies without a '
      'recompute, nothing throws', () async {
    final h = TargetsAppHarness();
    await h.setUp();
    final id = (await h.currentVersion()).id;
    await h.apply([
      ScriptOp.rows([
        UpdateRow(
          h.db.targetSettingsRows,
          id,
          const TargetSettingsRowsCompanion(basisWeightKg: Value(100000)),
        ),
      ]),
    ]);
    for (final command in <Future<TargetsOutcome> Function()>[
      () async => await h.actions.setManualTarget(await h.shownVersion(), 2000),
      () async => await h.actions.recalculate(await h.shownVersion()),
    ]) {
      expect(
        (await h.expectNoWrite<TargetsFailed>(command)).reason,
        TargetsFailure.invalid,
      );
    }
    final saved = await h.actions.saveProfile(
      const ProfilePatch(activity: ActivityLevel.high),
      1,
    ) as TargetsDone;
    expect(saved.recomputedKcal, isNull);
    // A usable trend weight makes the commands work again.
    h.trend = 80;
    expect(
      await h.actions.recalculate(await h.shownVersion()),
      isA<TargetsDone>(),
    );
  });

  test('notSetUp: revise commands before setup write nothing', () async {
    final h = TargetsAppHarness();
    final id = VersionedId(h.ids.next(), 1);
    for (final command in <Future<TargetsOutcome> Function()>[
      () => h.actions.setMode(id, TargetMode.fixed),
      () => h.actions.recalculate(id),
      () => h.actions.setManualTarget(id, 2000),
      () => h.actions.startPhase(GoalInput.maintain()),
    ]) {
      expect(
        (await h.expectNoWrite<TargetsFailed>(command)).reason,
        TargetsFailure.notSetUp,
      );
    }
    expect(
      (await h.expectNoWrite<TargetsFailed>(
        () => h.actions.saveProfile(const ProfilePatch(heightCm: 170), 1),
      )).reason,
      TargetsFailure.removed,
    );
    expect(
      (await h.expectNoWrite<TargetsFailed>(
        () => h.actions.renamePhase(id, 'Cut'),
      )).reason,
      TargetsFailure.removed,
    );
  });

  test('PA14 toString of the targets inputs, patches, previews and outcomes '
      'shows no body values, names, weights or kcal', () {
    final input = setupInput(goalName: 'Secret plan', weight: 81.7);
    final texts = [
      input,
      input.goal,
      input.preferences,
      const ProfilePatch(heightCm: 177.7, birthYear: 1977),
      SetupPreview.of(input, today),
      GoalPhases(const []),
      const TargetsDone(
        'id',
        TargetsChangeKind.targetsSet,
        recomputedKcal: 2162.5,
      ),
    ].map((o) => o.toString());
    for (final text in texts) {
      for (final secret in ['81.7', '177', '1977', 'Secret', '2162', '180']) {
        expect(text, isNot(contains(secret)), reason: text);
      }
    }
  });
}
