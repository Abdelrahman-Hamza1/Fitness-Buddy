import 'package:drift/drift.dart' show Value, Variable;
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/measurement_harness.dart';

/// The `InvalidOp` code of [failure].
String? _code(ChangeFailure failure) =>
    failure is InvalidOp ? failure.code : null;

void main() {
  late MeasurementHarness h;

  setUp(() => h = MeasurementHarness());

  MeasurementTypeRef custom(int n) => MeasurementTypeRef.custom(tId(n));

  test('WB-040 CreateMeasurement writes value, input, time, local date and '
      'one outbox row', () async {
    final outbox = await h.outboxCount();
    final draft = measureDraft(36.5, unit: MeasurementUnit.inch, hour: 1);
    await h.apply([CreateMeasurement(mId(1), draft)]);
    final row = await h.row(mId(1));
    expect(row.kind, 'waist');
    expect(row.customTypeId, isNull);
    expect(row.value, 92.71);
    expect(row.inputValue, 36.5);
    expect(row.inputUnit, 'in');
    expect(row.measuredAtUtc, draft.time.occurredAtUtc.millisecondsSinceEpoch);
    expect(row.tzOffsetMin, 180);
    expect(row.localDate, '2026-10-17');
    expect(row.version, 1);
    expect(await h.outboxCount(), outbox + 1);
    final live = (await h.live()).measurements.single;
    expect(live.draft, draft);
  });

  test('UX-030 undo of CreateMeasurement tombstones the row · UX-030 '
      'DeleteMeasurement tombstones the row and undo restores its '
      'content', () async {
    final created = await h.apply([
      CreateMeasurement(mId(1), measureDraft(92)),
    ]);
    await h.undo(created);
    expect((await h.row(mId(1))).deletedAt, isNotNull);
    expect((await h.live()).measurements, isEmpty);

    await h.apply([CreateMeasurement(mId(2), measureDraft(91))]);
    final before = await h.state();
    final deleted = await h.apply([DeleteMeasurement(VersionedId(mId(2), 1))]);
    expect((await h.row(mId(2))).deletedAt, isNotNull);
    await h.undo(deleted);
    expect((await h.row(mId(2))).deletedAt, isNull);
    expect(await h.state(), before);
  });

  test('UpdateMeasurement with a stale version is rejected and writes '
      'nothing; an identical draft writes nothing', () async {
    final draft = measureDraft(92.25);
    await h.apply([CreateMeasurement(mId(1), draft)]);
    expect(
      await h.reject([UpdateMeasurement(mId(1), 2, measureDraft(91))]),
      isA<VersionConflict>(),
    );
    final outbox = await h.outboxCount();
    final same = await h.apply([UpdateMeasurement(mId(1), 1, draft)]);
    expect(same.inverse.isEmpty, isTrue);
    expect((await h.row(mId(1))).version, 1);
    expect(await h.outboxCount(), outbox);
    await h.apply([UpdateMeasurement(mId(1), 1, measureDraft(91))]);
    expect((await h.row(mId(1))).value, 91);
    expect(
      await h.reject([UpdateMeasurement(mId(9), 1, measureDraft(91))]),
      isA<RowNotFound>(),
    );
  });

  test('a custom measurement whose type is missing or deleted is rejected '
      '(unknownType)', () async {
    expect(
      _code(
        await h.reject([
          CreateMeasurement(mId(1), measureDraft(40, type: custom(1))),
        ]),
      ),
      'unknownType',
    );
    await h.apply([CreateMeasurementType(tId(1), 'Left arm')]);
    await h.apply([DeleteMeasurementType(VersionedId(tId(1), 1), const [])]);
    expect(
      _code(
        await h.reject([
          CreateMeasurement(mId(1), measureDraft(40, type: custom(1))),
        ]),
      ),
      'unknownType',
    );
    await h.apply([CreateMeasurementType(tId(2), 'Calf')]);
    await h.apply([
      CreateMeasurement(mId(2), measureDraft(40, type: custom(2))),
    ]);
    expect((await h.live()).measurements.single.type, custom(2));
  });

  test('a measured time more than 5 minutes ahead is rejected (future); '
      'before 1970 (time); an invalid draft (invalidDraft)', () async {
    final future = MeasurementDraft(
      type: waistRef,
      time: EntryTime(measureNow.add(const Duration(minutes: 6)), 180),
      input: const MeasurementInput(90, MeasurementUnit.cm),
    );
    expect(
      _code(await h.reject([CreateMeasurement(mId(1), future)])),
      'future',
    );
    final skew = MeasurementDraft(
      type: waistRef,
      time: EntryTime(measureNow.add(const Duration(minutes: 5)), 180),
      input: const MeasurementInput(90, MeasurementUnit.cm),
    );
    await h.apply([CreateMeasurement(mId(2), skew)]);
    final old = MeasurementDraft(
      type: waistRef,
      time: EntryTime(DateTime.utc(1969, 12, 31), 0),
      input: const MeasurementInput(90, MeasurementUnit.cm),
    );
    expect(_code(await h.reject([CreateMeasurement(mId(1), old)])), 'time');
    for (final bad in [
      measureDraft(9),
      measureDraft(301),
      measureDraft(20, unit: MeasurementUnit.percent),
      measureDraft(
        20,
        type: MeasurementTypeRef.builtIn(MeasurementKind.bodyFat),
      ),
      measureDraft(80, type: MeasurementTypeRef(kind: MeasurementKind.custom)),
    ]) {
      expect(
        _code(await h.reject([CreateMeasurement(mId(1), bad)])),
        'invalidDraft',
      );
    }
    // The same rules on an update.
    expect(
      _code(await h.reject([UpdateMeasurement(mId(2), 1, measureDraft(9))])),
      'invalidDraft',
    );
  });

  test('a duplicate live custom type name is rejected regardless of case; a '
      'stale rename is rejected', () async {
    await h.apply([CreateMeasurementType(tId(1), 'Left Arm')]);
    for (final name in ['left arm', ' LEFT ARM ', 'Left Arm']) {
      expect(
        _code(await h.reject([CreateMeasurementType(tId(2), name)])),
        'duplicateName',
      );
    }
    await h.apply([CreateMeasurementType(tId(2), 'Ärm')]);
    expect(
      _code(await h.reject([CreateMeasurementType(tId(3), 'ärm')])),
      'duplicateName',
    );
    expect(
      _code(await h.reject([RenameMeasurementType(tId(2), 1, 'LEFT arm')])),
      'duplicateName',
    );
    for (final bad in ['  ', 'a' * 41, 'Arm\u0007']) {
      expect(
        _code(await h.reject([CreateMeasurementType(tId(3), bad)])),
        'invalidDraft',
      );
    }
    // Renaming to its own name in another case is fine.
    await h.apply([RenameMeasurementType(tId(1), 1, 'left arm')]);
    expect((await h.typeRow(tId(1))).name, 'left arm');
    expect(
      await h.reject([RenameMeasurementType(tId(1), 1, 'Arm L')]),
      isA<VersionConflict>(),
    );
    final same = await h.apply([
      RenameMeasurementType(tId(1), 2, ' left arm '),
    ]);
    expect(same.inverse.isEmpty, isTrue);
  });

  test('WB-040 UX-030 DeleteMeasurementType tombstones the type and its '
      'measurements atomically; changed membership is rejected; undo revives '
      'all', () async {
    await h.apply([CreateMeasurementType(tId(1), 'Calf')]);
    await h.apply([
      CreateMeasurement(mId(1), measureDraft(40, type: custom(1))),
      CreateMeasurement(
        mId(2),
        measureDraft(40.5, type: custom(1), date: measureDay.plusDays(-1)),
      ),
      CreateMeasurement(mId(3), measureDraft(92)),
    ]);
    final before = await h.state();
    // A missing member, a stale version, an extra one.
    for (final members in [
      [VersionedId(mId(1), 1)],
      [VersionedId(mId(1), 1), VersionedId(mId(2), 2)],
      [VersionedId(mId(1), 1), VersionedId(mId(2), 1), VersionedId(mId(3), 1)],
    ]) {
      expect(
        _code(
          await h.reject([
            DeleteMeasurementType(VersionedId(tId(1), 1), members),
          ]),
        ),
        'sourceChanged',
      );
    }
    final deleted = await h.apply([
      DeleteMeasurementType(VersionedId(tId(1), 1), [
        VersionedId(mId(2), 1),
        VersionedId(mId(1), 1),
      ]),
    ]);
    final live = await h.live();
    expect(live.types, isEmpty);
    expect(live.measurements.map((m) => m.id), [mId(3)]);
    expect((await h.typeRow(tId(1))).deletedAt, isNotNull);
    expect((await h.row(mId(1))).deletedAt, isNotNull);
    expect((await h.row(mId(2))).deletedAt, isNotNull);

    await h.undo(deleted);
    expect(await h.state(), before);
    expect((await h.live()).measurements, hasLength(3));
  });

  test('UX-030 AC-012 undo of every measurement op restores the user-visible '
      'content with a newer version and HLC, writes valid inverse metadata '
      '(origin, updated_hlc) and appends one new outbox row per touched row; '
      'created rows become tombstones', () async {
    await h.apply([CreateMeasurementType(tId(9), 'Neck L')]);
    await h.apply([
      CreateMeasurement(mId(9), measureDraft(40, type: custom(9))),
    ]);
    Future<Map<String, Object?>> meta(String table, String id) async =>
        (await h.db
                .customSelect(
                  'SELECT version, updated_hlc, origin, deleted_at '
                  'FROM $table WHERE id = ?',
                  variables: [Variable.withString(id)],
                )
                .getSingle())
            .data;

    final cases = <(String, List<ChangeOp>, List<(String, String)>)>[
      (
        'create measurement',
        [CreateMeasurement(mId(1), measureDraft(92))],
        [('measurements', mId(1))],
      ),
      (
        'update measurement',
        [UpdateMeasurement(mId(9), 1, measureDraft(41, type: custom(9)))],
        [('measurements', mId(9))],
      ),
      (
        'delete measurement',
        [DeleteMeasurement(VersionedId(mId(9), 3))],
        [('measurements', mId(9))],
      ),
      (
        'create type',
        [CreateMeasurementType(tId(1), 'Calf')],
        [('measurement_types', tId(1))],
      ),
      (
        'rename type',
        [RenameMeasurementType(tId(9), 1, 'Neck left')],
        [('measurement_types', tId(9))],
      ),
      (
        'delete type',
        [
          DeleteMeasurementType(VersionedId(tId(9), 3), [
            VersionedId(mId(9), 5),
          ]),
        ],
        [('measurements', mId(9)), ('measurement_types', tId(9))],
      ),
    ];
    for (final (name, ops, touched) in cases) {
      final before = await h.state();
      final applied = await h.apply(ops);
      final afterApply = {
        for (final (table, id) in touched) id: await meta(table, id),
      };
      final outbox = await h.outboxCount();
      await h.undo(applied);
      expect(await h.state(), before, reason: name);
      expect(await h.outboxCount(), outbox + touched.length, reason: name);
      for (final (table, id) in touched) {
        final now = await meta(table, id);
        final was = afterApply[id]!;
        expect(now['version'], (was['version']! as int) + 1, reason: name);
        expect(
          (now['updated_hlc']! as String).compareTo(
            was['updated_hlc']! as String,
          ),
          greaterThan(0),
          reason: name,
        );
        expect(now['origin'], startsWith('undo:'), reason: name);
        if (name.startsWith('create')) {
          expect(now['deleted_at'], isNotNull, reason: name);
        }
      }
    }
  });

  test('UX-030 an undo that conflicts with a later edit is rejected '
      'atomically: nothing written, no outbox row', () async {
    final created = await h.apply([
      CreateMeasurement(mId(1), measureDraft(92)),
      CreateMeasurement(
        mId(2),
        measureDraft(91, date: measureDay.plusDays(-1)),
      ),
    ]);
    await h.apply([
      UpdateMeasurement(
        mId(2),
        1,
        measureDraft(90, date: measureDay.plusDays(-1)),
      ),
    ]);
    expect(await h.undoRejected(created), isA<VersionConflict>());
    expect((await h.live()).measurements, hasLength(2));
  });

  test('UX-030 create type → add measurement → undo the type creation is '
      'rejected (typeInUse) and writes nothing; undoing the measurement '
      'first, then the type, succeeds', () async {
    final type = await h.apply([CreateMeasurementType(tId(1), 'Calf')]);
    final entry = await h.apply([
      CreateMeasurement(mId(1), measureDraft(40, type: custom(1))),
    ]);
    expect(_code(await h.undoRejected(type)), 'typeInUse');
    await h.undo(entry);
    await h.undo(type);
    final live = await h.live();
    expect(live.types, isEmpty);
    expect(live.measurements, isEmpty);
  });

  test('UX-030 delete a measurement → delete its type → undo the measurement '
      'deletion is rejected (unknownType); undoing the type deletion first, '
      'then the measurement, restores both', () async {
    await h.apply([CreateMeasurementType(tId(1), 'Calf')]);
    await h.apply([
      CreateMeasurement(mId(1), measureDraft(40, type: custom(1))),
    ]);
    final before = await h.state();
    final entry = await h.apply([DeleteMeasurement(VersionedId(mId(1), 1))]);
    final type = await h.apply([
      DeleteMeasurementType(VersionedId(tId(1), 1), const []),
    ]);
    expect(_code(await h.undoRejected(entry)), 'unknownType');
    await h.undo(type);
    await h.undo(entry);
    expect(await h.state(), before);
  });

  test('UX-030 rename a type → create a new type with the old name (any '
      'case) → undo the rename is rejected (duplicateName) · delete a type → '
      'create one with its name → undo the deletion is rejected '
      '(duplicateName)', () async {
    await h.apply([CreateMeasurementType(tId(1), 'Calf')]);
    final rename = await h.apply([RenameMeasurementType(tId(1), 1, 'Shin')]);
    await h.apply([CreateMeasurementType(tId(2), 'CALF')]);
    expect(_code(await h.undoRejected(rename)), 'duplicateName');

    final delete = await h.apply([
      DeleteMeasurementType(VersionedId(tId(2), 1), const []),
    ]);
    await h.apply([CreateMeasurementType(tId(3), ' calf ')]);
    expect(_code(await h.undoRejected(delete)), 'duplicateName');
  });

  test('an UpdateMeasurement that changes the type is rejected '
      '(typeChanged)', () async {
    await h.apply([CreateMeasurementType(tId(1), 'Calf')]);
    await h.apply([CreateMeasurement(mId(1), measureDraft(40))]);
    for (final type in [
      custom(1),
      MeasurementTypeRef.builtIn(MeasurementKind.chest),
    ]) {
      expect(
        _code(
          await h.reject([
            UpdateMeasurement(mId(1), 1, measureDraft(40, type: type)),
          ]),
        ),
        'typeChanged',
      );
    }
  });

  test('a custom type the lists hide (a blank synced name) is unknownType for '
      'a new or edited entry (A15b review m2)', () async {
    await h.apply([
      ScriptOp.rows([
        InsertRow(
          h.db.measurementTypes,
          MeasurementTypesCompanion(id: Value(tId(1)), name: const Value('  ')),
        ),
      ]),
    ]);
    expect(
      _code(
        await h.reject([
          CreateMeasurement(mId(1), measureDraft(40, type: custom(1))),
        ]),
      ),
      'unknownType',
    );
  });

  test('UX-030 PA1 a type and its entry created in one change set undo in '
      'one step: the guards see the state after the whole inverse', () async {
    final before = await h.state();
    final both = await h.apply([
      CreateMeasurementType(tId(1), 'Calf'),
      CreateMeasurement(mId(1), measureDraft(40, type: custom(1))),
    ]);
    await h.undo(both);
    expect(await h.state(), before);
    expect((await h.typeRow(tId(1))).deletedAt, isNotNull);
    expect((await h.row(mId(1))).deletedAt, isNotNull);
  });
}
