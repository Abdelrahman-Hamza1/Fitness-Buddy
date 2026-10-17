import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_domain/testing.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/core/changes/change_set_applier.dart';
import 'package:fb_mobile/core/changes/op_handler.dart';
import 'package:fb_mobile/core/changes/row_ops.dart';
import 'package:fb_mobile/core/db/synced_tables.dart';
import 'package:fb_mobile/core/db/tables/sync_columns.dart';
import 'package:fb_mobile/core/db/tables/sync_tables.dart';
import 'package:fb_mobile/core/db/write_guard.dart';
import 'package:fb_mobile/core/db/write_guarded.dart';
import 'package:fb_mobile/core/events/domain_event_bus.dart';
import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_test/flutter_test.dart';

import '../../db/support/db_support.dart';

part 'test_db.g.dart';

/// A test-only synced table (A01 WP3): notes with a nullable column.
@DataClassName('NoteRow')
class TestNotes extends Table with SyncColumns {
  TextColumn get title => text()();
  TextColumn get body => text().nullable()();
}

/// A second test-only synced table, with a unique column (constraint
/// failures).
@DataClassName('TagRow')
class TestTags extends Table with SyncColumns {
  TextColumn get name => text().unique()();
}

/// A small database with the app's sync tables, two synced test tables and
/// the same outbox triggers and write guard as `AppDatabase`.
@DriftDatabase(tables: [SyncState, SyncOutbox, TestNotes, TestTags])
final class TestDatabase extends _$TestDatabase with WriteGuarded {
  new(QueryExecutor executor) : super(executor.interceptWith(WriteGuard()));

  late final List<SyncedTable<Table, Object?>> syncedTables = [
    SyncedTable<$TestNotesTable, NoteRow>(testNotes, 'testNote'),
    SyncedTable<$TestTagsTable, TagRow>(testTags, 'testTag'),
  ];

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => runAuthorizedWrite(() async {
      await m.createAll();
      for (final synced in syncedTables) {
        for (final sql in expectedTriggers(
          synced.sqlName,
          synced.entity,
        ).split('\n\n')) {
          await customStatement(sql);
        }
      }
    }),
  );
}

/// An in-memory [TestDatabase], closed after the test.
TestDatabase testDatabase([QueryExecutor? executor]) {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final db = TestDatabase(executor ?? NativeDatabase.memory());
  addTearDown(db.close);
  return db;
}

/// An op that runs a test's own planner.
final class ScriptOp implements ChangeOp {
  new(this.planner);

  /// An op that writes [rows] and emits [events].
  new rows(
    List<RowOp> rows, {
    List<DomainEvent> events = const [],
    List<DomainEvent> revertEvents = const [],
  }) : this(
         (_, _) async =>
             OpPlan(rows, events: events, revertEvents: revertEvents),
       );

  static const String familyName = 'test';

  final Future<OpPlan> Function(TxReader tx, ApplyContext context) planner;

  @override
  String get family => familyName;
}

/// The handler of [ScriptOp].
final class ScriptHandler extends ChangeOpHandler<ScriptOp> {
  const new();

  @override
  String get family => ScriptOp.familyName;

  @override
  Future<OpPlan> plan(ScriptOp op, TxReader tx, ApplyContext context) =>
      op.planner(tx, context);
}

/// A test event.
@immutable
final class Noted extends DomainEvent {
  const new(this.n);

  final int n;

  @override
  bool operator ==(Object other) => other is Noted && other.n == n;

  @override
  int get hashCode => n.hashCode;

  @override
  String toString() => 'Noted($n)';
}

/// The start of the test clock, 2026-10-17T00:00:00Z.
const int t0 = 1792195200000;

/// An applier over [db] and what it was built with.
final class Harness {
  new(
    this.db, {
    ManualClock? clock,
    SequenceIdGenerator? ids,
    String device = testDevice,
    List<ChangeOpHandler<ChangeOp>>? handlers,
  }) : clock = clock ?? ManualClock.millis(t0),
       ids = ids ?? SequenceIdGenerator() {
    addTearDown(bus.close);
    applier = ChangeSetApplier(
      db: db,
      tables: db.syncedTables,
      handlers: (_) => handlers ?? const [ScriptHandler()],
      clock: this.clock,
      ids: this.ids,
      deviceId: () async => device,
      events: bus,
    );
  }

  final TestDatabase db;
  final ManualClock clock;
  final SequenceIdGenerator ids;
  final DomainEventBus bus = DomainEventBus();
  late final ChangeSetApplier<TestDatabase> applier;

  /// Applies one [ScriptOp] per item of [ops] as a direct change set.
  Future<ApplyResult> run(List<List<RowOp>> ops, {Origin? origin}) =>
      applier.apply(
        ChangeSet([
          for (final rows in ops) ScriptOp.rows(rows),
        ], origin: origin ?? Origin.direct),
      );

  /// Like [run], expecting [Applied].
  Future<Applied> applied(List<List<RowOp>> ops, {Origin? origin}) async {
    final result = await run(ops, origin: origin);
    if (result is! Applied) fail('expected Applied, got $result');
    return result;
  }

  /// Every row of [table] as raw SQL values, by id.
  Future<List<Map<String, Object?>>> rows(String table) async => [
    for (final r
        in await db.customSelect('SELECT * FROM "$table" ORDER BY id').get())
      r.data,
  ];

  /// Row [id] of [table] as raw SQL values.
  Future<Map<String, Object?>?> row(String table, String id) async =>
      (await db
              .customSelect(
                'SELECT * FROM "$table" WHERE id = ?',
                variables: [Variable.withString(id)],
              )
              .getSingleOrNull())
          ?.data;

  /// The outbox rows as `(entity, rowId, hlc, deleted)`.
  Future<List<(String, String, String, bool)>> outbox() async => [
    for (final r in await (db.select(
      db.syncOutbox,
    )..orderBy([(t) => OrderingTerm(expression: t.seq)])).get())
      (r.entity, r.rowId, r.hlc, r.deleted),
  ];

  /// `sync_state['hlc.last']`.
  Future<String?> lastHlc() async => (await (db.select(
    db.syncState,
  )..where((t) => t.key.equals('hlc.last'))).getSingleOrNull())?.value;
}

/// A note insert: the companion gives only the id and content (the writer
/// stamps the sync metadata).
InsertRow<$TestNotesTable, NoteRow> addNote(
  TestDatabase db,
  String id,
  String title, {
  String? body,
  bool? editedByUser,
}) => InsertRow(
  db.testNotes,
  TestNotesCompanion(
    id: Value(id),
    title: Value(title),
    body: Value(body),
    editedByUser: editedByUser == null
        ? const Value.absent()
        : Value(editedByUser),
  ),
);

/// A tag insert.
InsertRow<$TestTagsTable, TagRow> addTag(
  TestDatabase db,
  String id,
  String name,
) =>
    InsertRow(db.testTags, TestTagsCompanion(id: Value(id), name: Value(name)));

/// A note update.
UpdateRow<$TestNotesTable, NoteRow> editNote(
  TestDatabase db,
  String id, {
  String? title,
  Value<String?> body = const Value.absent(),
  bool? editedByUser,
  int? expectedVersion,
}) => UpdateRow(
  db.testNotes,
  id,
  TestNotesCompanion(
    title: title == null ? const Value.absent() : Value(title),
    body: body,
    editedByUser: editedByUser == null
        ? const Value.absent()
        : Value(editedByUser),
  ),
  expectedVersion: expectedVersion,
);
