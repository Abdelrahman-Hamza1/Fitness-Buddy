import 'package:drift/drift.dart' hide isNull;
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/db/natural_id.dart';
import 'package:fb_mobile/core/db/seed_rows.dart';
import 'package:fb_mobile/core/db/write_guard.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/db_support.dart';

final String _units = naturalId('setting', 'units.system');
final String _theme = naturalId('setting', 'ui.theme');

List<SettingsKvCompanion> _seeds() => [
  SettingsKvCompanion(id: Value(_units), valueJson: const Value('"metric"')),
  SettingsKvCompanion(id: Value(_theme), valueJson: const Value('"system"')),
];

Future<List<Map<String, Object?>>> _rows(AppDatabase db) async => [
  for (final r
      in await db.customSelect('SELECT * FROM settings_kv ORDER BY id').get())
    r.data,
];

Future<String?> _capture(AppDatabase db) async => (await (db.select(
  db.syncState,
)..where((t) => t.key.equals('outbox.capture'))).getSingleOrNull())?.value;

void main() {
  test('A01 D7 seeding appends no outbox rows and restores capture', () async {
    final db = memoryDatabase();
    await seedRows(db, db.settingsKv, _seeds());
    expect(await outbox(db), isEmpty);
    expect(await _capture(db), '1');

    final rows = await db.select(db.settingsKv).get();
    expect(rows, hasLength(2));
    for (final row in rows) {
      expect(row.createdAt, 0);
      expect(row.version, 1);
      expect(row.updatedHlc, seedHlc);
      expect(row.deviceId, seedDeviceId);
      expect(row.origin, 'system');
      expect(row.editedByUser, isFalse);
      expect(row.deletedAt, isNull);
    }
  });

  test('two fresh databases seed byte-identical rows', () async {
    final a = memoryDatabase();
    final b = memoryDatabase();
    await seedRows(a, a.settingsKv, _seeds());
    await seedRows(b, b.settingsKv, _seeds());
    expect(await _rows(a), await _rows(b));
  });

  test('the seed HLC is below any real HLC', () {
    expect(seedHlc.compareTo(hlcAt(1)), isNegative);
  });

  test('a seed never overwrites an existing row', () async {
    final db = memoryDatabase();
    await insertSetting(db, settingRow(_units, valueJson: '"imperial"'));
    await seedRows(db, db.settingsKv, _seeds());
    final units = await (db.select(
      db.settingsKv,
    )..where((t) => t.id.equals(_units))).getSingle();
    expect(units.valueJson, '"imperial"');
    expect(units.origin, 'direct');
  });

  test('capture stays off when seeding inside a capture-off scope', () async {
    final db = memoryDatabase();
    await runAuthorizedWrite(
      () => db.transaction(() async {
        await db.customStatement(
          "UPDATE sync_state SET value = '0' WHERE key = 'outbox.capture'",
        );
        await seedRows(db, db.settingsKv, _seeds());
        expect(await _capture(db), '0');
      }),
    );
  });

  test('a seed row that sets sync metadata is rejected', () async {
    final db = memoryDatabase();
    await expectLater(
      seedRows(db, db.settingsKv, [
        SettingsKvCompanion(
          id: Value(_units),
          valueJson: const Value('1'),
          version: const Value(7),
        ),
      ]),
      throwsArgumentError,
    );
    expect(await db.select(db.settingsKv).get(), isEmpty);
  });
}
