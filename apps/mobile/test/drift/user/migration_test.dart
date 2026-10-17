// The migration harness (A01 D15). Started from drift's make-migrations
// template; the generated schema classes are in generated/ (`make gen`
// keeps them current). A new schema version adds its own data test here.
import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/db/write_guard.dart';
import 'package:flutter_test/flutter_test.dart';

import 'generated/schema.dart';
import 'generated/schema_v1.dart' as v1;
import 'generated/schema_v2.dart' as v2;

const _hlc = '1760351234567-00000-0199e3c2-5b1a-7c3d-8e4f-0123456789ab';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  group('every schema step', () {
    // Each older version migrates to every newer one and ends with exactly
    // the dumped schema (tables, columns, triggers).
    const versions = GeneratedHelper.versions;
    for (final (i, fromVersion) in versions.indexed) {
      group('from $fromVersion', () {
        for (final toVersion in versions.skip(i + 1)) {
          test('to $toVersion', () async {
            final schema = await verifier.schemaAt(fromVersion);
            final db = AppDatabase(schema.newConnection());
            await verifier.migrateAndValidate(db, toVersion);
            await db.close();
          });
        }
      });
    }
  });

  test('current schema equals the latest dump', () async {
    final schema = await verifier.schemaAt(GeneratedHelper.versions.last);
    final db = AppDatabase(schema.newConnection());
    expect(db.schemaVersion, GeneratedHelper.versions.last);
    await verifier.migrateAndValidate(db, db.schemaVersion);
    await db.close();
  });

  test(
    'AC-012 migration v1→v2 keeps sync_state and sync_outbox rows and creates '
    'settings_kv',
    () async {
      const oldSyncState = [
        v1.SyncStateData(key: 'hlc.last', value: _hlc),
        v1.SyncStateData(key: 'outbox.capture', value: '0'),
      ];
      // beforeOpen turns capture back on whenever the database opens.
      const expectedSyncState = [
        v2.SyncStateData(key: 'hlc.last', value: _hlc),
        v2.SyncStateData(key: 'outbox.capture', value: '1'),
      ];
      const oldOutbox = [
        v1.SyncOutboxData(
          seq: 1,
          entity: 'meal',
          rowId: '0199e3c2-5b1a-7c3d-8e4f-0123456789ac',
          hlc: _hlc,
          deleted: 0,
        ),
        v1.SyncOutboxData(
          seq: 2,
          entity: 'meal',
          rowId: '0199e3c2-5b1a-7c3d-8e4f-0123456789ad',
          hlc: _hlc,
          deleted: 1,
        ),
      ];
      final expectedOutbox = [
        for (final row in oldOutbox)
          v2.SyncOutboxData(
            seq: row.seq,
            entity: row.entity,
            rowId: row.rowId,
            hlc: row.hlc,
            deleted: row.deleted,
          ),
      ];

      await verifier.testWithDataIntegrity(
        oldVersion: 1,
        newVersion: 2,
        createOld: v1.DatabaseAtV1.new,
        createNew: v2.DatabaseAtV2.new,
        openTestedDatabase: AppDatabase.new,
        createItems: (batch, oldDb) {
          batch
            ..insertAll(oldDb.syncState, oldSyncState)
            ..insertAll(oldDb.syncOutbox, oldOutbox);
        },
        validateItems: (newDb) async {
          expect(await newDb.select(newDb.syncState).get(), expectedSyncState);
          expect(await newDb.select(newDb.syncOutbox).get(), expectedOutbox);
          expect(await newDb.select(newDb.settingsKv).get(), isEmpty);
        },
      );
    },
  );

  test(
    'AC-012 after v1→v2 a settings write is captured in the outbox',
    () async {
      final schema = await verifier.schemaAt(1);
      final db = AppDatabase(schema.newConnection());
      await verifier.migrateAndValidate(db, 2);
      await runAuthorizedWrite(
        () => db
            .into(db.settingsKv)
            .insert(
              SettingsKvCompanion.insert(
                id: '0199e3c2-5b1a-7c3d-8e4f-0123456789ae',
                createdAt: 1,
                updatedHlc: _hlc,
                version: 1,
                deviceId: '0199e3c2-5b1a-7c3d-8e4f-0123456789ab',
                origin: 'direct',
                valueJson: '1',
              ),
            ),
      );
      final outbox = await db.select(db.syncOutbox).get();
      expect(outbox.map((r) => (r.entity, r.hlc, r.deleted)), [
        ('setting', _hlc, false),
      ]);
      await db.close();
    },
  );
}
