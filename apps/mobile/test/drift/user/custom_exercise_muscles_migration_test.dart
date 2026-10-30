import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift_dev/api/migrations_native.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

import 'generated/schema.dart';
// A renumber (another lane took v11 first, A37 R2) changes these two imports
// and the two constants.
import 'generated/schema_v10.dart' as before;
import 'generated/schema_v11.dart' as after;

/// The schema version before the custom-exercise muscles step.
const _from = 10;

/// The version that adds `custom_exercises.primary_muscle` and
/// `secondary_muscles_json` (A37 D6).
const _to = 11;

const _hlc = '1760351234567-00000-0199e3c2-5b1a-7c3d-8e4f-0123456789ab';
const _device = '0199e3c2-5b1a-7c3d-8e4f-0123456789ab';

/// Row [n]'s ID.
String _id(int n) =>
    '0199e3c2-5b1a-7c3d-8e4f-${n.toRadixString(16).padLeft(12, '0')}';

/// Tables at [_from] seeded from the wire fixtures: entity → (table, file).
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
  'measurementType': ('measurement_types', _v1),
  'measurement': ('measurements', _v1),
};

const _v1 = '../../contracts/testdata/sync/entity-payloads.json';
const _v2 = '../../contracts/testdata/sync/entity-payloads-v2.json';

String _snake(String s) =>
    s.replaceAllMapped(RegExp('[A-Z]'), (m) => '_${m[0]!.toLowerCase()}');

