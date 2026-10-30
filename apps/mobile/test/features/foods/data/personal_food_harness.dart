import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_domain/testing.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/core/changes/change_set_applier.dart';
import 'package:fb_mobile/core/changes/op_handler.dart';
import 'package:fb_mobile/core/changes/row_ops.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/events/domain_event_bus.dart';
import 'package:fb_mobile/features/diary/data/diary_op_handler.dart';
import 'package:fb_mobile/features/foods/data/personal_food_op_handler.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../core/changes/support/test_db.dart'
    show ScriptHandler, ScriptOp;
import '../../../core/db/support/db_support.dart';
import '../../diary/support/diary_fixtures.dart';
import '../../diary/support/diary_harness.dart' show newEntry, today;

export 'package:fb_mobile/core/changes/row_ops.dart';

export '../../../core/changes/support/test_db.dart' show ScriptOp;
export '../../diary/support/diary_fixtures.dart';
export '../../diary/support/diary_harness.dart' show newEntry, newId, today;

/// Real applier, including both new families; all fixture writes use it too.
final class PersonalHarness {
  new({bool failRelink = false, bool failLog = false}) {
    addTearDown(bus.close);
    applier = ChangeSetApplier(
      db: db,
      tables: db.syncedTables,
      handlers: (db) => [
        RejectRelinkHandler(db, failRelink: failRelink, failLog: failLog),
        PersonalFoodOpHandler(db),
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
  Future<Applied> apply(List<ChangeOp> ops) async {
    final r = await applier.apply(ChangeSet(ops, origin: Origin.direct));
    if (r is! Applied) fail('expected Applied: $r');
    return r;
  }

  Future<ChangeFailure> reject(List<ChangeOp> ops) async {
    final before = await raw();
    final r = await applier.apply(ChangeSet(ops, origin: Origin.direct));
    expect(await raw(), before, reason: 'rejection changed persisted state');
    if (r is! Rejected) fail('expected Rejected');
    return r.failure;
  }

  Future<void> undo(Applied a) async {
    expect(await applier.revert(a.inverse), isA<Applied>());
  }

  Future<void> conflict(Applied a) async {
    final before = await raw();
    final result = await applier.revert(a.inverse);
    expect(
      result,
      isA<Rejected>().having(
        (r) => r.failure,
        'failure',
        isA<VersionConflict>(),
      ),
    );
    expect(await raw(), before);
  }

  Future<void> write(List<RowOp> rows) async {
    await apply([ScriptOp.rows(rows)]);
  }

  Future<PersonalFoodRow> row(int n) => (db.select(
    db.personalFoods,
  )..where((t) => t.id.equals(fixtureId(n)))).getSingle();
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

  Future<void> seed({int entries = 2, int items = 2}) async {
    await apply([
      CreatePersonalFood(fixtureId(1), draft('A')),
      CreatePersonalFood(fixtureId(2), draft('B')),
    ]);
    await apply([
      LogEntries([
        for (var i = 0; i < entries; i++)
          newEntry(10 + i, ref: FoodRef.personal(fixtureId(2))),
      ]),
    ]);
    await apply([
      SaveMeal(
        savedMealId: fixtureId(3),
        name: 'Saved',
        source: MealSource.entries([
          for (var i = 0; i < items; i++) fixtureId(10 + i),
        ]),
        expected: SourceVersions(
          entries: [
            for (var i = 0; i < items; i++) VersionedId(fixtureId(10 + i), 1),
          ],
        ),
      ),
    ]);
  }

  Future<SavedMealVersions> versions() async => SavedMealVersions(
    meal: VersionedId(
      fixtureId(3),
      (await (db.select(
        db.savedMeals,
      )..where((t) => t.id.equals(fixtureId(3)))).getSingle()).version,
    ),
    items: [
      for (final item in await liveItems()) VersionedId(item.id, item.version),
    ],
  );
  Future<List<SavedMealItemRow>> liveItems() =>
      (db.select(db.savedMealItems)
            ..where((t) => t.deletedAt.isNull())
            ..orderBy([(t) => OrderingTerm(expression: t.sortOrder)]))
          .get();
  LogSavedMeal log(SavedMealVersions v, {EntryWhen? when, String? slotId}) =>
      LogSavedMeal(
        expected: v,
        entryIds: {
          for (final (i, item) in v.items.indexed) item.id: fixtureId(2000 + i),
        },
        when: when ?? EntryWhen.onDay(today),
        slotId: slotId ?? DefaultSlots.all.first.id,
      );
  List<ChangeOp> merge({int av = 1, int bv = 1}) => [
    MergePersonalFoods(
      survivor: VersionedId(fixtureId(1), av),
      merged: VersionedId(fixtureId(2), bv),
    ),
    RelinkFoodRefs(
      from: FoodRef.personal(fixtureId(2)),
      to: FoodRef.personal(fixtureId(1)),
    ),
  ];
}

/// Valid, deterministic definitions; numbers differ from diary snapshots.
PersonalFoodDraft draft(
  String name, {
  NutrientBasis basis = NutrientBasis.per100g,
  List<String> aliases = const [],
  List<String> barcodes = const [],
  List<PersonalFoodServing> servings = const [],
}) => PersonalFoodDraft(
  names: FoodNames(name),
  per100: Nutrients.zero,
  basis: basis,
  aliases: aliases,
  barcodes: barcodes,
  servings: servings,
);

/// Fault injection at the second family boundary, after food writes were
/// queued.
final class RejectRelinkHandler extends ChangeOpHandler<DiaryOp> {
  const new(this.db, {required this.failRelink, this.failLog = false});
  final AppDatabase db;
  final bool failRelink;

  /// Rejects every LogEntries (A28a: a scanned food's create must roll back).
  final bool failLog;
  @override
  String get family => DiaryOp.familyName;
  @override
  Future<OpPlan> plan(DiaryOp op, TxReader tx, ApplyContext context) {
    if ((failRelink && op is RelinkFoodRefs) || (failLog && op is LogEntries)) {
      throw const ChangeRejected(InvalidOp('injectedFailure'));
    }
    return DiaryOpHandler(db).plan(op, tx, context);
  }
}
