import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/isolate.dart';
import 'package:drift/native.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_domain/testing.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/core/changes/change_set_applier.dart';
import 'package:fb_mobile/core/changes/op_handler.dart';
import 'package:fb_mobile/core/changes/row_ops.dart';
import 'package:fb_mobile/core/db/write_guard.dart';
import 'package:fb_mobile/core/events/domain_event_bus.dart';
import 'package:flutter_test/flutter_test.dart';

import '../db/support/db_support.dart';
import 'support/test_db.dart';

const _n1 = '0199e3c2-5b1a-7c3d-8e4f-000000000001';
const _n2 = '0199e3c2-5b1a-7c3d-8e4f-000000000002';
const _g1 = '0199e3c2-5b1a-7c3d-8e4f-0000000000a1';
const _g2 = '0199e3c2-5b1a-7c3d-8e4f-0000000000a2';

/// A row value that must never reach an error's text.
const _secret = 'PLANTED-SECRET-7f3a';

/// A change set of one op per planner.
ChangeSet _set(List<ScriptOp> ops) => ChangeSet(ops, origin: Origin.direct);

/// An in-memory test database behind a drift isolate, like the app's
/// connection (errors arrive as DriftRemoteException).
QueryExecutor _isolateMemory() => LazyDatabase(() async {
  final isolate = await DriftIsolate.spawn(NativeDatabase.memory);
  return await isolate.connect(singleClientMode: true);
});

