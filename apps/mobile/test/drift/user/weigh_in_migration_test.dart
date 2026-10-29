import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift_dev/api/migrations_native.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/db/tables/sync_columns.dart';
import 'package:fb_mobile/core/db/write_guard.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../core/db/support/db_support.dart';
import 'generated/schema.dart';
// A renumber (A14 D11) changes these two imports and the two constants.
import 'generated/schema_v5.dart' as before;
import 'generated/schema_v6.dart' as after;

/// The schema version before the weigh-in step.
const _from = 5;

/// The version that adds `weigh_ins`.
const _to = 6;

const _hlc = '1760351234567-00000-0199e3c2-5b1a-7c3d-8e4f-0123456789ab';
const _id = '0199e3c2-5b1a-7c3d-8e4f-0123456789ab';

/// Every table at [_from] with its contract entity, seeded from the wire
/// fixtures.
const _tables = {
  'setting': 'settings_kv',
  'mealSlot': 'meal_slots',
  'dishGroup': 'dish_groups',
  'diaryEntry': 'diary_entries',
  'dayMark': 'day_marks',
  'savedMeal': 'saved_meals',
  'savedMealItem': 'saved_meal_items',
  'personalFood': 'personal_foods',
  'profile': 'profile',
  'goalPhase': 'goal_phases',
  'targetSettings': 'target_settings',
};

/// The local columns the `weighIn` v1 wire doesn't carry yet (A14 D7, PA4).
const _localOnly = {
  'tz_offset_min',
  'input_value',
  'input_unit',
  'preferred_for_day',
};

String _snake(String s) =>
    s.replaceAllMapped(RegExp('[A-Z]'), (m) => '_${m[0]!.toLowerCase()}');

