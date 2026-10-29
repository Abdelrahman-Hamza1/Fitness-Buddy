import 'dart:convert';

import 'package:drift/drift.dart' show Variable;

import 'package:fb_domain/fb_domain.dart';
import 'package:fb_domain/testing.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/core/changes/change_set_applier.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/events/domain_event_bus.dart';
import 'package:fb_mobile/features/workouts/workouts.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../core/db/support/db_support.dart';

/// When the harness applies change sets: 2026-10-29 12:00 UTC (UTC+02:00).
final DateTime harnessNow = DateTime.utc(2026, 10, 29, 12);

/// The harness's local day.
final LocalDate today = LocalDate(2026, 10, 29);

/// A deterministic UUID for fixture row [n].
String wid(int n) =>
    '0199e3c2-0000-7000-8000-${n.toRadixString(16).padLeft(12, '0')}';

/// A weight × reps custom exercise draft.
CustomExerciseDraft benchDraft({ExerciseType type = ExerciseType.weightReps}) =>
    CustomExerciseDraft(
      name: 'Cable fly',
      type: type,
      equipment: Equipment.cable,
      aliases: const ['fly'],
    );

/// A weight × reps set [id] of [reps] at [kg].
LoggedSet lifted(int id, int reps, double kg) =>
    LoggedSet(wid(id), SetValues(reps: reps, kg: kg));

/// A session on [date] of custom exercise `wid(1)` with [sets] (exercise
/// row `wid(exerciseRow)`).
WorkoutSessionDraft sessionDraft({
  LocalDate? date,
  List<LoggedSet>? sets,
  int exerciseRow = 20,
  String? name = 'Push',
  String? templateId,
}) => WorkoutSessionDraft(
  date: date ?? today,
  name: name,
  templateId: templateId,
  exercises: [
    SessionExerciseDraft(
      id: wid(exerciseRow),
      exerciseId: wid(1),
      sets: sets ?? [lifted(30, 8, 80), lifted(31, 8, 80), lifted(32, 7, 80)],
    ),
  ],
);

/// The real applier with the workout handler over an in-memory database.
final class WorkoutHarness {
  /// Over [database] (default: a fresh in-memory database without a pack).
  new({AppDatabase? database}) : db = database ?? memoryDatabase() {
    addTearDown(bus.close);
    addTearDown(db.close);
    applier = ChangeSetApplier(
      db: db,
      tables: db.syncedTables,
      handlers: (db) => [WorkoutOpHandler(db)],
      clock: clock,
      ids: SequenceIdGenerator(),
      deviceId: () async => testDevice,
      events: bus,
    );
  }

  /// The profile database.
  final AppDatabase db;

  /// The applier's clock.
  final ManualClock clock = ManualClock(harnessNow, offsetMinutes: 120);

  /// The event bus.
  final DomainEventBus bus = DomainEventBus();

  /// The applier under test.
  late final ChangeSetApplier<AppDatabase> applier;

  /// The read side.
  WorkoutRepository get repository => WorkoutRepository(db);

  /// Applies [ops] and expects success.
  Future<Applied> apply(List<ChangeOp> ops) async {
    final r = await applier.apply(ChangeSet(ops, origin: Origin.direct));
    if (r is! Applied) fail('expected Applied: $r');
    return r;
  }

  /// Applies [ops], expects a rejection and nothing persisted.
  Future<ChangeFailure> reject(List<ChangeOp> ops) async {
    final before = await raw();
    final r = await applier.apply(ChangeSet(ops, origin: Origin.direct));
    expect(await raw(), before, reason: 'a rejection changed persisted state');
    if (r is! Rejected) fail('expected Rejected: $r');
    return r.failure;
  }

  /// Undoes [a] and returns the result.
  Future<ApplyResult> undo(Applied a) => applier.revert(a.inverse);

  /// Creates custom exercise `wid(1)`.
  Future<Applied> seedExercise() =>
      apply([CreateCustomExercise(wid(1), benchDraft())]);

  /// The version of row [id] in [table].
  Future<int> version(String table, String id) async =>
      (await db
              .customSelect(
                'SELECT version FROM $table WHERE id = ?',
                variables: [Variable.withString(id)],
              )
              .getSingle())
          .read<int>('version');

  /// Whether row [id] of [table] is a tombstone.
  Future<bool> isTombstone(String table, String id) async =>
      (await db
              .customSelect(
                'SELECT deleted_at FROM $table WHERE id = ?',
                variables: [Variable.withString(id)],
              )
              .getSingle())
          .read<int?>('deleted_at') !=
      null;

  /// Every persisted row, for "nothing was written" checks.
  Future<String> raw() async => jsonEncode({
    for (final table in [
      ...db.syncedTables.map((t) => t.sqlName),
      'sync_outbox',
    ])
      table: [
        for (final r
            in await db.customSelect('SELECT * FROM $table ORDER BY 1').get())
          r.data,
      ],
  });

  /// The live user-visible content of every synced table, for undo checks.
  Future<String> state() async {
    const meta = {
      'created_at',
      'updated_hlc',
      'version',
      'deleted_at',
      'device_id',
      'origin',
    };
    return jsonEncode({
      for (final table in db.syncedTables.map((t) => t.sqlName))
        table: [
          for (final r
              in await db
                  .customSelect(
                    'SELECT * FROM $table WHERE deleted_at IS NULL ORDER BY id',
                  )
                  .get())
            {
              for (final e in r.data.entries)
                if (!meta.contains(e.key)) e.key: e.value,
            },
        ],
    });
  }
}
