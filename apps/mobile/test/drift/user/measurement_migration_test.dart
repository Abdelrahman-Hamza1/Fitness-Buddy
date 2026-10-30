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
// A15b took v10 after A23a's v9 (D20): a renumber changes these two
// imports and the two constants.
import 'generated/schema_v10.dart' as after;
import 'generated/schema_v9.dart' as before;

/// The schema version before the measurement step.
const _from = 9;

/// The version that adds `measurement_types` and `measurements`.
const _to = 10;

const _hlc = '1760351234567-00000-0199e3c2-5b1a-7c3d-8e4f-0123456789ab';
const _id = '0199e3c2-5b1a-7c3d-8e4f-0123456789ab';

/// Tables at [_from] seeded from the wire fixtures, with their entity and
/// fixture file (with [_handSeeded], every v$_from synced table).
const Map<String, (String, String)> _seeded = {
  'setting': ('settings_kv', _v1),
  'mealSlot': ('meal_slots', _v1),
  'dishGroup': ('dish_groups', _v1),
  'diaryEntry': ('diary_entries', _v1),
  'dayMark': ('day_marks', _v1),
  'savedMeal': ('saved_meals', _v1),
  'savedMealItem': ('saved_meal_items', _v1),
  'personalFood': ('personal_foods', _v1),
  'profile': ('profile', _v1),
  'goalPhase': ('goal_phases', _v1),
  'targetSettings': ('target_settings', _v1),
  'weighIn': ('weigh_ins', _v2),
};

/// The v$_from tables seeded by hand (chat with A23a's local columns, A23a's
/// proposals, A36 workouts): their content columns.
const Map<String, Map<String, Object?>> _handSeeded = {
  'chat_messages': {
    'role': 'user',
    'message_text': 'bench 3x8 80',
    'status': 'done',
    'language': null,
    'reply_to_message_id': null,
    'codec_version': null,
    'budget_json': null,
    // A23a's local-only columns (v9).
    'request_json': '{"q":1}',
    'answer_json': null,
  },
  // A23a's durable proposals (v9).
  'proposals': {
    'kind': 'foodLog',
    'status': 'pending',
    'outcome': null,
    'resolved_at': null,
    'origin_message_id': _id,
    'budget_message_id': _id,
    'codec_version': 2,
    'interpretation_json': '[]',
    'draft_json': '{}',
  },
  'custom_exercises': {
    'name': 'Cable fly',
    'aliases_json': '[]',
    'exercise_type': 'weight_reps',
    'equipment': 'cable',
  },
  'workout_sessions': {
    'local_date': '2026-10-18',
    'name': null,
    'start_minute': null,
    'duration_minutes': null,
    'template_id': null,
  },
  'session_exercises': {'session_id': _id, 'exercise_id': _id, 'position': 0},
  'workout_sets': {
    'session_exercise_id': _id,
    'position': 0,
    'reps': 8,
    'kg': 80.0,
    'input_value': 80.0,
    'input_unit': 'kg',
    'duration_seconds': null,
    'distance_meters': null,
  },
  'workout_templates': {'name': 'Push'},
  'workout_template_items': {
    'template_id': _id,
    'exercise_id': _id,
    'position': 0,
    'target_sets': 3,
    'target_reps': 8,
  },
  'weekly_plan_days': {'weekday': 6, 'template_id': null},
};

const _v1 = '../../contracts/testdata/sync/entity-payloads.json';
const _v2 = '../../contracts/testdata/sync/entity-payloads-v2.json';

/// The measurement entities and their tables.
const _measurementTables = {
  'measurementType': 'measurement_types',
  'measurement': 'measurements',
};

String _snake(String s) =>
    s.replaceAllMapped(RegExp('[A-Z]'), (m) => '_${m[0]!.toLowerCase()}');

