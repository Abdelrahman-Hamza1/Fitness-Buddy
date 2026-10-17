import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/core/changes/row_ops.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_db.dart';

const _n1 = '0199e3c2-5b1a-7c3d-8e4f-000000000001';
const _n2 = '0199e3c2-5b1a-7c3d-8e4f-000000000002';
const _g1 = '0199e3c2-5b1a-7c3d-8e4f-0000000000a1';

/// The columns undo restores (A01 D3): content, deleted_at, edited_by_user.
Map<String, Object?> _restored(Map<String, Object?> row) => {
  for (final MapEntry(:key, :value) in row.entries)
    if (!const {'version', 'updated_hlc', 'device_id', 'origin'}.contains(key))
      key: value,
};

Future<Applied> _revert(Harness h, Applied applied) async {
  final result = await h.applier.revert(applied.inverse);
  if (result is! Applied) fail('expected Applied, got $result');
  return result;
}

void main() {
  group('UX-030 undo restores the exact previous state', () {
    test('UX-030 content columns, deleted_at and edited_by_user equal the '
        'snapshot for update, tombstone and upsert', () async {
      final h = Harness(testDatabase());
      await h.applied([
        [
          addNote(h.db, _n1, 'one', body: 'b1'),
          addNote(h.db, _n2, 'two', editedByUser: true),
        ],
      ]);
      final cases = <String, List<RowOp>>{
        'update': [
          editNote(
            h.db,
            _n1,
            title: 'x',
            body: const Value(null),
            editedByUser: true,
          ),
        ],
        'tombstone': [TombstoneRow(h.db.testNotes, _n2)],
        'upsert': [
          UpsertRow(
            h.db.testNotes,
            const TestNotesCompanion(
              id: Value(_n1),
              title: Value('u'),
              body: Value('ub'),
              editedByUser: Value(false),
            ),
          ),
        ],
      };
      for (final MapEntry(key: name, value: rows) in cases.entries) {
        final before = await h.rows('test_notes');
        h.clock.advance(const Duration(seconds: 1));
        final applied = await h.applied([rows]);
        expect(await h.rows('test_notes'), isNot(before), reason: name);
        await _revert(h, applied);
        final after = await h.rows('test_notes');
        expect(after.map(_restored), before.map(_restored), reason: name);
        for (var i = 0; i < after.length; i++) {
          if (after[i]['updated_hlc'] != before[i]['updated_hlc']) {
            // Undo is a new write: version +2 (the change, then the undo).
            expect(after[i]['version'], (before[i]['version']! as int) + 2);
          }
        }
      }
    });

    test('UX-030 undo of an insert tombstones it', () async {
      final h = Harness(testDatabase());
      final applied = await h.applied([
        [addNote(h.db, _n1, 'one'), addTag(h.db, _g1, 'red')],
      ]);
      h.clock.advance(const Duration(seconds: 2));
      await _revert(h, applied);
      final note = (await h.row('test_notes', _n1))!;
      final tag = (await h.row('test_tags', _g1))!;
      expect((note['deleted_at'], note['version']), (t0 + 2000, 2));
      expect((tag['deleted_at'], tag['version']), (t0 + 2000, 2));
      expect(note['title'], 'one');
    });

    test('UX-030 undo of a delete revives the tombstoned row', () async {
      final h = Harness(testDatabase());
      await h.applied([
        [addNote(h.db, _n1, 'one')],
      ]);
      final live = await h.row('test_notes', _n1);
      final deleted = await h.applied([
        [TombstoneRow(h.db.testNotes, _n1, expectedVersion: 1)],
      ]);
      expect((await h.row('test_notes', _n1))!['deleted_at'], isNotNull);
      await _revert(h, deleted);
      final revived = (await h.row('test_notes', _n1))!;
      expect(revived['deleted_at'], isNull);
      expect(_restored(revived), _restored(live!));
    });

    test(
      'a row touched twice in one set restores its first snapshot',
      () async {
        final h = Harness(testDatabase());
        await h.applied([
          [addNote(h.db, _n1, 'one', body: 'b')],
        ]);
        final before = (await h.row('test_notes', _n1))!;
        final applied = await h.applied([
          [editNote(h.db, _n1, title: 'two')],
          [
            editNote(h.db, _n1, body: const Value('c')),
            TombstoneRow(h.db.testNotes, _n1),
          ],
        ]);
        expect(applied.inverse.rows, hasLength(1));
        await _revert(h, applied);
        final after = (await h.row('test_notes', _n1))!;
        expect(_restored(after), _restored(before));
        expect(after['version'], 5);
      },
    );

    test('a row inserted and tombstoned in one set needs no undo', () async {
      final h = Harness(testDatabase());
      final applied = await h.applied([
        [addNote(h.db, _n1, 'one'), TombstoneRow(h.db.testNotes, _n1)],
        [addNote(h.db, _n2, 'two')],
      ]);
      expect(applied.inverse.rows.single.id, _n2);
    });

    test('undo after a later change → conflict, nothing written', () async {
      final h = Harness(testDatabase());
      await h.applied([
        [addNote(h.db, _n1, 'one'), addNote(h.db, _n2, 'two')],
      ]);
      final applied = await h.applied([
        [editNote(h.db, _n2, title: 'b'), editNote(h.db, _n1, title: 'a')],
      ]);
      await h.applied([
        [editNote(h.db, _n1, title: 'later')],
      ]);
      final rows = await h.rows('test_notes');
      final outbox = await h.outbox();
      final result = await h.applier.revert(applied.inverse);
      expect(
        (result as Rejected).failure,
        const VersionConflict(
          entity: 'testNote',
          id: _n1,
          expected: 2,
          actual: 3,
        ),
      );
      expect(await h.rows('test_notes'), rows);
      expect(await h.outbox(), outbox);
    });

    test('undo syncs: it appends outbox rows, origin undo:<id>', () async {
      final h = Harness(testDatabase());
      final applied = await h.applied([
        [addNote(h.db, _n1, 'one')],
        [addTag(h.db, _g1, 'red')],
      ]);
      final heard = <DomainEvent>[];
      h.bus.events.listen(heard.add);
      final undone = await _revert(h, applied);
      final outbox = await h.outbox();
      expect(outbox, hasLength(4));
      expect(outbox.skip(2).map((o) => (o.$1, o.$2, o.$4)), [
        ('testTag', _g1, true),
        ('testNote', _n1, true),
      ]);
      expect(await h.lastHlc(), outbox.last.$3);
      final origin = 'undo:${applied.changeSetId}';
      expect((await h.row('test_notes', _n1))!['origin'], origin);
      expect((await h.row('test_tags', _g1))!['origin'], origin);
      expect(heard, [
        ChangeSetApplied(
          changeSetId: undone.changeSetId,
          origin: Origin.undo(applied.changeSetId),
          entities: const {'testNote', 'testTag'},
        ),
      ]);
    });

    test('revert takes only restores and tombstones: another row write is '
        "Rejected(InvalidOp('notInverse')) and nothing is written", () async {
      final h = Harness(testDatabase());
      final applied = await h.applied([
        [addNote(h.db, _n1, 'one')],
      ]);
      for (final row in <RowOp>[
        addNote(h.db, _n2, 'two'),
        editNote(h.db, _n1, title: 'x'),
        UpsertRow(
          h.db.testNotes,
          const TestNotesCompanion(id: Value(_n1), title: Value('u')),
        ),
      ]) {
        final result = await h.applier.revert(
          InverseChangeSet(
            changeSetId: applied.changeSetId,
            rows: [...applied.inverse.rows, row],
          ),
        );
        expect(
          (result as Rejected).failure,
          const InvalidOp('notInverse'),
          reason: row.runtimeType.toString(),
        );
      }
      expect((await h.rows('test_notes')).map((r) => r['title']), ['one']);
      expect((await h.rows('test_notes')).single['deleted_at'], isNull);
    });

    test('revert emits the revert events the plan asked for, then '
        'ChangeSetApplied', () async {
      final h = Harness(testDatabase());
      final applied = (await h.applier.apply(
        ChangeSet([
          ScriptOp.rows(
            [addNote(h.db, _n1, 'one')],
            events: [const Noted(1)],
            revertEvents: [const Noted(-1)],
          ),
        ], origin: Origin.direct),
      )) as Applied;
      expect(applied.inverse.events, [const Noted(-1)]);
      final undone = await _revert(h, applied);
      expect(undone.events.first, const Noted(-1));
      expect(undone.events.last, isA<ChangeSetApplied>());
      expect('${applied.inverse}', startsWith('InverseChangeSet('));
      expect('$applied', 'Applied(${applied.changeSetId})');
    });
  });
}
