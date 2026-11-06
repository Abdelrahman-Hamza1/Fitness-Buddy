import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Variable, driftRuntimeOptions;
import 'package:drift_dev/api/migrations_native.dart';
import 'package:fb_api_client/fb_api_client.dart' hide LocalDate;
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/db/natural_id.dart';
import 'package:fb_mobile/core/db/sync/drift_sync_store.dart';
import 'package:fb_mobile/core/sync/downgrade_recovery.dart';
import 'package:fb_sync/fb_sync.dart';
import 'package:fb_sync/testing.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../drift/user/generated/schema.dart';
import '../db/support/db_support.dart';
import '../db/sync/sync_support.dart';

// TD-114, A62 D23 (review fixes): a version the server refused as a schema
// downgrade is resolved against the server's current row before any retry,
// whatever the cursor and the deferred set hold.

Map<String, Object?> _fixture(String file, String entity) =>
    ((jsonDecode(File('../../contracts/testdata/sync/$file').readAsStringSync())
                as Map)[entity]!
            as Map)
        .cast<String, Object?>();

const _other = '0199e3c2-5b1a-7000-8000-000000000002';
const _h1 = '1760351230000-00000-$_other';
const _h2 = '1760351231000-00000-$_other';
const _h3 = '1760351232000-00000-$testDevice';
const _id = '0199e3c2-5b1a-7c3d-8e4f-000000000001';

/// The row ID of [entity]'s fixture row: a day mark's is natural (TD-070).
String _idOf(String entity) =>
    entity == 'dayMark' ? naturalId('dayMark', '2026-10-18') : _id;

SyncChange _change(
  String entity,
  Map<String, Object?> payload, {
  required String hlc,
  required int schema,
  String device = _other,
}) => SyncChange(
  entity: entity,
  id: _idOf(entity),
  schemaVersion: schema,
  hlc: hlc,
  deviceId: device,
  deletedAt: null,
  payload: payload,
);

/// Records what the phone pushes.
final class _Recording implements SyncTransport {
  new(this.inner);
  final FakeSyncServer inner;
  final List<SyncChange> pushed = [];
  final List<SyncPushResult> results = [];

  @override
  Future<SyncPushResponse> push(
    List<SyncChange> changes, {
    required String? datasetId,
  }) async {
    pushed.addAll(changes);
    final response = await inner.push(changes, datasetId: datasetId);
    results.addAll(response.results);
    return response;
  }

  @override
  Future<SyncPage> pull({
    required String cursor,
    required int limit,
    required String? datasetId,
  }) => inner.pull(cursor: cursor, limit: limit, datasetId: datasetId);

  @override
  Future<SyncPage> itemHistory(
    String entity,
    String id, {
    required String cursor,
    required int limit,
    required String? datasetId,
  }) => inner.itemHistory(
    entity,
    id,
    cursor: cursor,
    limit: limit,
    datasetId: datasetId,
  );
}

/// A server holding [entity] v1 at h1, then v2 (an estimate) at h2 from
/// the upgraded phone; the old build's v1 edit at h3 was refused.
Future<FakeSyncServer> _server(SimClock clock, String entity) async {
  final server = FakeSyncServer(clock)..downgradeProtected = {entity};
  Future<String> push(SyncChange c) async => (await server.push([
    c,
  ], datasetId: server.datasetId)).results.single.status;
  final v1 = _fixture('entity-payloads.json', entity);
  expect(await push(_change(entity, v1, hlc: _h1, schema: 1)), 'accepted');
  final v2 = _fixture('entity-payloads-v2.json', entity);
  expect(await push(_change(entity, v2, hlc: _h2, schema: 2)), 'accepted');
  final refused = await server.push([
    _change(
      entity,
      entity == 'dayMark'
          ? {...v1, 'incomplete': true}
          : {...v1, 'nameEn': 'Old edit'},
      hlc: _h3,
      schema: 1,
      device: testDevice,
    ),
  ], datasetId: server.datasetId);
  expect(refused.results.single.reason, 'unsupported');
  return server;
}

SyncEngine _engine(
  DriftSyncStore store,
  SyncTransport transport, {
  String appVersion = 'new',
}) => SyncEngine(
  store: store,
  transport: transport,
  afterDeferredRetry: () => retryParkedSafely(
    store: store,
    transport: transport,
    nowMs: syncBase.millisecondsSinceEpoch,
    appVersion: appVersion,
  ),
);