Map<String, dynamic> _json(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

final Map<String, dynamic> _fixtures = _json(
  '../../contracts/testdata/sync/entity-payloads.json',
);

/// [entity]'s fixture payload as SQL column values (snake_case, booleans as
/// 0/1), with sync metadata.
Map<String, Object?> _row(String entity) => {
  'id': _id,
  'created_at': 0,
  'updated_hlc': _hlc,
  'version': 1,
  'device_id': _id,
  'deleted_at': null,
  for (final f in (_fixtures[entity] as Map<String, dynamic>).entries)
    if (f.key != 'createdAtMs')
      _snake(f.key): f.value is bool ? (f.value == true ? 1 : 0) : f.value,
};

String _insert(String table, Map<String, Object?> values) =>
    'INSERT INTO $table (${values.keys.join(',')}) '
    'VALUES (${List.filled(values.length, '?').join(',')})';

Future<List<String>> _names(GeneratedDatabase db, String type) async => [
  for (final r
      in await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = '$type' "
            "AND tbl_name = 'weigh_ins' ORDER BY name",
          )
          .get())
    r.read<String>('name'),
];

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final verifier = SchemaVerifier(GeneratedHelper());

  test('migration v$_from→v$_to keeps every v$_from row and adds weigh_ins '
      'with its index and three triggers', () async {
    final seeded = <String, List<Map<String, Object?>>>{};
    var outboxBefore = 0;
    await verifier.testWithDataIntegrity(
      oldVersion: _from,
      newVersion: _to,
      createOld: before.DatabaseAtV5.new,
      createNew: after.DatabaseAtV6.new,
      openTestedDatabase: AppDatabase.new,
      createItems: (batch, db) {
        batch.customStatement(
          "INSERT INTO sync_state (key,value) VALUES ('outbox.capture','1')",
        );
        for (final MapEntry(key: entity, value: table) in _tables.entries) {
          final values = _row(entity);
          batch.customStatement(_insert(table, values), values.values.toList());
          seeded[table] = [values];
        }
        outboxBefore = _tables.length;
      },
      validateItems: (db) async {
        for (final MapEntry(key: table, value: rows) in seeded.entries) {
          final now = await db.customSelect('SELECT * FROM $table').get();
          expect(now.map((r) => r.data).toList(), rows, reason: table);
        }
        expect(await db.select(db.syncOutbox).get(), hasLength(outboxBefore));
        expect(await db.select(db.weighIns).get(), isEmpty);
        expect(await _names(db, 'trigger'), [
          'weigh_ins_no_delete',
          'weigh_ins_outbox_ai',
          'weigh_ins_outbox_au',
        ]);
        expect(await _names(db, 'index'), contains('ix_weigh_ins_live'));
        final columns = await db
            .customSelect('PRAGMA index_info(ix_weigh_ins_live)')
            .get();
        expect(columns.map((r) => r.read<String>('name')), [
          'local_date',
          'measured_at_utc',
        ]);
        final plan = await db
            .customSelect(
              'EXPLAIN QUERY PLAN SELECT * FROM weigh_ins '
              "WHERE local_date = '2026-10-18' AND deleted_at IS NULL "
              'ORDER BY measured_at_utc',
            )
            .get();
        expect(
          plan.map((r) => r.read<String>('detail')).join(),
          contains('ix_weigh_ins_live'),
        );

        // Capture works after the upgrade, and the PA9 CHECK holds.
        final row = {
          ..._row('weighIn'),
          'tz_offset_min': 180,
          'input_value': 1.0,
          'input_unit': 'kg',
        };
        await db.customStatement(
          _insert('weigh_ins', row),
          row.values.toList(),
        );
        expect((await db.select(db.syncOutbox).get()).last.entity, 'weighIn');
        final negative = {...row, 'id': '${_id.substring(0, 35)}c'};
        negative['measured_at_utc'] = -1;
        await expectLater(
          db.customStatement(
            _insert('weigh_ins', negative),
            negative.values.toList(),
          ),
          throwsA(predicate((e) => '$e'.contains('CHECK'))),
        );
      },
    );
  });

  test('the weighIn wire fixture fields map to weigh_ins columns by '
      'snake_case; the extra local columns are the documented four', () async {
    final db = memoryDatabase();
    final columns = {
      for (final r
          in await db
              .customSelect("SELECT name FROM pragma_table_info('weigh_ins')")
              .get())
        r.read<String>('name'),
    };
    final versions =
        (_json('../../contracts/openapi/sync-entities.json')['entities']
                as Map<String, dynamic>)['weighIn']
            as Map<String, dynamic>;
    final latest = versions.keys.map(int.parse).reduce((a, b) => a > b ? a : b);
    final wire = {
      for (final field
          in ((versions['$latest'] as Map<String, dynamic>)['properties']
                  as Map<String, dynamic>)
              .keys)
        if (field == 'createdAtMs') 'created_at' else _snake(field),
    };
    expect(
      (_fixtures['weighIn'] as Map<String, dynamic>).keys
          .map((f) => f == 'createdAtMs' ? 'created_at' : _snake(f))
          .toSet(),
      wire,
      reason: 'the fixture covers the latest weighIn wire version',
    );
    expect(
      columns.containsAll(wire),
      isTrue,
      reason: 'every weighIn wire field has a weigh_ins column',
    );
    expect(
      columns.difference(wire).difference(syncColumnNames.toSet()),
      _localOnly,
      reason:
          'The weigh_ins columns outside the weighIn v$latest wire must be '
          'exactly the documented four (A14 D7/PA4). weighIn v2 lands in B19 '
          '(body & targets sync): add them to weighIn v2 with the v1→v2 '
          'upgrader there, then update _localOnly here.',
    );

    // The fixture payload stores as it is, with the local columns' values.
    final row = {
      ..._row('weighIn'),
      'tz_offset_min': 0,
      'input_value': 1.0,
      'input_unit': 'kg',
    };
    await runAuthorizedWrite(
      () => db.customStatement(_insert('weigh_ins', row), row.values.toList()),
    );
    final stored = await db.select(db.weighIns).getSingle();
    expect(
      (stored.kg, stored.localDate, stored.note),
      (1.0, '2026-10-18', null),
    );
    expect(stored.preferredForDay, isFalse);
  });
}
