import 'package:drift/drift.dart' hide isNull;
import 'package:drift_dev/api/migrations_native.dart';
import 'package:fb_domain/fb_domain.dart' show RamadanSlots;
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

import 'generated/schema.dart';

const _hlc = '1760351234567-00000-0199e3c2-5b1a-7c3d-8e4f-0123456789ab';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final verifier = SchemaVerifier(GeneratedHelper());

  test('DY-012 v12→v13 seeds the three Ramadan slots without capturing them, '
      'keeps a synced Ramadan slot and adds ix_proposals_kind', () async {
    final schema = await verifier.schemaAt(12);
    // An Iftar row that arrived by sync before the upgrade (renamed, v3).
    schema.rawDatabase.execute(
      'INSERT INTO meal_slots (id, created_at, updated_hlc, version, '
      'device_id, deleted_at, origin, edited_by_user, default_key, name, '
      'sort_order, window_start_min, window_end_min, mode, active) VALUES '
      "(?, 5, ?, 3, '0199e3c2-5b1a-7c3d-8e4f-0123456789ab', NULL, 'direct', "
      "1, 'iftar', 'Ftoor', 1, NULL, NULL, 'ramadan', 1)",
      [RamadanSlots.iftarId, _hlc],
    );
    final db = AppDatabase(schema.newConnection());
    await verifier.migrateAndValidate(db, 13);
    final rows = await (db.select(
      db.mealSlots,
    )..where((t) => t.mode.equals('ramadan'))).get();
    final byId = {for (final r in rows) r.id: r};
    expect(byId.keys.toSet(), {for (final s in RamadanSlots.all) s.id});
    expect(byId[RamadanSlots.iftarId]!.name, 'Ftoor', reason: 'kept');
    expect(byId[RamadanSlots.iftarId]!.version, 3);
    final suhoor = byId[RamadanSlots.suhoorId]!;
    expect(suhoor.createdAt, 0);
    expect(suhoor.windowStartMin, isNull);
    expect(suhoor.active, isTrue);
    // Only the pre-upgrade insert itself is captured, never a seed.
    expect((await db.select(db.syncOutbox).get()).map((r) => r.rowId), [
      RamadanSlots.iftarId,
    ]);
    final index = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'index' "
          "AND name = 'ix_proposals_kind'",
        )
        .get();
    expect(index, hasLength(1));
    await db.close();
  });
}
