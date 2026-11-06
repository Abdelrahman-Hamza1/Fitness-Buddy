import 'dart:convert';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift_dev/api/migrations_native.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/db/sync/drift_sync_store.dart';
import 'package:fb_mobile/core/db/sync/sync_codec.dart';
import 'package:fb_sync/testing.dart' show SimClock;
import 'package:flutter_test/flutter_test.dart';

import 'generated/schema.dart';

// A renumber (another lane took v16 first) changes the two constants.

/// The schema version before the day estimate.
const _from = 15;

/// The version that adds `day_marks.estimate_kcal` and `estimate_only`
/// (A62b D19).
const _to = 16;

const _hlc = '1760351234567-00000-0199e3c2-5b1a-7c3d-8e4f-0123456789ab';
const _hlc2 = '1760351234000-00000-0199e3c2-5b1a-7c3d-8e4f-0123456789ab';
const _device = '0199e3c2-5b1a-7c3d-8e4f-0123456789ab';

String _id(int n) =>
    '0199e3c2-5b1a-7c3d-8e4f-${n.toRadixString(16).padLeft(12, '0')}';

/// A day mark at v15.
Map<String, Object?> _mark(int n) => {
  'id': _id(n),
  'created_at': 1000 + n,
  'updated_hlc': _hlc,
  'version': 1 + n % 3,
  'device_id': _device,
  'deleted_at': n == 3 ? 5000 : null,
  'origin': 'direct',
  'edited_by_user': 1,
  'local_date': '2026-10-1$n',
  'incomplete': n % 2,
  'not_fasting': n == 2 ? 1 : 0,
};

String _insert(String table, Map<String, Object?> values) =>
    'INSERT INTO $table (${values.keys.join(', ')}) '
    'VALUES (${List.filled(values.length, '?').join(', ')})';

Future<List<Map<String, Object?>>> _all(AppDatabase db, String sql) async => [
  for (final r in await db.customSelect(sql).get()) r.data,
];

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final verifier = SchemaVerifier(GeneratedHelper());

  test('DY-006 migration 15→16: existing marks read as "no estimate"; every '
      'other column, tombstones and the outbox are kept; kept displaced '
      'marks gain estimate_kcal and encode as v2; old refused day marks are '
      'marked as possible downgrades (A62 D23)', () async {
    final marks = [
      for (final n in [1, 2, 3]) _mark(n),
    ];
    final schema = await verifier.schemaAt(_from);
    final raw = schema.rawDatabase
      ..execute(
        "INSERT INTO sync_state (key,value) VALUES ('outbox.capture','1')",
      );
    for (final values in marks) {
      raw.execute(_insert('day_marks', values), values.values.toList());
    }
    final before = [
      for (final r in raw.select('SELECT * FROM day_marks ORDER BY id'))
        Map<String, Object?>.of(r),
    ];
    final outbox = [
      for (final r in raw.select('SELECT * FROM sync_outbox ORDER BY seq'))
        Map<String, Object?>.of(r),
    ];
    expect(outbox, hasLength(3));
    // Kept local versions: a mark's earlier version waiting to be pushed, a
    // parked one, and a diary entry already marked by 14 → 15 (untouched).
    final markSnapshot = jsonEncode({...before.first, 'updated_hlc': _hlc2});
    const entry = '{"id":"e"}';
    raw
      ..execute(
        'INSERT INTO sync_displaced (entity, row_id, hlc, row_json, '
        "parked_reason, refused_schema) VALUES ('dayMark', ?, ?, ?, NULL, "
        "NULL), ('dayMark', ?, ?, ?, 'unsupported', NULL), "
        "('diaryEntry', 'e', ?, ?, 'unsupported', 1)",
        [
          _id(1),
          _hlc2,
          markSnapshot,
          _id(2),
          _hlc2,
          jsonEncode({...before[1], 'updated_hlc': _hlc2}),
          _hlc,
          entry,
        ],
      )
      ..execute(
        'INSERT INTO sync_parked (entity, row_id, hlc, reason, parked_at, '
        "refused_schema) VALUES ('dayMark', ?, ?, 'unsupported', 1, NULL), "
        "('dayMark', ?, ?, 'tooLarge', 1, NULL), "
        "('diaryEntry', 'e', ?, 'unsupported', 1, 2), "
        "('setting', 'y', ?, 'unsupported', 1, NULL)",
        [_id(2), _hlc, _id(3), _hlc, _hlc, _hlc],
      );

    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, _to);

    expect(
      await _all(db, 'SELECT * FROM day_marks ORDER BY id'),
      [
        for (final row in before)
          {...row, 'estimate_kcal': null, 'estimate_only': 0},
      ],
      reason:
          'estimate_kcal null and estimate_only 0 added, nothing else '
          'changed',
    );
    expect(
      await _all(db, 'SELECT * FROM sync_outbox ORDER BY seq'),
      outbox,
      reason: 'adding a column queues nothing',
    );

    final displaced = await _all(
      db,
      'SELECT entity, row_id, row_json, refused_schema FROM sync_displaced '
      'ORDER BY entity, row_id',
    );
    expect(jsonDecode(displaced[0]['row_json']! as String), {
      ...(jsonDecode(markSnapshot) as Map<String, Object?>),
      'estimate_kcal': null,
      'estimate_only': 0,
    }, reason: 'same content and HLC, estimate_kcal and estimate_only added');
    expect(
      [for (final d in displaced) d['refused_schema']],
      [null, 1, 1],
      reason: 'a parked v1 mark is a possible downgrade; the entry keeps 1',
    );
    expect(displaced[2]['row_json'], entry);
    expect(
      await _all(
        db,
        'SELECT entity, row_id, refused_schema FROM sync_parked '
        'ORDER BY entity, row_id',
      ),
      [
        {'entity': 'dayMark', 'row_id': _id(2), 'refused_schema': 1},
        {'entity': 'dayMark', 'row_id': _id(3), 'refused_schema': null},
        {'entity': 'diaryEntry', 'row_id': 'e', 'refused_schema': 2},
        {'entity': 'setting', 'row_id': 'y', 'refused_schema': null},
      ],
    );

    // The waiting mark snapshot now encodes as a valid v2 payload.
    final store = DriftSyncStore(
      db,
      codecs: columnSyncCodecs(db.syncedTables),
      clock: SimClock(DateTime.utc(2026, 11, 6)),
      deviceId: () async => _device,
      exclusive: <T>(body) => body(),
    );
    final read = await store.pending(limit: 100);
    final change = read.changes.singleWhere(
      (c) => c.entity == 'dayMark' && c.hlc == _hlc2,
    );
    expect(change.schemaVersion, 2);
    expect(change.payload, containsPair('estimateKcal', null));
    expect(change.payload, containsPair('estimateOnly', false));
    expect(change.payload, containsPair('incomplete', true));
  });
}
