import 'dart:convert';

import 'package:fb_domain/fb_domain.dart';
import 'package:fb_domain/testing.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/core/changes/change_providers.dart';
import 'package:fb_mobile/core/changes/change_set_applier.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/db/db_providers.dart';
import 'package:fb_mobile/core/events/domain_event_bus.dart';
import 'package:fb_mobile/core/ids/id_generator.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/features/body/data/measurement_op_handler.dart';
import 'package:fb_mobile/features/body/data/measurement_repository.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import '../../../core/changes/support/test_db.dart' show ScriptHandler;
import '../../../core/db/support/db_support.dart';
import '../../diary/support/diary_fixtures.dart' show fixtureId;

export 'package:fb_mobile/core/changes/row_ops.dart';

export '../../../core/changes/support/test_db.dart' show ScriptOp;
export '../../diary/support/diary_fixtures.dart' show fixtureId;

/// When the harness applies change sets: 2026-10-17 12:00 UTC.
final DateTime measureNow = DateTime.utc(2026, 10, 17, 12);

/// The harness's day.
final LocalDate measureDay = LocalDate(2026, 10, 17);

/// The built-in waist series.
final MeasurementTypeRef waistRef = MeasurementTypeRef.builtIn(
  MeasurementKind.waist,
);

/// [value] [unit] of [type] (waist by default) on [date] at [hour] local
/// time (UTC+03:00).
MeasurementDraft measureDraft(
  double value, {
  MeasurementTypeRef? type,
  LocalDate? date,
  int hour = 7,
  int minute = 0,
  MeasurementUnit unit = MeasurementUnit.cm,
}) => MeasurementDraft(
  type: type ?? waistRef,
  time: EntryTime.local(
    LocalDateTime(date ?? measureDay, hour: hour, minute: minute),
    180,
  ),
  input: MeasurementInput(value, unit),
);

/// The real applier with the measurement handler (and the script handler
/// for raw fixture rows), over an in-memory database.
final class MeasurementHarness {
  new() {
    addTearDown(bus.close);
    applier = ChangeSetApplier(
      db: db,
      tables: db.syncedTables,
      handlers: (db) => [MeasurementOpHandler(db), const ScriptHandler()],
      clock: clock,
      ids: SequenceIdGenerator(),
      deviceId: () async => testDevice,
      events: bus,
    );
  }

  /// The profile database.
  final AppDatabase db = memoryDatabase();

  /// The applier's clock, at [measureNow] in UTC+03:00.
  final ManualClock clock = ManualClock(measureNow, offsetMinutes: 180);

  /// The event bus the applier emits on.
  final DomainEventBus bus = DomainEventBus();

  /// The applier under test.
  late final ChangeSetApplier<AppDatabase> applier;

  /// The read side.
  MeasurementRepository get repository => MeasurementRepository(db);

  /// The IDs the app's actions get.
  final SequenceIdGenerator ids = SequenceIdGenerator(startMs: 0x0299e3c25b1a);

  /// Provider overrides that put the app's write path and reads on this
  /// harness.
  List<Override> get overrides => [
    appDatabaseProvider.overrideWithValue(db),
    changeSetApplierProvider.overrideWithValue(applier),
    clockProvider.overrideWithValue(clock),
    idGeneratorProvider.overrideWithValue(ids),
  ];

  /// Applies [ops] and expects it to succeed.
  Future<Applied> apply(List<ChangeOp> ops) async {
    final r = await applier.apply(ChangeSet(ops, origin: Origin.direct));
    if (r is! Applied) fail('expected Applied: $r');
    return r;
  }

  /// Applies [ops], expects a rejection and no persisted change at all.
  Future<ChangeFailure> reject(List<ChangeOp> ops) async {
    final before = await raw();
    final r = await applier.apply(ChangeSet(ops, origin: Origin.direct));
    expect(await raw(), before, reason: 'a rejection changed persisted state');
    if (r is! Rejected) fail('expected Rejected: $r');
    return r.failure;
  }

  /// Undoes [a] and expects it to succeed.
  Future<void> undo(Applied a) async {
    expect(await applier.revert(a.inverse), isA<Applied>());
  }

  /// Undoes [a], expects a rejection and no persisted change at all.
  Future<ChangeFailure> undoRejected(Applied a) async {
    final before = await raw();
    final r = await applier.revert(a.inverse);
    expect(await raw(), before, reason: 'a rejected undo changed state');
    if (r is! Rejected) fail('expected Rejected: $r');
    return r.failure;
  }

  /// The live data.
  Future<MeasurementData> live() => repository.read();

  /// Measurement row [id], tombstone or not.
  Future<MeasurementRow> row(String id) =>
      (db.select(db.measurements)..where((t) => t.id.equals(id))).getSingle();

  /// Type row [id], tombstone or not.
  Future<MeasurementTypeRow> typeRow(String id) => (db.select(
    db.measurementTypes,
  )..where((t) => t.id.equals(id))).getSingle();

  /// How many outbox rows there are.
  Future<int> outboxCount() async =>
      (await db
              .customSelect('SELECT COUNT(*) AS n FROM sync_outbox')
              .getSingle())
          .read<int>('n');

  /// Every persisted row (all synced tables, outbox, state), for "nothing
  /// was written" checks.
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

  /// The live content of the measurement tables without sync metadata.
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
      for (final table in ['measurement_types', 'measurements'])
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

/// Fixed IDs for the measurement tests.
String mId(int n) => fixtureId(100 + n);

/// Fixed type IDs.
String tId(int n) => fixtureId(200 + n);
