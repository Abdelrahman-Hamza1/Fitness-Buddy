import 'dart:convert';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift_dev/api/migrations_native.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/db/sync/drift_sync_store.dart';
import 'package:fb_mobile/core/db/sync/sync_codec.dart';
import 'package:fb_sync/testing.dart' show SimClock;
import 'package:flutter_test/flutter_test.dart';

import 'generated/schema.dart';

// A renumber (another lane took v15 first) changes the two constants.

/// The schema version before the meal-estimate columns.
const _from = 14;

/// The version that adds `user_estimate` and `*_known` to `diary_entries`
/// and `saved_meal_items` (A62a D19).
const _to = 15;

const _hlc = '1760351234567-00000-0199e3c2-5b1a-7c3d-8e4f-0123456789ab';
const _hlc2 = '1760351234000-00000-0199e3c2-5b1a-7c3d-8e4f-0123456789ab';
const _device = '0199e3c2-5b1a-7c3d-8e4f-0123456789ab';

String _id(int n) =>
    '0199e3c2-5b1a-7c3d-8e4f-${n.toRadixString(16).padLeft(12, '0')}';

/// The food columns both tables share, at v14.
Map<String, Object?> _food(int n) => {
  'id': _id(n),
  'created_at': 1000 + n,
  'updated_hlc': _hlc,
  'version': 1 + n % 3,
  'device_id': _device,
  'deleted_at': n.isEven ? null : 5000,
  'origin': 'direct',
  'edited_by_user': n % 2,
  'food_kind': 'catalog',
  'food_id': 'usda:$n',
  'name_en': 'Food $n',
  'input_amount': 150.0,
  'input_unit': 'g',
  'amount': 150.0,
  'amount_basis': 'g',
  'per100_kcal': 130.0,
  'per100_protein_g': 2.7,
  'per100_carbs_g': 28.0,
  'per100_fat_g': 0.3,
  'per100_fiber_g': 0.4,
  'kcal': 195.0,
  'protein_g': 4.05,
  'carbs_g': 42.0,
  'fat_g': 0.45,
  'fiber_g': 0.6,
  'source': 'database',
  'is_estimate': 0,
};

String _insert(String table, Map<String, Object?> values) =>
    'INSERT INTO $table (${values.keys.join(', ')}) '
    'VALUES (${List.filled(values.length, '?').join(', ')})';

const _added = {
  'user_estimate': 0,
  'protein_known': 1,
  'carbs_known': 1,
  'fat_known': 1,
  'fiber_known': 1,
};