Map<String, dynamic> _json(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

/// Sync metadata of row [n]: varied versions, origins, provenance and
/// tombstones, so the migration must keep every column as it was.
Map<String, Object?> _meta(int n, {bool deleted = false}) => {
  'id': _id(n),
  'created_at': 1000 + n,
  'updated_hlc': _hlc,
  'version': 1 + n % 4,
  'device_id': _device,
  'deleted_at': deleted ? 5000 + n : null,
  'origin': switch (n % 3) {
    0 => 'direct',
    1 => 'undo:${_id(900)}',
    _ => 'proposal:${_id(901)}',
  },
  'edited_by_user': n % 2,
};

/// Every workout aggregate at v$_from: custom exercises (one tombstoned),
/// a session with a live and a tombstoned exercise and set, a tombstoned
/// session, a template with items, and plan days (one rest day).
final Map<String, List<Map<String, Object?>>> _workouts = {
  'custom_exercises': [
    {
      ..._meta(1),
      'name': 'Cable fly',
      'aliases_json': '["fly"]',
      'exercise_type': 'weight_reps',
      'equipment': 'cable',
    },
    {
      ..._meta(2, deleted: true),
      'name': 'Old thing',
      'aliases_json': '[]',
      'exercise_type': 'duration',
      'equipment': 'other',
    },
  ],
  'workout_sessions': [
    {
      ..._meta(10),
      'local_date': '2026-10-18',
      'name': 'Push',
      'start_minute': 1080,
      'duration_minutes': 60,
      'template_id': _id(40),
    },
    {
      ..._meta(11, deleted: true),
      'local_date': '2026-10-17',
      'name': null,
      'start_minute': null,
      'duration_minutes': null,
      'template_id': null,
    },
  ],
  'session_exercises': [
    {..._meta(20), 'session_id': _id(10), 'exercise_id': _id(1), 'position': 0},
    {
      ..._meta(21, deleted: true),
      'session_id': _id(10),
      'exercise_id': 'ex:barbell_bench_press',
      'position': 1,
    },
  ],
  'workout_sets': [
    {
      ..._meta(30),
      'session_exercise_id': _id(20),
      'position': 0,
      'reps': 8,
      'kg': 80.0,
      'input_value': 176.0,
      'input_unit': 'lb',
      'duration_seconds': null,
      'distance_meters': null,
    },
    {
      ..._meta(31, deleted: true),
      'session_exercise_id': _id(21),
      'position': 0,
      'reps': 5,
      'kg': 100.0,
      'input_value': 100.0,
      'input_unit': 'kg',
      'duration_seconds': null,
      'distance_meters': null,
    },
  ],
  'workout_templates': [
    {..._meta(40), 'name': 'Push'},
  ],
  'workout_template_items': [
    {
      ..._meta(41),
      'template_id': _id(40),
      'exercise_id': _id(1),
      'position': 0,
      'target_sets': 3,
      'target_reps': 12,
    },
  ],
  'weekly_plan_days': [
    {..._meta(50), 'weekday': 6, 'template_id': _id(40)},
    {..._meta(51), 'weekday': 7, 'template_id': null},
  ],
};

/// [payload] as SQL column values with sync metadata, as row [n].
Map<String, Object?> _row(Map<String, dynamic> payload, int n) => {
  ..._meta(n)
    ..remove('origin')
    ..remove('edited_by_user'),
  for (final f in payload.entries)
    if (f.key != 'createdAtMs')
      _snake(f.key): f.value is bool ? (f.value == true ? 1 : 0) : f.value,
};

String _insert(String table, Map<String, Object?> values) =>
    'INSERT INTO $table (${values.keys.join(',')}) '
    'VALUES (${List.filled(values.length, '?').join(',')})';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final verifier = SchemaVerifier(GeneratedHelper());

  test('migration v10→v11 preserves custom exercises, every workout '
      'aggregate, tombstones, sync metadata and queued outbox rows, adds '
      'empty muscles, and writes no outbox rows', () async {
    final seeded = <String, List<Map<String, Object?>>>{};
    var outboxBefore = <Map<String, Object?>>[];
    await verifier.testWithDataIntegrity(
      oldVersion: _from,
      newVersion: _to,
      createOld: before.DatabaseAtV10.new,
      createNew: after.DatabaseAtV11.new,
      openTestedDatabase: AppDatabase.new,
      createItems: (batch, db) {
        batch.customStatement(
          "INSERT INTO sync_state (key,value) VALUES ('outbox.capture','1')",
        );
        var n = 100;
        for (final MapEntry(key: entity, value: (table, file))
            in _seeded.entries) {
          final values = _row(_json(file)[entity] as Map<String, dynamic>, n++);
          batch.customStatement(_insert(table, values), values.values.toList());
          seeded[table] = [values];
        }
        for (final MapEntry(key: table, value: rows) in _workouts.entries) {
          for (final values in rows) {
            batch.customStatement(
              _insert(table, values),
              values.values.toList(),
            );
          }
          seeded[table] = rows;
        }
        // A queued outbox row of an older write, beside the triggers' rows.
        batch.customStatement(
          'INSERT INTO sync_outbox (entity, row_id, hlc, deleted) '
          "VALUES ('workoutSet', ?, ?, 1)",
          [_id(31), _hlc],
        );
      },
      validateItems: (db) async {
        outboxBefore = [
          for (final r
              in await db
                  .customSelect('SELECT * FROM sync_outbox ORDER BY seq')
                  .get())
            r.data,
        ];
        // One queued row per seeded row (the v10 triggers) plus the extra.
        final rowCount = seeded.values.fold(
          0,
          (sum, rows) => sum + rows.length,
        );
        expect(outboxBefore, hasLength(rowCount + 1));
        for (final MapEntry(key: table, value: rows) in seeded.entries) {
          final now = await db
              .customSelect('SELECT * FROM $table ORDER BY id')
              .get();
          final expected = [
            for (final row in rows)
              if (table == 'custom_exercises')
                {...row, 'primary_muscle': null, 'secondary_muscles_json': '[]'}
              else
                row,
          ]..sort((a, b) => (a['id']! as String).compareTo(b['id']! as String));
          expect(
            [
              for (final r in now)
                {for (final k in expected.first.keys) k: r.data[k]},
            ],
            expected,
            reason: table,
          );
          expect(
            now.first.data.keys.toSet(),
            expected.first.keys.toSet(),
            reason: '$table has exactly the expected columns',
          );
        }

        // The new columns hold their CHECK and capture still works.
        final fly = {
          ..._workouts['custom_exercises']!.first,
          'id': _id(3),
          'primary_muscle': 'chest',
          'secondary_muscles_json': '["triceps"]',
        };
        await db.customStatement(_insert('custom_exercises', fly), [
          ...fly.values,
        ]);
        final outbox = await db.select(db.syncOutbox).get();
        expect(outbox, hasLength(outboxBefore.length + 1));
        expect(outbox.last.entity, 'customExercise');
        final legacy = {...fly, 'id': _id(4), 'primary_muscle': 'back'};
        await expectLater(
          db.customStatement(
            _insert('custom_exercises', legacy),
            legacy.values.toList(),
          ),
          throwsA(predicate((e) => '$e'.contains('CHECK'))),
        );
      },
    );
  });
}
