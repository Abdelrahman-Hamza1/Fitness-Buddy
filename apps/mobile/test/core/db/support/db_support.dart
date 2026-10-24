import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/db/catalog/catalog_pack_source.dart';
import 'package:fb_mobile/core/db/connection.dart';
import 'package:fb_mobile/core/db/database_location.dart';
import 'package:fb_mobile/core/db/write_guard.dart';
import 'package:flutter_test/flutter_test.dart';

/// A device id for test rows.
const testDevice = '0199e3c2-5b1a-7c3d-8e4f-0123456789ab';

/// The HLC text at wall ms [wall] on [testDevice].
String hlcAt(int wall) =>
    '${wall.toString().padLeft(13, '0')}-00000-$testDevice';

/// An in-memory database (main isolate), closed after the test.
///
/// Closing waits for every open query stream to finish. A widget test can
/// leave one open (a provider's subscription made in fake async, whose done
/// event nobody pumps), and the close would hang the test, so the wait is
/// bounded.
AppDatabase memoryDatabase() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(
    () => db.close().timeout(const Duration(seconds: 1), onTimeout: () {}),
  );
  return db;
}

/// A fresh temporary directory, deleted after the test.
Directory tempDir() {
  final dir = Directory.systemTemp.createTempSync('fb_db_test');
  addTearDown(() => dir.deleteSync(recursive: true));
  return dir;
}

/// A location under `root`, counting how often the root is resolved.
final class CountingLocation {
  new(String root, {String profileKey = 'local'}) {
    location = DatabaseLocation(
      profileKey: profileKey,
      root: () async {
        resolved++;
        return root;
      },
      temporary: () async => root,
    );
  }

  late final DatabaseLocation location;
  int resolved = 0;
}

/// A file database in a background isolate, the app's real connection,
/// closed after the test.
AppDatabase backgroundDatabase(
  String root, {
  CatalogPackSource catalog = const NoCatalogPack(),
}) {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final db = AppDatabase(
    openUserDatabase(CountingLocation(root).location),
    catalog: catalog,
  );
  addTearDown(db.close);
  return db;
}

/// A file database in the main isolate (URI filenames on, like the app).
AppDatabase fileDatabase(
  String path, {
  CatalogPackSource catalog = const NoCatalogPack(),
  CatalogErrorHandler? onCatalogError,
}) {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final db = AppDatabase(
    openNativeUserDatabase(path),
    catalog: catalog,
    onCatalogError: onCatalogError,
  );
  addTearDown(
    () => db.close().timeout(const Duration(seconds: 1), onTimeout: () {}),
  );
  return db;
}

/// A setting row with the given metadata.
SettingsKvCompanion settingRow(
  String id, {
  int wall = 1,
  int version = 1,
  int? deletedAt,
  String valueJson = '1',
}) => SettingsKvCompanion.insert(
  id: id,
  createdAt: 1,
  updatedHlc: hlcAt(wall),
  version: version,
  deletedAt: Value(deletedAt),
  deviceId: testDevice,
  origin: 'direct',
  valueJson: valueJson,
);

/// Inserts [row] as the single writer would.
Future<void> insertSetting(AppDatabase db, SettingsKvCompanion row) =>
    runAuthorizedWrite(() => db.into(db.settingsKv).insert(row));

/// The outbox rows as `(entity, rowId, hlc, deleted)`.
Future<List<(String, String, String, bool)>> outbox(AppDatabase db) async => [
  for (final r in await (db.select(
    db.syncOutbox,
  )..orderBy([(t) => OrderingTerm(expression: t.seq)])).get())
    (r.entity, r.rowId, r.hlc, r.deleted),
];

/// A catalog pack at a fixed path.
final class FixedPack implements CatalogPackSource {
  const new(this.path);

  final String? path;

  @override
  Future<String?> currentPackPath() async => path;
}

/// The three triggers a synced table must have (A01 D8), as in
/// `lib/core/db/sync_triggers.drift`.
String expectedTriggers(String table, String entity) =>
    '''
CREATE TRIGGER ${table}_outbox_ai AFTER INSERT ON $table
WHEN (SELECT value FROM sync_state WHERE "key" = 'outbox.capture') IS NOT '0'
BEGIN
  INSERT INTO sync_outbox (entity, row_id, hlc, deleted)
  VALUES ('$entity', NEW.id, NEW.updated_hlc, NEW.deleted_at IS NOT NULL);
END;

CREATE TRIGGER ${table}_outbox_au AFTER UPDATE ON $table
WHEN NEW.updated_hlc IS NOT OLD.updated_hlc
  AND (SELECT value FROM sync_state WHERE "key" = 'outbox.capture') IS NOT '0'
BEGIN
  INSERT INTO sync_outbox (entity, row_id, hlc, deleted)
  VALUES ('$entity', NEW.id, NEW.updated_hlc, NEW.deleted_at IS NOT NULL);
END;

CREATE TRIGGER ${table}_no_delete BEFORE DELETE ON $table
BEGIN
  SELECT RAISE(ABORT, 'tombstone, never delete');
END;
''';