Future<List<Map<String, Object?>>> _all(AppDatabase db, String sql) async => [
  for (final r in await db.customSelect(sql).get()) r.data,
];

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final verifier = SchemaVerifier(GeneratedHelper());

  test('DY-005 migration 14→15: existing rows read as known non-estimates; '
      'every other column, tombstones and the outbox are kept; kept '
      'displaced snapshots gain the defaults and encode as v2; old refused '
      'versions are marked as possible downgrades (A62 D23)', () async {
    final rows = {
      'diary_entries': [
        for (final n in [1, 2])
          {
            ..._food(n),
            'local_date': '2026-10-24',
            'occurred_at_utc': 1792843200000,
            'tz_offset_min': 180,
            'slot_id': _id(90),
          },
      ],
      'saved_meal_items': [
        for (final n in [3, 4])
          {..._food(n), 'saved_meal_id': _id(91), 'sort_order': n},
      ],
    };
    final schema = await verifier.schemaAt(_from);
    final raw = schema.rawDatabase
      ..execute(
        "INSERT INTO sync_state (key,value) VALUES ('outbox.capture','1')",
      );
    for (final MapEntry(key: table, value: list) in rows.entries) {
      for (final values in list) {
        raw.execute(_insert(table, values), values.values.toList());
      }
    }
    // The complete rows before the migration (every column, nulls too).
    final before = {
      for (final table in rows.keys)
        table: [
          for (final r in raw.select('SELECT * FROM $table ORDER BY id'))
            Map<String, Object?>.of(r),
        ],
    };
    final outbox = [
      for (final r in raw.select('SELECT * FROM sync_outbox ORDER BY seq'))
        Map<String, Object?>.of(r),
    ];
    expect(outbox, hasLength(4));
    // Kept local versions: a diary entry and a saved-meal item waiting to
    // be pushed (v14 snapshots), and a setting (untouched).
    // A live entry's earlier version (its own HLC), kept whole.
    final entrySnapshot = jsonEncode({
      ...before['diary_entries']!.last,
      'updated_hlc': _hlc2,
    });
    final itemSnapshot = jsonEncode(before['saved_meal_items']!.first);
    const setting = '{"id":"x","value_json":"1"}';
    raw
      ..execute(
        'INSERT INTO sync_displaced (entity, row_id, hlc, row_json, '
        "parked_reason) VALUES ('diaryEntry', ?, ?, ?, NULL), "
        "('savedMealItem', ?, ?, ?, 'unsupported'), "
        "('setting', 'x', ?, ?, 'unsupported')",
        [
          _id(2),
          _hlc2,
          entrySnapshot,
          _id(3),
          _hlc,
          itemSnapshot,
          _hlc,
          setting,
        ],
      )
      ..execute(
        'INSERT INTO sync_parked (entity, row_id, hlc, reason, parked_at) '
        "VALUES ('diaryEntry', ?, ?, 'unsupported', 1), "
        "('diaryEntry', ?, ?, 'tooLarge', 1), "
        "('setting', 'y', ?, 'unsupported', 1)",
        [_id(2), _hlc, _id(5), _hlc, _hlc],
      );

    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, _to);

    for (final table in rows.keys) {
      expect(await _all(db, 'SELECT * FROM $table ORDER BY id'), [
        for (final row in before[table]!) {...row, ..._added},
      ], reason: '$table: the five defaults added, nothing else changed');
    }
    expect(
      await _all(db, 'SELECT * FROM sync_outbox ORDER BY seq'),
      outbox,
      reason: 'adding columns queues nothing',
    );

    final displaced = {
      for (final r in await _all(
        db,
        'SELECT entity, row_json, parked_reason, refused_schema '
        'FROM sync_displaced',
      ))
        r['entity']! as String: r,
    };
    for (final (entity, snapshot) in [
      ('diaryEntry', entrySnapshot),
      ('savedMealItem', itemSnapshot),
    ]) {
      expect(jsonDecode(displaced[entity]!['row_json']! as String), {
        ...(jsonDecode(snapshot) as Map<String, Object?>),
        ..._added,
      }, reason: '$entity snapshot: same content and HLC, defaults added');
    }
    expect(displaced['setting']!['row_json'], setting);
    expect(
      [
        for (final e in ['diaryEntry', 'savedMealItem', 'setting'])
          displaced[e]!['refused_schema'],
      ],
      [null, 1, null],
    );
    expect(
      await _all(
        db,
        'SELECT row_id, refused_schema FROM sync_parked ORDER BY row_id',
      ),
      [
        {'row_id': _id(2), 'refused_schema': 1},
        {'row_id': _id(5), 'refused_schema': null},
        {'row_id': 'y', 'refused_schema': null},
      ],
    );

    // The waiting diary snapshot now encodes as a valid v2 payload.
    final store = DriftSyncStore(
      db,
      codecs: columnSyncCodecs(db.syncedTables),
      clock: SimClock(DateTime.utc(2026, 11, 6)),
      deviceId: () async => _device,
      exclusive: <T>(body) => body(),
    );
    final read = await store.pending(limit: 100);
    expect(read.parkedNow, isEmpty);
    final change = read.changes.singleWhere(
      (c) => c.entity == 'diaryEntry' && c.hlc == _hlc2,
    );
    expect(change.schemaVersion, 2);
    expect(change.payload, containsPair('userEstimate', false));
    for (final known in ['protein', 'carbs', 'fat', 'fiber']) {
      expect(change.payload, containsPair('${known}Known', true));
    }
  });
}