/// The v14 columns of a food row of [entity] (the old build's local copy).
Map<String, Object?> _v14Row(String entity) => {
  'id': _id,
  'created_at': 1,
  'updated_hlc': _h3,
  'version': 2,
  'device_id': testDevice,
  'deleted_at': null,
  'origin': 'direct',
  'edited_by_user': 1,
  'food_kind': 'catalog',
  'food_id': 'usda:1',
  'name_en': 'Old edit',
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
  if (entity == 'diaryEntry') ...{
    'local_date': '2026-10-18',
    'occurred_at_utc': 1792299600000,
    'tz_offset_min': 180,
    'slot_id': _other,
  } else ...{
    'saved_meal_id': _other,
    'sort_order': 0,
  },
};

String _tableOf(String entity) =>
    entity == 'diaryEntry' ? 'diary_entries' : 'saved_meal_items';

Future<Map<String, Object?>> _row(AppDatabase db, String entity) async =>
    (await db
            .customSelect(
              'SELECT * FROM ${_tableOf(entity)} WHERE id = ?',
              variables: [Variable.withString(_id)],
            )
            .getSingle())
        .data;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final verifier = SchemaVerifier(GeneratedHelper());

  for (final entity in ['diaryEntry', 'savedMealItem']) {
    test('D23 $entity: the real old-client sequence (the old build skipped '
        'the v2 by HLC, moved its cursor on, deferred nothing) → update → '
        'sync applies the server v2 and keeps the old edit displaced, never '
        'pushed again (no versionConflict)', () async {
      final clock = SimClock(syncBase);
      final server = await _server(clock, entity);
      final transport = _Recording(server);

      // The old build's database (v14): its edit at h3, parked by the
      // server's refusal; the cursor already past h2; no deferred row.
      final schema = await verifier.schemaAt(14);
      final row = _v14Row(entity);
      schema.rawDatabase
        ..execute(
          'INSERT INTO ${_tableOf(entity)} (${row.keys.join(', ')}) '
          'VALUES (${List.filled(row.length, '?').join(', ')})',
          row.values.toList(),
        )
        ..execute('DELETE FROM sync_outbox')
        ..execute(
          'INSERT INTO sync_parked (entity, row_id, hlc, reason, parked_at) '
          "VALUES (?, ?, ?, 'unsupported', 1)",
          [entity, _id, _h3],
        )
        ..execute(
          'INSERT INTO sync_state (key, value) VALUES '
          "('sync.cursor', '2'), ('sync.dataset', ?), ('hlc.last', ?), "
          "('sync.appVersion', 'old'), ('sync.parkedRetryMs', ?)",
          [server.datasetId, _h3, syncBase.millisecondsSinceEpoch],
        );

      final db = AppDatabase(schema.newConnection());
      addTearDown(db.close);
      await verifier.migrateAndValidate(db, db.schemaVersion);
      final store = driftStore(db, clock: clock);
      expect(await store.refusedDowngrades(), {(entity: entity, id: _id)});

      await _engine(store, transport).run();

      final now = await _row(db, entity);
      final v2 = _fixture('entity-payloads-v2.json', entity);
      expect(now['updated_hlc'], _h2, reason: 'the server v2 is the winner');
      expect(now['user_estimate'], 1);
      expect(now['name_en'], v2['nameEn']);
      expect(now['carbs_known'], v2['carbsKnown']! as bool ? 1 : 0);
      final displaced = await db
          .customSelect(
            'SELECT hlc, parked_reason, refused_schema, row_json '
            'FROM sync_displaced',
          )
          .getSingle();
      expect(displaced.read<String>('hlc'), _h3);
      expect(displaced.read<String>('parked_reason'), supersededReason);
      expect(displaced.readNullable<int>('refused_schema'), isNull);
      expect(
        (jsonDecode(displaced.read<String>('row_json')) as Map)['name_en'],
        'Old edit',
        reason: 'the old edit is kept for the user',
      );
      expect(await db.customSelect('SELECT * FROM sync_parked').get(), isEmpty);
      expect(
        transport.pushed.where((c) => c.hlc == _h3),
        isEmpty,
        reason: 'a v2 re-encode under h3 would be a versionConflict',
      );
      expect(
        transport.results.where((r) => r.reason == 'versionConflict'),
        isEmpty,
      );
      expect(server.documents['$entity/$_id']!.hlc, _h2);
      final counts = await store.counts();
      expect((counts.pendingRows, counts.parked), (0, 0));
      expect(await store.retryParked(), 0);

      // A second run changes nothing.
      await _engine(store, transport).run();
      expect((await _row(db, entity))['updated_hlc'], _h2);
    });
  }

  test('DY-006 D23 dayMark: existing v1 mark → remote v2 estimate → the old '
      "client's incomplete flag edit: the server refused it; after the "
      'update the recovery keeps v2 and the edit is displaced, never pushed '
      'again', () async {
    final clock = SimClock(syncBase);
    final server = await _server(clock, 'dayMark');
    final transport = _Recording(server);
    final id = _idOf('dayMark');

    // The old build's database (v14): its incomplete edit at h3, parked by
    // the server's refusal; the cursor past h2; nothing deferred.
    final schema = await verifier.schemaAt(14);
    final row = {
      'id': id,
      'created_at': 1,
      'updated_hlc': _h3,
      'version': 2,
      'device_id': testDevice,
      'deleted_at': null,
      'origin': 'direct',
      'edited_by_user': 1,
      'local_date': '2026-10-18',
      'incomplete': 1,
      'not_fasting': 0,
    };
    schema.rawDatabase
      ..execute(
        'INSERT INTO day_marks (${row.keys.join(', ')}) '
        'VALUES (${List.filled(row.length, '?').join(', ')})',
        row.values.toList(),
      )
      ..execute('DELETE FROM sync_outbox')
      ..execute(
        'INSERT INTO sync_parked (entity, row_id, hlc, reason, parked_at) '
        "VALUES ('dayMark', ?, ?, 'unsupported', 1)",
        [id, _h3],
      )
      ..execute(
        'INSERT INTO sync_state (key, value) VALUES '
        "('sync.cursor', '2'), ('sync.dataset', ?), ('hlc.last', ?), "
        "('sync.appVersion', 'old'), ('sync.parkedRetryMs', ?)",
        [server.datasetId, _h3, syncBase.millisecondsSinceEpoch],
      );

    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, db.schemaVersion);
    final store = driftStore(db, clock: clock);
    expect(await store.refusedDowngrades(), {(entity: 'dayMark', id: id)});

    await _engine(store, transport).run();

    final now =
        (await db
                .customSelect(
                  'SELECT * FROM day_marks WHERE id = ?',
                  variables: [Variable.withString(id)],
                )
                .getSingle())
            .data;
    final v2 = _fixture('entity-payloads-v2.json', 'dayMark');
    expect(now['updated_hlc'], _h2, reason: 'the server v2 is the winner');
    expect(now['estimate_kcal'], v2['estimateKcal']);
    expect(now['incomplete'], 0);
    final displaced = await db
        .customSelect('SELECT hlc, parked_reason, row_json FROM sync_displaced')
        .getSingle();
    expect(displaced.read<String>('hlc'), _h3);
    expect(displaced.read<String>('parked_reason'), supersededReason);
    expect(
      (jsonDecode(displaced.read<String>('row_json')) as Map)['incomplete'],
      1,
      reason: 'the old edit is kept for the user',
    );
    expect(transport.pushed.where((c) => c.hlc == _h3), isEmpty);
    expect(server.documents['dayMark/$id']!.hlc, _h2);
    final counts = await store.counts();
    expect((counts.pendingRows, counts.parked), (0, 0));
  });

  test('D23 an old build that had deferred the v2: the deferred retry '
      'skips it by HLC, the recovery still applies it', () async {
    final clock = SimClock(syncBase);
    final server = await _server(clock, 'diaryEntry');
    final db = memoryDatabase();
    final store = driftStore(db, clock: clock);
    await _engine(store, server).run();
    await writeRaw(
      db,
      "UPDATE diary_entries SET name_en = 'Old edit', updated_hlc = '$_h3' "
      "WHERE id = '$_id'",
    );
    await writeRaw(db, 'DELETE FROM sync_outbox');
    // What the migration leaves for an old build's refused edit.
    await writeRaw(
      db,
      'INSERT INTO sync_parked (entity, row_id, hlc, reason, parked_at, '
      "refused_schema) VALUES ('diaryEntry', '$_id', '$_h3', "
      "'unsupported', 1, 1)",
    );
    final deferred = server.documents['diaryEntry/$_id']!;
    await writeRaw(
      db,
      'INSERT INTO sync_deferred (entity, row_id, hlc, document_json, '
      "reason) VALUES ('diaryEntry', '$_id', '$_h2', "
      "'${jsonEncode(deferred.toJson()).replaceAll("'", "''")}', "
      "'newerSchema')",
    );
    await _engine(store, server, appVersion: 'newer').run();
    expect((await _row(db, 'diaryEntry'))['updated_hlc'], _h2);
    final displaced = await db
        .customSelect('SELECT hlc, parked_reason FROM sync_displaced')
        .getSingle();
    expect(displaced.data, {'hlc': _h3, 'parked_reason': supersededReason});
    expect(await db.customSelect('SELECT * FROM sync_deferred').get(), isEmpty);
  });

  test(
    'D23 a refused downgrade is never retried before the recovery: '
    '"Try again" leaves it parked; an offline recovery resolves nothing',
    () async {
      final clock = SimClock(syncBase);
      final server = await _server(clock, 'diaryEntry');
      final db = memoryDatabase();
      final store = driftStore(db, clock: clock);
      await _engine(store, server).run();
      await writeRaw(
        db,
        "UPDATE diary_entries SET updated_hlc = '$_h3' WHERE id = '$_id'",
      );
      await writeRaw(db, 'DELETE FROM sync_outbox');
      await store.settle(
        parked: [
          const ParkedVersion(
            SyncVersion('diaryEntry', _id, _h3),
            'unsupported',
          ),
        ],
      );
      final parked = await db
          .customSelect('SELECT refused_schema FROM sync_parked')
          .getSingle();
      expect(parked.read<int>('refused_schema'), 2, reason: 'the sent schema');
      expect(await store.retryParked(), 0);
      expect((await store.pending(limit: 10)).changes, isEmpty);
      expect((await store.counts()).parked, 1);

      server.failNextPull = const SyncFailure(SyncFailureKind.offline);
      await expectLater(
        _engine(store, server, appVersion: 'newer').run(),
        throwsA(isA<SyncFailure>()),
      );
      expect(await store.refusedDowngrades(), hasLength(1));
    },
  );

  test(
    'D23 only a real downgrade is superseded: a newer v2 edit parked for '
    'another reason, or refused at the same schema, keeps HLC rules',
    () async {
      final clock = SimClock(syncBase);
      final server = FakeSyncServer(clock)..downgradeProtected = {'diaryEntry'};
      final v2 = _fixture('entity-payloads-v2.json', 'diaryEntry');
      await server.push([
        _change('diaryEntry', v2, hlc: _h1, schema: 2),
      ], datasetId: server.datasetId);
      final db = memoryDatabase();
      final store = driftStore(db, clock: clock);
      await _engine(store, server).run();
      // This phone's newer v2 edit (h3), parked for a non-downgrade reason.
      // A local write stamps this device with its HLC.
      await writeRaw(
        db,
        "UPDATE diary_entries SET name_en = 'Mine', updated_hlc = '$_h3', "
        "device_id = '$testDevice' WHERE id = '$_id'",
      );
      await writeRaw(db, 'DELETE FROM sync_outbox');
      final reasons = ['tooLarge', 'invalidPayload', 'encodeFailed'];
      for (final (i, reason) in reasons.indexed) {
        await store.settle(
          parked: [
            ParkedVersion(const SyncVersion('diaryEntry', _id, _h3), reason),
          ],
        );
        // An older v2 arrives (another device, h1 < it < h3).
        await server.push([
          _change(
            'diaryEntry',
            {...v2, 'nameEn': 'Theirs'},
            hlc: '${1760351231000 + i * 100}-00000-$_other',
            schema: 2,
          ),
        ], datasetId: server.datasetId);
        // The retried edit is refused again (not as a downgrade).
        server.validate = (_) => 'invalidPayload';
        await _engine(store, server, appVersion: reason).run();
        server.validate = (_) => null;
        final row = await _row(db, 'diaryEntry');
        expect(row['updated_hlc'], _h3, reason: reason);
        expect(row['name_en'], 'Mine', reason: reason);
        expect(
          await db.customSelect('SELECT * FROM sync_displaced').get(),
          isEmpty,
          reason: reason,
        );
        await writeRaw(db, 'DELETE FROM sync_parked');
      }

      // Refused `unsupported` at schema 2 while the server holds schema 2
      // (no downgrade: say the server lagged): the mark is dropped and the
      // edit is retried, then wins by HLC.
      await store.settle(
        parked: [
          const ParkedVersion(
            SyncVersion('diaryEntry', _id, _h3),
            'unsupported',
          ),
        ],
      );
      expect(await store.refusedDowngrades(), hasLength(1));
      await _engine(store, server, appVersion: 'lagged').run();
      expect(await store.refusedDowngrades(), isEmpty);
      expect((await _row(db, 'diaryEntry'))['name_en'], 'Mine');
      expect(server.documents['diaryEntry/$_id']!.hlc, _h3);
      expect(
        await db.customSelect('SELECT * FROM sync_displaced').get(),
        isEmpty,
      );
    },
  );
}
