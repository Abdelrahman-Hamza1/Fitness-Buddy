import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/features/targets/data/target_mappers.dart';
import 'package:flutter_test/flutter_test.dart';

import 'targets_harness.dart';

void main() {
  test('TG-001 PutProfile creates profile:self, origin direct; undo '
      'tombstones it; a second create revives it (UpsertRow only after the '
      'absent/tombstoned check)', () async {
    final h = TargetsHarness();
    final created = await h.apply([PutProfile(profile)]);
    final row = await h.db.select(h.db.profiles).getSingle();
    expect(row.id, profileRowId);
    expect(row.id, isNot(fixtureId(1)));
    expect((row.origin, row.version, row.deletedAt), ('direct', 1, null));
    expect(profileOf(row), profile);
    expect(await h.outbox(), [('profile', profileRowId, false)]);
    expect(created.events, contains(TargetsChanged({TargetsPart.profile})));

    await h.undo(created);
    final tombstone = await h.db.select(h.db.profiles).getSingle();
    expect(tombstone.deletedAt, isNotNull);
    expect((await h.outbox()).last, ('profile', profileRowId, true));

    // Absent again for the handler: a create revives the same row.
    final beforeRevive = await h.state();
    final revived = await h.apply([
      PutProfile(profile.copyWith(heightCm: 170)),
    ]);
    final live = await h.db.select(h.db.profiles).getSingle();
    expect(live.deletedAt, isNull);
    expect(live.heightCm, 170);
    expect(live.version, tombstone.version + 1);
    // Undoing the revival restores the tombstone exactly.
    await h.undo(revived);
    expect(await h.state(), beforeRevive);
  });

  test('PutProfile create over a live row → VersionConflict; stale expected '
      'version → VersionConflict; nothing written (rows and outbox)', () async {
    final h = TargetsHarness();
    await h.apply([PutProfile(profile)]);
    expect(
      await h.reject([PutProfile(profile.copyWith(heightCm: 170))]),
      VersionConflict(
        entity: 'profile',
        id: profileRowId,
        expected: 0,
        actual: 1,
      ),
    );
    await h.apply([
      PutProfile(profile.copyWith(heightCm: 171), expectedVersion: 1),
    ]);
    expect(
      await h.reject([
        PutProfile(profile.copyWith(heightCm: 172), expectedVersion: 1),
      ]),
      VersionConflict(
        entity: 'profile',
        id: profileRowId,
        expected: 1,
        actual: 2,
      ),
    );
    // A revision needs a live row.
    final empty = TargetsHarness();
    expect(
      await empty.reject([PutProfile(profile, expectedVersion: 1)]),
      RowNotFound(entity: 'profile', id: profileRowId),
    );
  });

  test('PA9 PutGoalPhase and PutTargetSettings create with InsertRow (a '
      'duplicate id fails) and revise with UpdateRow at the expected '
      'version', () async {
    final h = TargetsHarness();
    await h.apply([PutGoalPhase(phase(1, 0)), PutTargetSettings(version(2))]);
    expect(await h.outbox(), [
      ('goalPhase', fixtureId(1), false),
      ('targetSettings', fixtureId(2), false),
    ]);
    // A duplicate ID is an insert failure, even with other content.
    expect(
      await h.reject([PutGoalPhase(phase(1, 5))]),
      const ConstraintViolation('duplicateId'),
    );
    expect(
      await h.reject([PutTargetSettings(version(2, from: 3))]),
      const ConstraintViolation('duplicateId'),
    );
    // A revision updates the row in place at the expected version.
    await h.apply([
      PutGoalPhase(
        phase(1, 0, revision: 2).withName('Cut'),
        expectedVersion: 1,
      ),
      PutTargetSettings(
        version(2, base: 1900).copyWith(revision: 2),
        expectedVersion: 1,
      ),
    ]);
    final goal = await h.db.select(h.db.goalPhases).getSingle();
    expect((goal.version, goal.revision, goal.name), (2, 2, 'Cut'));
    final settings = await h.db.select(h.db.targetSettingsRows).getSingle();
    expect((settings.version, settings.baseKcal), (2, 1900));
    expect(
      await h.reject([
        PutGoalPhase(phase(1, 0, revision: 3), expectedVersion: 1),
      ]),
      VersionConflict(
        entity: 'goalPhase',
        id: fixtureId(1),
        expected: 1,
        actual: 2,
      ),
    );
    expect(
      await h.reject([PutTargetSettings(version(9), expectedVersion: 1)]),
      RowNotFound(entity: 'targetSettings', id: fixtureId(9)),
    );
    expect(
      await h.reject([PutGoalPhase(phase(9, 0), expectedVersion: 1)]),
      RowNotFound(entity: 'goalPhase', id: fixtureId(9)),
    );
  });

  test('TG-012 a phase write that creates a new overlap → phaseOverlap, '
      'nothing written', () async {
    final h = TargetsHarness();
    await h.apply([PutGoalPhase(phase(1, -30, end: -1))]);
    expect(
      await h.reject([PutGoalPhase(phase(2, -5))]),
      const InvalidOp('phaseOverlap'),
    );
    // Extending a closed phase into a later one overlaps too.
    await h.apply([PutGoalPhase(phase(2, 0))]);
    expect(
      await h.reject([PutGoalPhase(phase(1, -30, end: 3), expectedVersion: 1)]),
      const InvalidOp('phaseOverlap'),
    );
    // Back to back is fine.
    await h.apply([PutGoalPhase(phase(1, -30, end: -2), expectedVersion: 1)]);
  });

  test('an existing synced overlap still allows renaming one of its phases '
      'and startPhase', () async {
    final h = TargetsHarness();
    final a = phase(1, -30);
    final b = phase(2, -10);
    await h.synced([
      InsertRow(h.db.goalPhases, goalPhaseColumns(a)),
      InsertRow(h.db.goalPhases, goalPhaseColumns(b)),
    ]);
    await h.apply([PutGoalPhase(a.withName('Winter'), expectedVersion: 1)]);
    // startPhase: end every live phase covering today at yesterday, then
    // start the new one today. The (a, b) overlap remains, nothing new.
    await h.apply([
      PutGoalPhase(
        a.withName('Winter').withEnd(today.plusDays(-1)),
        expectedVersion: 2,
      ),
      PutGoalPhase(b.withEnd(today.plusDays(-1)), expectedVersion: 1),
      PutGoalPhase(phase(3, 0)),
    ]);
    final live = await h.db.select(h.db.goalPhases).get();
    expect(live, hasLength(3));
    // But a new overlap with the new phase is still refused.
    expect(
      await h.reject([PutGoalPhase(phase(4, 5))]),
      const InvalidOp('phaseOverlap'),
    );
  });

  test('an existing synced duplicate-date pair still allows '
      'TargetSettingsRevision.next; adding a third same-date row is '
      'rejected', () async {
    final h = TargetsHarness();
    await h.synced([
      InsertRow(h.db.targetSettingsRows, targetSettingsColumns(version(1))),
      InsertRow(
        h.db.targetSettingsRows,
        targetSettingsColumns(version(2, base: 2100)),
      ),
    ]);
    final current = TargetsTimeline.versionOn([
      version(1),
      version(2, base: 2100),
    ], today)!;
    expect(current.id, fixtureId(2));
    final next = TargetSettingsRevision.next(
      current: current,
      currentVersion: 1,
      today: today,
      newId: fixtureId(3),
      change: (r) => r.copyWith(rebalancing: false),
    );
    await h.apply([
      PutTargetSettings(next.record, expectedVersion: next.expectedVersion),
    ]);
    final revised = await (h.db.select(
      h.db.targetSettingsRows,
    )..where((t) => t.id.equals(fixtureId(2)))).getSingle();
    expect((revised.revision, revised.rebalancing), (2, false));
    expect(
      await h.reject([PutTargetSettings(version(3))]),
      const InvalidOp('duplicateDate'),
    );
    // Another date is fine.
    await h.apply([PutTargetSettings(version(3, from: 1))]);
  });

  test("PA6 a stored out-of-range height (synced) doesn't block an activity "
      'edit; changing the height to an out-of-range value is '
      'rejected', () async {
    final h = TargetsHarness();
    final tall = profile.copyWith(heightCm: 300);
    await h.synced([UpsertRow(h.db.profiles, profileColumns(tall))]);
    await h.apply([
      PutProfile(
        tall.copyWith(activity: ActivityLevel.high),
        expectedVersion: 1,
      ),
    ]);
    expect(
      await h.reject([
        PutProfile(
          tall.copyWith(activity: ActivityLevel.high, heightCm: 260),
          expectedVersion: 2,
        ),
      ]),
      const InvalidOp('invalid'),
    );
    // A new row is checked in full.
    expect(
      await TargetsHarness().reject([PutProfile(tall)]),
      const InvalidOp('invalid'),
    );
  });

  test('SF-012 a newly acknowledged manual value is rejected unless the '
      'origin is direct; a proposal may keep an existing acknowledgement but '
      'not move it to another value', () async {
    final h = TargetsHarness();
    final acknowledged = version(
      1,
      base: 1000,
    ).copyWith(manual: true, acknowledged: true, mode: TargetMode.fixed);
    final proposal = Origin.proposal(fixtureId(99));
    Future<ApplyResult> propose(TargetsOp op) =>
        h.applier.apply(ChangeSet([op], origin: proposal));

    final before = await h.raw();
    expect(
      (await propose(PutTargetSettings(acknowledged)) as Rejected).failure,
      const InvalidOp('acknowledgement'),
    );
    expect(await h.raw(), before);
    await h.apply([PutTargetSettings(acknowledged)]);

    // Keeping the acknowledged value (a macro change) is fine.
    expect(
      await propose(
        PutTargetSettings(
          acknowledged.copyWith(
            revision: 2,
            macros: MacroSettings(fiberGrams: 30),
          ),
          expectedVersion: 1,
        ),
      ),
      isA<Applied>(),
    );
    // Acknowledging a different value is the user's call only.
    final moved = acknowledged.copyWith(revision: 3, baseKcal: 900);
    final kept = await h.raw();
    expect(
      (await propose(
        PutTargetSettings(moved, expectedVersion: 2),
      ) as Rejected).failure,
      const InvalidOp('acknowledgement'),
    );
    expect(await h.raw(), kept);
    await h.apply([PutTargetSettings(moved, expectedVersion: 2)]);
  });

  test('D15 the wire rules always apply and the input rules apply to new '
      'rows; an identical put writes nothing', () async {
    final h = TargetsHarness();
    // Wire: acknowledged without manual; maintain not weekly 0.
    expect(
      await h.reject([
        PutTargetSettings(version(1).copyWith(acknowledged: true)),
      ]),
      const InvalidOp('invalid'),
    );
    expect(
      await h.reject([
        PutGoalPhase(
          GoalPhaseRecord(
            id: fixtureId(2),
            revision: 1,
            start: today,
            type: GoalType.maintain,
            expression: GoalExpression.weekly(-.5),
            weightInputUnit: MassUnit.kilogram,
          ),
        ),
      ]),
      const InvalidOp('invalid'),
    );
    expect(
      await h.reject([PutProfile(profile.copyWith(birthYear: 0))]),
      const InvalidOp('invalid'),
    );
    // Input: a manual target below 500 kcal, a 3 kg/week rate.
    expect(
      await h.reject([
        PutTargetSettings(version(1, base: 400).copyWith(manual: true)),
      ]),
      const InvalidOp('invalid'),
    );
    expect(
      await h.reject([
        PutGoalPhase(
          phase(2, 0).copyWith(expression: GoalExpression.weekly(-3)),
        ),
      ]),
      const InvalidOp('invalid'),
    );
    // Identical puts are no-ops: no version bump, no outbox row, no event.
    final applied = await h.apply([
      PutProfile(profile),
      PutGoalPhase(phase(2, 0)),
      PutTargetSettings(version(1)),
    ]);
    expect(applied.events.whereType<TargetsChanged>().map((e) => e.parts), [
      {TargetsPart.profile},
      {TargetsPart.goals},
      {TargetsPart.settings},
    ]);
    final before = await h.raw();
    final same = await h.apply([
      PutProfile(profile, expectedVersion: 1),
      PutGoalPhase(phase(2, 0), expectedVersion: 1),
      PutTargetSettings(version(1), expectedVersion: 1),
    ]);
    expect(await h.raw(), before);
    expect(same.events.whereType<TargetsChanged>(), isEmpty);
  });

  test('every targets op and its undo restore the exact prior state, outbox '
      'included (A01 D3 comparison)', () async {
    final h = TargetsHarness();
    // Creates: undo tombstones the new rows, live state as before.
    final empty = await h.state(liveOnly: true);
    final created = await h.apply([
      PutProfile(profile),
      PutGoalPhase(phase(1, 0)),
      PutTargetSettings(version(2)),
    ]);
    final createdOutbox = await h.outbox();
    expect(createdOutbox, hasLength(3));
    final undoCreate = await h.undo(created);
    expect(await h.state(liveOnly: true), empty);
    expect((await h.outbox()).skip(3).toSet(), {
      ('profile', profileRowId, true),
      ('goalPhase', fixtureId(1), true),
      ('targetSettings', fixtureId(2), true),
    });
    expect(
      undoCreate.events.whereType<TargetsChanged>().map((e) => e.parts).toSet(),
      {
        {TargetsPart.profile},
        {TargetsPart.goals},
        {TargetsPart.settings},
      },
    );

    // Revisions: undo restores every column exactly, tombstones included.
    await h.apply([
      PutProfile(profile),
      PutGoalPhase(phase(3, 0)),
      PutTargetSettings(version(4)),
    ]);
    final before = await h.state();
    final outboxBefore = (await h.outbox()).length;
    final revised = await h.apply([
      PutProfile(
        profile.copyWith(activity: ActivityLevel.high),
        expectedVersion: 3,
      ),
      PutGoalPhase(
        phase(3, 0).withName('Cut').withEnd(today.plusDays(9)),
        expectedVersion: 1,
      ),
      PutTargetSettings(
        version(4).copyWith(
          revision: 2,
          mode: TargetMode.fixed,
          shifts: {DayOfWeek.friday: 1.3},
          macros: MacroSettings(protein: MacroOverride.percent(30)),
        ),
        expectedVersion: 1,
      ),
    ]);
    expect(await h.state(), isNot(before));
    await h.undo(revised);
    expect(await h.state(), before);
    // Each write and each undo is captured for sync.
    expect((await h.outbox()).length, outboxBefore + 6);
  });

  test('a change set mixing settings and targets ops is atomic: a rejected '
      'targets op leaves settings unchanged', () async {
    final h = TargetsHarness();
    await h.apply([PutGoalPhase(phase(1, -10))]);
    expect(
      await h.reject([
        SettingsOp.put('units.system', '"imperial"'),
        PutProfile(profile),
        PutGoalPhase(phase(2, 0)),
      ]),
      const InvalidOp('phaseOverlap'),
    );
    expect(await h.db.select(h.db.settingsKv).get(), isEmpty);
    expect(await h.db.select(h.db.profiles).get(), isEmpty);
  });
}