void main() {
  group('AI-036 atomic apply', () {
    test('AI-036 a change set with several ops across two tables applies '
        'atomically', () async {
      final h = Harness(testDatabase());
      final result = await h.applied([
        [addNote(h.db, _n1, 'one')],
        [addTag(h.db, _g1, 'red'), addNote(h.db, _n2, 'two')],
      ]);
      expect((await h.rows('test_notes')).map((r) => r['title']), [
        'one',
        'two',
      ]);
      expect((await h.rows('test_tags')).map((r) => r['name']), ['red']);
      final outbox = await h.outbox();
      expect(outbox.map((o) => (o.$1, o.$2)), [
        ('testNote', _n1),
        ('testTag', _g1),
        ('testNote', _n2),
      ]);
      expect(await h.lastHlc(), outbox.last.$3);
      expect(result.events.single, isA<ChangeSetApplied>());
      expect((result.events.single as ChangeSetApplied).entities, {
        'testNote',
        'testTag',
      });
    });

    test('AI-036 a failing third op rolls back the first two (rows, outbox, '
        'hlc.last) and emits no events', () async {
      final h = Harness(testDatabase());
      await h.applied([
        [addNote(h.db, _n1, 'one')],
      ]);
      final rowsBefore = await h.rows('test_notes');
      final outboxBefore = await h.outbox();
      final hlcBefore = await h.lastHlc();
      final heard = <DomainEvent>[];
      h.bus.events.listen(heard.add);

      final result = await h.applier.apply(
        _set([
          ScriptOp.rows(
            [editNote(h.db, _n1, title: 'changed')],
            events: [const Noted(1)],
          ),
          ScriptOp.rows([addTag(h.db, _g1, 'red')], events: [const Noted(2)]),
          ScriptOp.rows([editNote(h.db, _n2, title: 'missing')]),
        ]),
      );

      expect(
        result,
        isA<Rejected>().having(
          (r) => r.failure,
          'failure',
          const RowNotFound(entity: 'testNote', id: _n2),
        ),
      );
      expect(await h.rows('test_notes'), rowsBefore);
      expect(await h.rows('test_tags'), isEmpty);
      expect(await h.outbox(), outboxBefore);
      expect(await h.lastHlc(), hlcBefore);
      expect(heard, isEmpty);
    });

    test('a handler that throws ChangeRejected rolls back with its failure, '
        'and an unexpected error rolls back and is rethrown', () async {
      final h = Harness(testDatabase());
      final rejected = await h.applier.apply(
        _set([
          ScriptOp.rows([addNote(h.db, _n1, 'one')]),
          ScriptOp(
            (_, _) => throw const ChangeRejected(InvalidOp('noSuchSlot')),
          ),
        ]),
      );
      expect((rejected as Rejected).failure, const InvalidOp('noSuchSlot'));
      await expectLater(
        h.applier.apply(
          _set([
            ScriptOp.rows([addNote(h.db, _n1, 'one')]),
            ScriptOp((_, _) => throw StateError('bug')),
          ]),
        ),
        throwsStateError,
      );
      expect(await h.rows('test_notes'), isEmpty);
      expect(await h.outbox(), isEmpty);
      // The queue keeps going after an error.
      await h.applied([
        [addNote(h.db, _n1, 'one')],
      ]);
    });
  });

  group('preconditions', () {
    test('expectedVersion mismatch → Rejected(VersionConflict) with expected '
        'and actual, nothing written', () async {
      final h = Harness(testDatabase());
      await h.applied([
        [addNote(h.db, _n1, 'one')],
      ]);
      await h.applied([
        [editNote(h.db, _n1, title: 'two', expectedVersion: 1)],
      ]);
      final before = await h.rows('test_notes');
      final outbox = await h.outbox();

      for (final op in [
        editNote(h.db, _n1, title: 'three', expectedVersion: 1),
        TombstoneRow(h.db.testNotes, _n1, expectedVersion: 1),
      ]) {
        final result = await h.run([
          [op],
        ]);
        expect(
          (result as Rejected).failure,
          const VersionConflict(
            entity: 'testNote',
            id: _n1,
            expected: 1,
            actual: 2,
          ),
        );
      }
      expect(await h.rows('test_notes'), before);
      expect(await h.outbox(), outbox);
    });

    test('update of a missing id → RowNotFound; a tombstone is not a live '
        'row', () async {
      final h = Harness(testDatabase());
      Future<ChangeFailure> failure(RowOp op) async => ((await h.run([
        [op],
      ])) as Rejected).failure;

      expect(
        await failure(editNote(h.db, _n1, title: 'x')),
        const RowNotFound(entity: 'testNote', id: _n1),
      );
      expect(
        await failure(TombstoneRow(h.db.testNotes, _n1)),
        const RowNotFound(entity: 'testNote', id: _n1),
      );
      await h.applied([
        [addNote(h.db, _n1, 'one'), TombstoneRow(h.db.testNotes, _n1)],
      ]);
      expect(
        await failure(editNote(h.db, _n1, title: 'x')),
        const RowNotFound(entity: 'testNote', id: _n1),
      );
      expect(
        await failure(TombstoneRow(h.db.testNotes, _n1)),
        const RowNotFound(entity: 'testNote', id: _n1),
      );
    });

    for (final (name, open) in [
      ('in-memory', testDatabase),
      ('background isolate', () => testDatabase(_isolateMemory())),
    ]) {
      test('duplicate insert id → ConstraintViolation; a unique column '
          'too ($name)', () async {
        final h = Harness(open());
        await h.applied([
          [addNote(h.db, _n1, 'one'), addTag(h.db, _g1, 'red')],
        ]);
        final duplicateId = await h.run([
          [addNote(h.db, _n2, 'two')],
          [addNote(h.db, _n1, 'again')],
        ]);
        expect(
          (duplicateId as Rejected).failure,
          const ConstraintViolation('duplicateId'),
        );
        final unique = await h.run([
          [addTag(h.db, _g2, 'red')],
        ]);
        expect(
          (unique as Rejected).failure,
          const ConstraintViolation('unique'),
        );
        expect((await h.rows('test_notes')).map((r) => r['id']), [_n1]);
        expect(await h.outbox(), hasLength(2));
      });
    }

    test('invalid ops are rejected with a code: unknown family, wrong op '
        'type, unsynced table, sync metadata, unknown column, restore in a '
        'plan', () async {
      final db = testDatabase();
      final h = Harness(db, handlers: const [ScriptHandler(), _WrongType()]);
      Future<ChangeFailure> failure(ChangeOp op) async =>
          ((await h.applier.apply(
            ChangeSet([op], origin: Origin.direct),
          )) as Rejected).failure;

      expect(
        await failure(const _Other('nobody')),
        const InvalidOp('unknownFamily'),
      );
      expect(await failure(const _Other('wrong')), const InvalidOp('opType'));
      expect(
        await failure(
          ScriptOp.rows([
            UpdateRow(
              db.syncState,
              'outbox.capture',
              const SyncStateCompanion(value: Value('0')),
            ),
          ]),
        ),
        const InvalidOp('unsyncedTable'),
      );
      expect(
        await failure(
          ScriptOp.rows([
            InsertRow(
              db.testNotes,
              const TestNotesCompanion(
                id: Value(_n1),
                title: Value('t'),
                version: Value(7),
              ),
            ),
          ]),
        ),
        const InvalidOp('metaColumn'),
      );
      expect(
        await failure(
          ScriptOp.rows([
            UpdateRow(
              db.testNotes,
              _n1,
              const RawValuesInsertable<NoteRow>({'colour': Variable('x')}),
            ),
          ]),
        ),
        const InvalidOp('unknownColumn'),
      );
      expect(
        await failure(
          ScriptOp.rows([
            RestoreRow(db.testNotes, _n1, const {}, expectedVersion: 1),
          ]),
        ),
        const InvalidOp('restoreInPlan'),
      );
      expect(
        await failure(
          ScriptOp.rows([
            InsertRow(
              db.testNotes,
              const TestNotesCompanion(id: Value(_n1), body: Value(_secret)),
            ),
          ]),
        ),
        const InvalidOp('invalidRow'),
        reason: 'title is required: drift says so without the values',
      );
      expect(await h.rows('test_notes'), isEmpty);
    });

    test('a database failure that is not a constraint rolls back and '
        'throws DatabaseWriteException, whose text has no row value', () async {
      final h = Harness(testDatabase());
      // A note insert now fails with SQLITE_ERROR (1): its trigger writes a
      // table that's gone.
      await runAuthorizedWrite(() async {
        await h.db.customStatement('CREATE TABLE gone (a)');
        await h.db.customStatement(
          'CREATE TRIGGER notes_gone AFTER INSERT ON test_notes '
          'BEGIN INSERT INTO gone VALUES (NEW.title); END',
        );
        await h.db.customStatement('DROP TABLE gone');
      });
      Object? thrown;
      try {
        await h.run([
          [addNote(h.db, _n1, _secret, body: _secret)],
        ]);
      } on DatabaseWriteException catch (error) {
        thrown = error;
      }
      final error = thrown! as DatabaseWriteException;
      expect(error.extendedResultCode, 1);
      expect('$error', 'DatabaseWriteException(sqlite 1)');
      expect('$error', isNot(contains(_secret)));
      // Debug builds keep the original (SQLite's text, which can quote the
      // statement and its values) aside.
      expect('${error.debugCause}', contains('no such table'));
      expect(await h.rows('test_notes'), isEmpty);
    });

    test('an id is required on insert', () {
      final db = testDatabase();
      expect(
        () => InsertRow(db.testNotes, const TestNotesCompanion()),
        throwsArgumentError,
      );
    });

    test("the handler factory is called with the applier's own database", () {
      final db = testDatabase();
      final seen = <Object>[];
      ChangeSetApplier<TestDatabase>(
        db: db,
        tables: db.syncedTables,
        handlers: (bound) {
          seen.add(bound);
          return const [ScriptHandler()];
        },
        clock: ManualClock.millis(t0),
        ids: SequenceIdGenerator(),
        deviceId: () async => testDevice,
        events: DomainEventBus(),
      );
      expect(seen.single, same(db));
    });

    test('TxReader.liveRow skips tombstones; row returns them', () async {
      final h = Harness(testDatabase());
      await h.applied([
        [addNote(h.db, _n1, 'one'), addNote(h.db, _n2, 'two')],
        [TombstoneRow(h.db.testNotes, _n2)],
      ]);
      final result = await h.applier.apply(
        _set([
          ScriptOp((tx, _) async {
            expect((await tx.liveRow(h.db.testNotes, _n1))?.title, 'one');
            expect(await tx.liveRow(h.db.testNotes, _n2), isNull);
            expect((await tx.row(h.db.testNotes, _n2))?.title, 'two');
            expect(await tx.liveRow(h.db.testNotes, _g1), isNull);
            return OpPlan(const []);
          }),
        ]),
      );
      expect(result, isA<Applied>());
    });

    test('two handlers for one family are refused', () {
      expect(
        () => Harness(
          testDatabase(),
          handlers: const [ScriptHandler(), ScriptHandler()],
        ),
        throwsArgumentError,
      );
    });

    test('handlers can read but not write: a direct write in a plan throws '
        'UnauthorizedWriteError and rolls back', () async {
      final h = Harness(testDatabase());
      await expectLater(
        h.applier.apply(
          _set([
            ScriptOp.rows([addNote(h.db, _n1, 'one')]),
            ScriptOp((tx, _) async {
              expect(await tx.row(h.db.testNotes, _n1), isNotNull);
              await h.db
                  .into(h.db.testTags)
                  .insert(
                    TestTagsCompanion.insert(
                      id: _g1,
                      createdAt: 0,
                      updatedHlc: 'x',
                      version: 1,
                      deviceId: testDevice,
                      origin: 'direct',
                      name: 'sneaky',
                    ),
                  );
              return OpPlan(const []);
            }),
          ]),
        ),
        throwsA(isA<UnauthorizedWriteError>()),
      );
      expect(await h.rows('test_notes'), isEmpty);
      expect(await h.rows('test_tags'), isEmpty);
    });
  });

  group('AC-012 sync metadata', () {
    test('AC-012 meta stamped: version 1 then +1, updated_hlc strictly '
        'increasing, device_id = install id, origin text, created_at kept on '
        'update', () async {
      final h = Harness(testDatabase());
      const proposal = '0199e3c2-5b1a-7c3d-8e4f-0000000000ff';
      await h.applied([
        [addNote(h.db, _n1, 'one')],
      ]);
      final v1 = (await h.row('test_notes', _n1))!;
      expect(v1['version'], 1);
      expect(v1['device_id'], testDevice);
      expect(v1['origin'], 'direct');
      expect(v1['created_at'], t0);
      expect(v1['deleted_at'], isNull);

      h.clock.advance(const Duration(minutes: 1));
      await h.applied([
        [
          editNote(h.db, _n1, title: 'two'),
          editNote(h.db, _n1, body: const Value('b')),
        ],
      ], origin: Origin.proposal(proposal));
      final v3 = (await h.row('test_notes', _n1))!;
      expect(v3['version'], 3);
      expect(v3['created_at'], t0);
      expect(v3['origin'], 'proposal:$proposal');
      expect((v3['title'], v3['body']), ('two', 'b'));

      h.clock.advance(const Duration(minutes: 1));
      await h.applied([
        [TombstoneRow(h.db.testNotes, _n1, expectedVersion: 3)],
      ]);
      final v4 = (await h.row('test_notes', _n1))!;
      expect(v4['version'], 4);
      expect(v4['deleted_at'], t0 + 2 * 60000);
      expect(v4['title'], 'two');

      final hlcs = [for (final o in await h.outbox()) o.$3];
      expect(hlcs, hasLength(4));
      for (var i = 1; i < hlcs.length; i++) {
        expect(hlcs[i].compareTo(hlcs[i - 1]), greaterThan(0));
        expect(Hlc.parse(hlcs[i]) > Hlc.parse(hlcs[i - 1]), isTrue);
      }
      expect(Hlc.parse(hlcs.first).deviceId, testDevice);
      expect(v4['updated_hlc'], hlcs.last);
      expect(await h.outbox().then((o) => o.last.$4), isTrue);
    });

    test('edited_by_user is written only when an op sets it, and is carried '
        'forward on other updates', () async {
      final h = Harness(testDatabase());
      Future<Object?> edited() async =>
          (await h.row('test_notes', _n1))!['edited_by_user'];

      await h.applied([
        [
          addNote(h.db, _n1, 'one'),
          addNote(h.db, _n2, 'two', editedByUser: true),
        ],
      ]);
      expect(await edited(), 0);
      expect((await h.row('test_notes', _n2))!['edited_by_user'], 1);
      await h.applied([
        [editNote(h.db, _n1, title: 'x')],
      ]);
      expect(await edited(), 0);
      await h.applied([
        [editNote(h.db, _n1, title: 'y', editedByUser: true)],
      ]);
      expect(await edited(), 1);
      await h.applied([
        [editNote(h.db, _n1, title: 'z')],
        [TombstoneRow(h.db.testNotes, _n1)],
      ]);
      expect(await edited(), 1);
    });

    test('upsert inserts, then overwrites content and revives a tombstone, '
        'keeping created_at', () async {
      final h = Harness(testDatabase());
      UpsertRow<$TestNotesTable, NoteRow> upsert(String title) => UpsertRow(
        h.db.testNotes,
        TestNotesCompanion(id: const Value(_n1), title: Value(title)),
      );
      await h.applied([
        [upsert('a')],
      ]);
      h.clock.advance(const Duration(seconds: 1));
      await h.applied([
        [TombstoneRow(h.db.testNotes, _n1)],
        [upsert('b')],
      ]);
      final row = (await h.row('test_notes', _n1))!;
      expect(
        (row['title'], row['version'], row['deleted_at'], row['created_at']),
        ('b', 3, null, t0),
      );
    });

    test('hlc.last survives reopen; a clock moved backwards still yields a '
        'larger HLC', () async {
      final path = '${tempDir().path}/test.db';
      final first = TestDatabase(NativeDatabase(File(path)));
      final h1 = Harness(first, clock: ManualClock.millis(t0));
      await h1.applied([
        [addNote(first, _n1, 'one')],
      ]);
      final stored = (await h1.lastHlc())!;
      expect(stored, (await h1.row('test_notes', _n1))!['updated_hlc']);
      await first.close();

      final second = testDatabase(NativeDatabase(File(path)));
      final h2 = Harness(second, clock: ManualClock.millis(t0 - 60000));
      expect(await h2.lastHlc(), stored);
      await h2.applied([
        [editNote(second, _n1, title: 'two')],
      ]);
      final next = Hlc.parse((await h2.lastHlc())!);
      expect(next > Hlc.parse(stored), isTrue);
      expect(next.wallMs, t0);
    });

    test('ApplyContext: one instant, the change set id, the local date and '
        'new ids', () async {
      final clock = ManualClock.millis(t0 - 1, offsetMinutes: 180);
      final h = Harness(testDatabase(), clock: clock);
      late ApplyContext seen;
      final result = await h.applier.apply(
        _set([
          ScriptOp((_, context) async {
            seen = context;
            return OpPlan([addNote(h.db, context.ids.next(), 'one')]);
          }),
        ]),
      );
      expect(seen.changeSetId, (result as Applied).changeSetId);
      expect(seen.origin, Origin.direct);
      expect(seen.nowUtc, utcMillis(t0 - 1));
      // 23:59:59.999 UTC on 10-16 is 02:59 on 10-17 at +03:00.
      expect(seen.today, LocalDate(2026, 10, 17));
      expect((await h.rows('test_notes')).single['created_at'], t0 - 1);
    });

    test('a change set that writes nothing still applies, with no hlc.last '
        'and an empty inverse', () async {
      final h = Harness(testDatabase());
      final result = await h.applied([[]]);
      expect(result.inverse.isEmpty, isTrue);
      expect(await h.lastHlc(), isNull);
      expect((result.events.single as ChangeSetApplied).entities, isEmpty);
    });
  });

  group('events', () {
    test('events are emitted after commit in op order, never on rollback; a '
        'throwing listener does not fail the apply', () async {
      final h = Harness(testDatabase());
      final heard = <DomainEvent>[];
      h.bus.events.listen(heard.add);

      final result = await h.applier.apply(
        _set([
          ScriptOp.rows(
            [addNote(h.db, _n1, 'one')],
            events: [const Noted(1), const Noted(2)],
          ),
          ScriptOp((_, _) async {
            // Op 1's events wait for the commit.
            expect(heard, isEmpty);
            return OpPlan(
              [addNote(h.db, _n2, 'two')],
              events: [const Noted(3)],
            );
          }),
        ]),
      );
      final applied = result as Applied;
      expect(heard, applied.events);
      expect(heard.take(3), [const Noted(1), const Noted(2), const Noted(3)]);
      expect(
        heard.last,
        ChangeSetApplied(
          changeSetId: applied.changeSetId,
          origin: Origin.direct,
          entities: const {'testNote'},
        ),
      );

      heard.clear();
      await h.run([
        [addNote(h.db, _n1, 'duplicate')],
      ]);
      expect(heard, isEmpty);

      final errors = <Object>[];
      await runZonedGuarded(() async {
        h.bus.events.listen((_) => throw StateError('listener bug'));
        final after = await h.applied([
          [addNote(h.db, '0199e3c2-5b1a-7c3d-8e4f-000000000003', 'three')],
        ]);
        expect(after.events, isNotEmpty);
      }, (error, _) => errors.add(error));
      expect(errors, [isA<StateError>()]);
      expect(await h.rows('test_notes'), hasLength(3));
    });

    test('the outbox is announced to watchers after the commit', () async {
      final h = Harness(testDatabase());
      final counts = <int>[];
      final sub = h.db
          .select(h.db.syncOutbox)
          .watch()
          .listen((rows) => counts.add(rows.length));
      addTearDown(sub.cancel);
      await pumpEventQueue();
      await h.applied([
        [addNote(h.db, _n1, 'one')],
      ]);
      await pumpEventQueue();
      expect(counts, [0, 1]);
    });
  });

  test('change sets submitted concurrently apply one after another (no '
      'interleaved snapshots)', () async {
    final h = Harness(testDatabase());
    final gate = Completer<void>();
    final first = h.applier.apply(
      _set([
        ScriptOp((_, _) async {
          await gate.future;
          return OpPlan([addNote(h.db, _n1, 'one')]);
        }),
      ]),
    );
    final second = h.applier.apply(
      _set([
        ScriptOp((tx, _) async {
          final meta = await tx.meta(h.db.testNotes, _n1);
          expect(meta?.version, 1, reason: 'the first change set committed');
          return OpPlan([
            editNote(h.db, _n1, title: 'two', expectedVersion: meta!.version),
          ]);
        }),
      ]),
    );
    await pumpEventQueue();
    gate.complete();
    expect(await first, isA<Applied>());
    expect(await second, isA<Applied>());
    final row = (await h.row('test_notes', _n1))!;
    expect((row['title'], row['version']), ('two', 2));
  });

  group('batched writes (A01 WP5)', () {
    for (final (name, open) in [
      ('in-memory', testDatabase),
      ('background isolate', () => testDatabase(_isolateMemory())),
    ]) {
      test('a handler reads the writes of the ops before it: through '
          'TxReader, its own query and parallel reads ($name)', () async {
        final h = Harness(open());
        await h.applied([
          [addNote(h.db, _n1, 'one')],
        ]);
        final result = await h.applier.apply(
          _set([
            ScriptOp.rows([
              editNote(h.db, _n1, title: 'edited'),
              addNote(h.db, _n2, 'two'),
            ]),
            ScriptOp((tx, _) async {
              final (note, meta, count) = await (
                tx.row(h.db.testNotes, _n1),
                tx.meta(h.db.testNotes, _n2),
                tx.db
                    .customSelect('SELECT count(*) AS n FROM test_notes')
                    .getSingle(),
              ).wait;
              expect((note?.title, note?.version), ('edited', 2));
              expect(meta?.version, 1);
              expect(count.read<int>('n'), 2);
              return OpPlan([
                editNote(h.db, _n2, title: 'two, edited', expectedVersion: 1),
              ]);
            }),
          ]),
        );
        expect(result, isA<Applied>());
        expect((await h.rows('test_notes')).map((r) => r['title']), [
          'edited',
          'two, edited',
        ]);
        expect(await h.outbox(), hasLength(4));
        expect(await h.lastHlc(), (await h.outbox()).last.$3);
      });

      test('the first failure wins, as if each write ran when planned: a '
          "queued write's constraint failure beats a later op's rejection "
          '($name)', () async {
        final h = Harness(open());
        await h.applied([
          [addTag(h.db, _g1, 'red')],
        ]);
        Future<ChangeFailure> failure(List<ChangeOp> ops) async =>
            ((await h.applier.apply(
              ChangeSet(ops, origin: Origin.direct),
            )) as Rejected).failure;

        // A later op's handler rejects.
        expect(
          await failure([
            ScriptOp.rows([addTag(h.db, _g2, 'red')]),
            ScriptOp(
              (_, _) => throw const ChangeRejected(InvalidOp('noSuchSlot')),
            ),
          ]),
          const ConstraintViolation('unique'),
        );
        // A later row of the same op fails a check.
        expect(
          await failure([
            ScriptOp.rows([
              addTag(h.db, _g2, 'red'),
              editNote(h.db, _n1, title: 'missing'),
            ]),
          ]),
          const ConstraintViolation('unique'),
        );
        // A later op of an unknown family.
        expect(
          await failure([
            ScriptOp.rows([addTag(h.db, _g2, 'red')]),
            const _Other('nobody'),
          ]),
          const ConstraintViolation('unique'),
        );
        // A duplicate id is reported before a later unique failure.
        expect(
          await failure([
            ScriptOp.rows([
              addTag(h.db, _g1, 'blue'),
              addTag(h.db, _g2, 'red'),
            ]),
          ]),
          const ConstraintViolation('duplicateId'),
        );
        expect((await h.rows('test_tags')).map((r) => r['name']), ['red']);
        expect(await h.outbox(), hasLength(1));
      });
    }

    test('a handler that swallows the failure its read surfaced still gets '
        'the change set rejected', () async {
      final h = Harness(testDatabase());
      await h.applied([
        [addTag(h.db, _g1, 'red')],
      ]);
      final result = await h.applier.apply(
        _set([
          ScriptOp.rows([addTag(h.db, _g2, 'red')]),
          ScriptOp((tx, _) async {
            try {
              await tx.row(h.db.testTags, _g2);
            } on ChangeRejected {
              // A handler shouldn't do this; the applier still rejects.
            }
            return OpPlan([addNote(h.db, _n1, 'one')]);
          }),
        ]),
      );
      expect((result as Rejected).failure, const ConstraintViolation('unique'));
      expect(await h.rows('test_notes'), isEmpty);
    });

    test('a row changed behind the writer inside the transaction is a bug: '
        'StateError, rolled back', () async {
      final h = Harness(testDatabase());
      await h.applied([
        [addNote(h.db, _n1, 'one')],
      ]);
      await expectLater(
        h.applier.apply(
          _set([
            ScriptOp.rows([editNote(h.db, _n1, title: 'two')]),
            ScriptOp((tx, _) async {
              await tx.row(h.db.testNotes, _n1);
              // Only a bug in core/db could do this.
              await runAuthorizedWrite(
                () => h.db.customStatement(
                  'UPDATE test_notes SET version = 99 WHERE id = ?',
                  [_n1],
                ),
              );
              return OpPlan([editNote(h.db, _n1, title: 'three')]);
            }),
          ]),
        ),
        throwsStateError,
      );
      final row = (await h.row('test_notes', _n1))!;
      expect((row['title'], row['version']), ('one', 1));
    });

    test('change sets of more rows than one query takes: snapshots, '
        'existence checks and the version check are chunked', () async {
      final h = Harness(testDatabase());
      String id(int n) =>
          '0199e3c2-5b1a-7c3d-8e4f-${n.toRadixString(16).padLeft(12, '0')}';
      const count = 1201;
      await h.applied([
        [for (var n = 0; n < count; n++) addNote(h.db, id(n), 'note $n')],
      ]);
      final edited = await h.applied([
        [
          for (var n = 0; n < count; n++)
            editNote(h.db, id(n), title: 'edited $n', expectedVersion: 1),
          addNote(h.db, id(count), 'one more'),
        ],
      ]);
      expect(await h.outbox(), hasLength(2 * count + 1));
      final duplicate = await h.run([
        [addNote(h.db, id(count + 1), 'new'), addNote(h.db, id(700), 'again')],
      ]);
      expect(
        (duplicate as Rejected).failure,
        const ConstraintViolation('duplicateId'),
      );

      expect(await h.applier.revert(edited.inverse), isA<Applied>());
      final rows = await h.rows('test_notes');
      expect(rows, hasLength(count + 1));
      expect(rows.where((r) => r['deleted_at'] != null).map((r) => r['id']), [
        id(count),
      ]);
      expect(
        rows.where((r) => r['version'] == 3).map((r) => r['title']).first,
        'note 0',
      );
      expect(rows.where((r) => r['title'] == 'note 7'), hasLength(1));
    });
  });

  test('failures carry ids and codes only', () {
    const failures = <ChangeFailure>[
      VersionConflict(entity: 'testNote', id: _n1, expected: 1, actual: 2),
      RowNotFound(entity: 'testNote', id: _n1),
      InvalidOp('metaColumn'),
      ConstraintViolation('unique'),
    ];
    expect(failures.map((f) => '${Rejected(f)}'), [
      'Rejected(VersionConflict(testNote, $_n1, v1 != v2))',
      'Rejected(RowNotFound(testNote, $_n1))',
      'Rejected(InvalidOp(metaColumn))',
      'Rejected(ConstraintViolation(unique))',
    ]);
    expect(
      '${const ChangeRejected(InvalidOp('x'))}',
      'ChangeRejected(InvalidOp(x))',
    );
    expect(failures.toSet(), hasLength(4));
  });
}

/// An op of another family (or of the test family with the wrong type).
final class _Other implements ChangeOp {
  const new(this.family);

  @override
  final String family;
}

/// A handler for the family `wrong` that expects [ScriptOp]s.
final class _WrongType extends ChangeOpHandler<ScriptOp> {
  const new();

  @override
  String get family => 'wrong';

  @override
  Future<OpPlan> plan(ScriptOp op, TxReader tx, ApplyContext context) =>
      op.planner(tx, context);
}
