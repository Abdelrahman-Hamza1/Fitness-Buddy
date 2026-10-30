import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/targets/data/target_mappers.dart';
import 'package:fb_mobile/features/targets/data/targets_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'targets_harness.dart';

void main() {
  test('repository: latest row per id, tombstones excluded, versions '
      'exposed', () async {
    final h = TargetsHarness();
    final repo = TargetsRepository(h.db);
    expect(await repo.read(), TargetsData());
    await h.apply([
      PutProfile(profile),
      PutGoalPhase(phase(2, -10, end: -1)),
      PutGoalPhase(phase(1, 0)),
      PutTargetSettings(version(3)),
    ]);
    final removed = await h.apply([PutTargetSettings(version(4, from: 1))]);
    await h.apply([
      PutProfile(profile.copyWith(heightCm: 168), expectedVersion: 1),
      PutGoalPhase(phase(1, 0).withName('Cut'), expectedVersion: 1),
    ]);
    await h.undo(removed);
    final data = await repo.read();
    expect(data.profile, Versioned(profile.copyWith(heightCm: 168), 2));
    expect(data.phases, [
      Versioned(phase(1, 0).withName('Cut'), 2),
      Versioned(phase(2, -10, end: -1), 1),
    ]);
    expect(data.settings, [Versioned(version(3), 1)]);
    expect(data.skippedRows, 0);
    expect(data.profileUnreadable, isFalse);
    expect(data.phases.clear, throwsUnsupportedError);
    expect(data.hashCode, (await repo.read()).hashCode);
    expect(
      '$data',
      'TargetsData(profile: true, 2 phases, 1 versions, 0 skipped)',
    );
    expect('${data.profile}', 'Versioned(v2)');
    // A tombstoned profile reads as absent.
    final emptied = TargetsHarness();
    await emptied.undo(await emptied.apply([PutProfile(profile)]));
    expect((await TargetsRepository(emptied.db).read()).profile, isNull);
  });

  test('tolerant decode: an unknown enum or broken pair in a synced row '
      'skips that row and counts it; an out-of-range shift weight reads as '
      '1.0; no exception, no values logged', () async {
    final h = TargetsHarness();
    await h.synced([
      UpsertRow(
        h.db.profiles,
        profileColumns(profile).copyWith(sex: const Value('average')),
      ),
      InsertRow(
        h.db.goalPhases,
        goalPhaseColumns(phase(1, 0)).copyWith(goalType: const Value('cut')),
      ),
      // A weekly expression with a stray target weight.
      InsertRow(
        h.db.goalPhases,
        goalPhaseColumns(phase(2, -20, end: -1))
            .copyWith(targetKg: const Value(60)),
      ),
      InsertRow(h.db.goalPhases, goalPhaseColumns(phase(3, -40, end: -21))),
      // A macro value without its unit flag.
      InsertRow(
        h.db.targetSettingsRows,
        targetSettingsColumns(version(4))
            .copyWith(proteinValue: const Value(120)),
      ),
      // Shift weights: wire-invalid (negative) and unusable (5,000).
      InsertRow(
        h.db.targetSettingsRows,
        targetSettingsColumns(version(5, from: -7)).copyWith(
          shiftFri: const Value(-1.3),
          shiftSat: const Value(5000),
          shiftSun: const Value(1.3),
        ),
      ),
    ]);
    final data = await TargetsRepository(h.db).read();
    expect(data.profile, isNull);
    // A13a security #3: the skipped live profile is reported, so setup
    // never runs over it.
    expect(data.profileUnreadable, isTrue);
    expect('$data', endsWith('4 skipped, profile unreadable)'));
    expect(data.phases.map((p) => p.value.id), [fixtureId(3)]);
    expect(data.settings.map((s) => s.value.id), [fixtureId(5)]);
    expect(data.skippedRows, 4);
    final shifted = data.settings.single.value;
    expect(shifted.shifts, {DayOfWeek.saturday: 5000.0, DayOfWeek.sunday: 1.3});
    expect(shifted.weights, {DayOfWeek.sunday: 1.3});
    expect(shifted.toPlan(1500).weights, {DayOfWeek.sunday: 1.3});
  });

  test('watchTargets emits the current rows and again after a change; the '
      'part streams follow', () async {
    final h = TargetsHarness();
    final repo = TargetsRepository(h.db);
    final all = <TargetsData>[];
    final profiles = <Versioned<ProfileRecord>?>[];
    final phases = <List<Versioned<GoalPhaseRecord>>>[];
    final settings = <List<Versioned<TargetSettingsRecord>>>[];
    final subs = [
      repo.watchTargets().listen(all.add),
      repo.watchProfile().listen(profiles.add),
      repo.watchGoalPhases().listen(phases.add),
      repo.watchTargetSettings().listen(settings.add),
    ];
    addTearDown(() => Future.wait(subs.map((s) => s.cancel())));
    await pumpEventQueue();
    expect(all, [TargetsData()]);
    await h.apply([PutProfile(profile)]);
    await pumpEventQueue();
    await h.apply([PutGoalPhase(phase(1, 0)), PutTargetSettings(version(2))]);
    await pumpEventQueue();
    expect(all.last.phases, hasLength(1));
    expect(profiles, [null, const Versioned(profile, 1)]);
    expect(phases.map((p) => p.length), [0, 1]);
    expect(settings.map((s) => s.length), [0, 1]);
  });
}