Map<String, dynamic> _json(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

/// [payload] as SQL column values (snake_case, booleans as 0/1) with sync
/// metadata, as row [id].
Map<String, Object?> _row(Map<String, dynamic> payload, {String id = _id}) => {
  'id': id,
  'created_at': 0,
  'updated_hlc': _hlc,
  'version': 1,
  'device_id': _id,
  'deleted_at': null,
  for (final f in payload.entries)
    if (f.key != 'createdAtMs')
      _snake(f.key): f.value is bool ? (f.value == true ? 1 : 0) : f.value,
};

String _insert(String table, Map<String, Object?> values) =>
    'INSERT INTO $table (${values.keys.join(',')}) '
    'VALUES (${List.filled(values.length, '?').join(',')})';

Future<List<String>> _names(
  GeneratedDatabase db,
  String type,
  String table,
) async => [
  for (final r
      in await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = '$type' "
            "AND tbl_name = '$table' ORDER BY name",
          )
          .get())
    r.read<String>('name'),
];

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final verifier = SchemaVerifier(GeneratedHelper());

  test('A15b migration v$_from→v$_to keeps every v$_from row and queued '
      'outbox entry and adds measurement_types and measurements with their '
      'index and six triggers', () async {
    final seeded = <String, List<Map<String, Object?>>>{};
    var outboxBefore = 0;
    await verifier.testWithDataIntegrity(
      oldVersion: _from,
      newVersion: _to,
      createOld: before.DatabaseAtV9.new,
      createNew: after.DatabaseAtV10.new,
      openTestedDatabase: AppDatabase.new,
      createItems: (batch, db) {
        batch.customStatement(
          "INSERT INTO sync_state (key,value) VALUES ('outbox.capture','1')",
        );
        for (final MapEntry(key: entity, value: (table, file))
            in _seeded.entries) {
          final values = _row(_json(file)[entity] as Map<String, dynamic>);
          batch.customStatement(_insert(table, values), values.values.toList());
          seeded[table] = [values];
        }
        for (final MapEntry(key: table, value: content)
            in _handSeeded.entries) {
          final values = {
            'id': _id,
            'created_at': 0,
            'updated_hlc': _hlc,
            'version': 1,
            'device_id': _id,
            'deleted_at': null,
            'origin': 'direct',
            'edited_by_user': 0,
            ...content,
          };
          batch.customStatement(_insert(table, values), values.values.toList());
          seeded[table] = [values];
        }
        // Every insert queued one outbox row through the v9 triggers.
        outboxBefore = _seeded.length + _handSeeded.length;
      },
      validateItems: (db) async {
        for (final MapEntry(key: table, value: rows) in seeded.entries) {
          final now = await db.customSelect('SELECT * FROM $table').get();
          expect(now.map((r) => r.data).toList(), rows, reason: table);
        }
        expect(await db.select(db.syncOutbox).get(), hasLength(outboxBefore));
        expect(await db.select(db.measurementTypes).get(), isEmpty);
        expect(await db.select(db.measurements).get(), isEmpty);
        for (final table in _measurementTables.values) {
          expect(await _names(db, 'trigger', table), [
            '${table}_no_delete',
            '${table}_outbox_ai',
            '${table}_outbox_au',
          ]);
        }
        final columns = await db
            .customSelect('PRAGMA index_info(ix_measurements_live)')
            .get();
        expect(columns.map((r) => r.read<String>('name')), [
          'kind',
          'custom_type_id',
          'local_date',
          'measured_at_utc',
        ]);
        final plan = await db
            .customSelect(
              'EXPLAIN QUERY PLAN SELECT * FROM measurements '
              "WHERE kind = 'waist' AND custom_type_id IS NULL "
              'AND deleted_at IS NULL ORDER BY local_date, measured_at_utc',
            )
            .get();
        expect(
          plan.map((r) => r.read<String>('detail')).join(),
          contains('ix_measurements_live'),
        );

        // Capture works after the upgrade, and the wire CHECKs hold.
        final fixtures = _json(_v1);
        for (final MapEntry(key: entity, value: table)
            in _measurementTables.entries) {
          final row = _row(fixtures[entity] as Map<String, dynamic>);
          await db.customStatement(_insert(table, row), row.values.toList());
          expect((await db.select(db.syncOutbox).get()).last.entity, entity);
        }
        final waist = _row(
          fixtures['measurement'] as Map<String, dynamic>,
          id: '${_id.substring(0, 35)}c',
        );
        for (final (column, bad) in [
          ('kind', 'calf'),
          ('input_unit', 'mm'),
          ('value', -1.0),
          ('tz_offset_min', 900),
          ('measured_at_utc', -1),
        ]) {
          final row = {...waist, column: bad};
          await expectLater(
            db.customStatement(
              _insert('measurements', row),
              row.values.toList(),
            ),
            throwsA(predicate((e) => '$e'.contains('CHECK'))),
            reason: column,
          );
        }
      },
    );
  });

  test('A15b the measurementType and measurement fixtures and variants map '
      '1:1 to the table columns by snake_case, both directions; every content '
      'column is on the wire', () async {
    final db = memoryDatabase();
    final entities =
        _json('../../contracts/openapi/sync-entities.json')['entities']
            as Map<String, dynamic>;
    final fixtures = _json(_v1);
    final variants =
        (_json(
                  '../../contracts/testdata/sync/'
                  'measurement-payload-variants.json',
                )['cases']
                as List)
            .cast<Map<String, dynamic>>();
    Set<String> columnsOf(Iterable<String> fields) => {
      for (final field in fields)
        if (field == 'createdAtMs') 'created_at' else _snake(field),
    };
    var n = 0;
    for (final MapEntry(key: entity, value: table)
        in _measurementTables.entries) {
      final columns = {
        for (final r
            in await db
                .customSelect("SELECT name FROM pragma_table_info('$table')")
                .get())
          r.read<String>('name'),
      };
      final versions = entities[entity] as Map<String, dynamic>;
      expect(versions.keys, ['1'], reason: entity);
      final wire = columnsOf(
        ((versions['1'] as Map<String, dynamic>)['properties']
                as Map<String, dynamic>)
            .keys,
      );
      expect(columns.containsAll(wire), isTrue, reason: '$entity wire');
      expect(
        columns.difference(wire).difference(syncColumnNames.toSet()),
        isEmpty,
        reason:
            'every $table content column must be on the $entity wire; a new '
            'column needs a new wire version',
      );
      // Every payload stores in the columns as it is, with nothing added.
      final payloads = [
        fixtures[entity] as Map<String, dynamic>,
        for (final c in variants)
          if (c['entity'] == entity) c['payload'] as Map<String, dynamic>,
      ];
      expect(payloads.length, greaterThan(1), reason: '$entity variants');
      for (final payload in payloads) {
        expect(columnsOf(payload.keys), wire, reason: '$entity payload');
        final id =
            '${_id.substring(0, 34)}${(n++).toRadixString(16).padLeft(2, '0')}';
        final row = _row(payload, id: id);
        await runAuthorizedWrite(
          () => db.customStatement(_insert(table, row), row.values.toList()),
        );
        final stored = await db
            .customSelect(
              'SELECT * FROM $table WHERE id = ?',
              variables: [Variable(id)],
            )
            .getSingle();
        expect(stored.data, row, reason: '$entity ${payload.keys}');
      }
    }
  });
}
