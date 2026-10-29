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
import 'package:fb_mobile/features/body/data/weigh_in_op_handler.dart';
import 'package:fb_mobile/features/body/data/weigh_in_repository.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import '../../../core/changes/support/test_db.dart' show ScriptHandler;
import '../../../core/db/support/db_support.dart';
import '../../diary/support/diary_fixtures.dart' show fixtureId;

export 'package:fb_mobile/core/changes/row_ops.dart';

export '../../../core/changes/support/test_db.dart' show ScriptOp;
export '../../diary/support/diary_fixtures.dart' show fixtureId;

/// When the harness applies change sets: 2026-10-17 12:00 UTC.
final DateTime harnessNow = DateTime.utc(2026, 10, 17, 12);

/// The harness's day.
final LocalDate day17 = LocalDate(2026, 10, 17);

/// [value] [unit] measured on [date] at [hour]:[minute] local time (UTC+03:00).
WeighInDraft weighInDraft(
  double value, {
  LocalDate? date,
  int hour = 7,
  int minute = 0,
  MassUnit unit = MassUnit.kilogram,
  String? note,
}) => WeighInDraft(
  time: EntryTime.local(
    LocalDateTime(date ?? day17, hour: hour, minute: minute),
    180,
  ),
  input: WeighInInput(value, unit),
  note: note,
);

/// [draft] as stored weigh-in `fixtureId(n)` (no database), for pure tests.
WeighIn storedWeighIn(
  int n,
  WeighInDraft draft, {
  int version = 1,
  bool preferred = false,
}) => WeighIn(
  id: fixtureId(n),
  version: version,
  time: draft.time,
  localDate: draft.localDate,
  kg: draft.kg,
  input: draft.input,
  note: draft.note,
  preferredForDay: preferred,
);

/// The real applier with the weigh-in handler (and the script handler for
/// raw fixture rows), over an in-memory database.
final class WeighInHarness {
  new() {
    addTearDown(bus.close);
    applier = ChangeSetApplier(
      db: db,
      tables: db.syncedTables,
      handlers: (db) => [WeighInOpHandler(db), const ScriptHandler()],
      clock: clock,
      ids: SequenceIdGenerator(),
      deviceId: () async => testDevice,
      events: bus,
    );
  }

  /// The profile database.
  final AppDatabase db = memoryDatabase();

  /// The applier's clock, at [harnessNow] in UTC+03:00.
  final ManualClock clock = ManualClock(harnessNow, offsetMinutes: 180);

  /// The event bus the applier emits on.
  final DomainEventBus bus = DomainEventBus();

  /// The applier under test.
  late final ChangeSetApplier<AppDatabase> applier;

  /// The read side.
  WeighInRepository get repository => WeighInRepository(db);

  /// The IDs the app's actions get (apart from `fixtureId(n)` and the
  /// applier's change-set IDs).
  final SequenceIdGenerator ids = SequenceIdGenerator(startMs: 0x0299e3c25b1a);

  /// Provider overrides that put the app's write path (actions, undo stack)
  /// and reads on this harness.
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

  /// Logs [drafts] (ids `fixtureId(1…)`) in one change set.
  Future<void> seed(List<WeighInDraft> drafts) => apply([
    for (final (i, draft) in drafts.indexed)
      CreateWeighIn(fixtureId(i + 1), draft),
  ]);

  /// Row [n] (`fixtureId(n)`), tombstone or not.
  Future<WeighInRow> row(int n) => (db.select(
    db.weighIns,
  )..where((t) => t.id.equals(fixtureId(n)))).getSingle();

  /// The live weigh-ins.
  Future<List<WeighIn>> live() => repository.watchLive().first;

  /// The live weigh-ins of [date] at their versions, for ChooseTrendWeighIn.
  Future<List<VersionedId>> dayIds(LocalDate date) async => [
    for (final w in await live())
      if (w.localDate == date) w.versionedId,
  ];

  /// Every persisted row (all tables the applier touches), for "nothing
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

  /// The live content of every synced table without sync metadata: the
  /// exact user-visible state, for undo checks.
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
