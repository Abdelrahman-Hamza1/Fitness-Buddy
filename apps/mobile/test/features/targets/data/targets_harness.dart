import 'dart:convert';

import 'package:fb_domain/fb_domain.dart';
import 'package:fb_domain/testing.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/core/changes/change_set_applier.dart';
import 'package:fb_mobile/core/changes/row_ops.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/events/domain_event_bus.dart';
import 'package:fb_mobile/core/settings/settings_op_handler.dart';
import 'package:fb_mobile/features/targets/data/targets_op_handler.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../core/changes/support/test_db.dart'
    show ScriptHandler, ScriptOp;
import '../../../core/db/support/db_support.dart';
import '../../diary/support/diary_fixtures.dart' show fixtureId;

export 'package:fb_mobile/core/changes/row_ops.dart';

export '../../../core/changes/support/test_db.dart' show ScriptOp;
export '../../diary/support/diary_fixtures.dart' show fixtureId;

/// The handler tests' "today": 2026-10-17 (UTC clock, offset 0).
final LocalDate today = LocalDate(2026, 10, 17);

/// A valid profile (age 36 on [today]).
const ProfileRecord profile = ProfileRecord(
  sex: FormulaSex.female,
  birthYear: 1990,
  heightCm: 165,
  heightInputUnit: HeightInputUnit.centimeter,
  activity: ActivityLevel.light,
);

/// Goal phase [n] from [today] + [start] (open unless [end]).
GoalPhaseRecord phase(int n, int start, {int? end, int revision = 1}) =>
    GoalPhaseRecord(
      id: fixtureId(n),
      revision: revision,
      start: today.plusDays(start),
      end: end == null ? null : today.plusDays(end),
      type: GoalType.lose,
      expression: GoalExpression.weekly(-.5),
      weightInputUnit: MassUnit.kilogram,
    );

/// Target settings version [n] effective [today] + [from].
TargetSettingsRecord version(int n, {int from = 0, double base = 2000}) =>
    TargetSettingsRecord(
      id: fixtureId(n),
      revision: 1,
      effectiveFrom: today.plusDays(from),
      baseKcal: base,
      basisWeightKg: 70,
    );

/// The real applier with the settings and targets handlers, plus
/// [ScriptOp] for rows that "arrived by sync" (no targets rules).
final class TargetsHarness {
  new() {
    addTearDown(bus.close);
    applier = ChangeSetApplier(
      db: db,
      tables: db.syncedTables,
      handlers: (db) => [
        SettingsOpHandler(db.settingsKv),
        TargetsOpHandler(db),
        const ScriptHandler(),
      ],
      clock: ManualClock(DateTime.utc(2026, 10, 17, 12)),
      ids: SequenceIdGenerator(),
      deviceId: () async => testDevice,
      events: bus,
    );
  }

  final AppDatabase db = memoryDatabase();
  final DomainEventBus bus = DomainEventBus();
  late final ChangeSetApplier<AppDatabase> applier;

  /// Applies [ops] directly; fails the test unless applied.
  Future<Applied> apply(List<ChangeOp> ops) async {
    final r = await applier.apply(ChangeSet(ops, origin: Origin.direct));
    if (r is! Applied) fail('expected Applied: $r');
    return r;
  }

  /// Applies [ops], expects a rejection and an unchanged database.
  Future<ChangeFailure> reject(List<ChangeOp> ops) async {
    final before = await raw();
    final r = await applier.apply(ChangeSet(ops, origin: Origin.direct));
    expect(await raw(), before, reason: 'rejection changed persisted state');
    if (r is! Rejected) fail('expected Rejected: $r');
    return r.failure;
  }

  /// Undoes [a]; fails the test unless applied.
  Future<Applied> undo(Applied a) async {
    final r = await applier.revert(a.inverse);
    if (r is! Applied) fail('expected the undo to apply: $r');
    return r;
  }

  /// Writes [rows] as if they arrived by sync (no targets rules).
  Future<void> synced(List<RowOp> rows) async {
    await apply([ScriptOp.rows(rows)]);
  }

  /// Every row of every synced table, the outbox and sync state.
  Future<String> raw() async {
    final tables = [
      ...db.syncedTables.map((t) => t.sqlName),
      'sync_outbox',
      'sync_state',
    ];
    return jsonEncode({
      for (final table in tables)
        table: [
          for (final r
              in await db.customSelect('SELECT * FROM $table ORDER BY 1').get())
            r.data,
        ],
    });
  }

  /// The A01 D3 comparison: every row of every synced table, content
  /// columns plus `deleted_at` and `edited_by_user`. [liveOnly] leaves out
  /// tombstones (the undo of a create tombstones the new row).
  Future<String> state({bool liveOnly = false}) async {
    const stamped = {
      'created_at',
      'updated_hlc',
      'version',
      'device_id',
      'origin',
    };
    return jsonEncode({
      for (final table in db.syncedTables.map((t) => t.sqlName))
        table: [
          for (final r
              in await db
                  .customSelect(
                    'SELECT * FROM $table '
                    '${liveOnly ? 'WHERE deleted_at IS NULL ' : ''}ORDER BY id',
                  )
                  .get())
            {
              for (final e in r.data.entries)
                if (!stamped.contains(e.key)) e.key: e.value,
            },
        ],
    });
  }

  /// The outbox as (entity, row id, deleted), in order.
  Future<List<(String, String, bool)>> outbox() async => [
    for (final r in await db.select(db.syncOutbox).get())
      (r.entity, r.rowId, r.deleted),
  ];
}
