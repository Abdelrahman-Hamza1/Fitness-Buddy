import 'package:drift/drift.dart';
import 'package:fb_mobile/core/db/app_database.steps.dart';
import 'package:fb_mobile/core/db/seed_rows.dart';

/// Schema v12 → v13 (A41a): the three Ramadan meal slots (DY-012, A41a D5)
/// and the proposals-by-kind index (backlog #235).
///
/// Shipped migrations are frozen: never edit this file once it is on `main`
/// (`tools/scripts/check-frozen-migrations.sh`).
Future<void> from12To13(Migrator m, Schema13 schema) async {
  await m.createIndex(schema.ixProposalsKind);
  await seedRows(m.database, schema.mealSlots, [
    for (final slot in v13RamadanSlots)
      RawValuesInsertable<Never>({
        'id': Variable<String>(slot.id),
        'default_key': Variable<String>(slot.key),
        'name': const Variable<String>(null),
        'sort_order': Variable<int>(slot.sortOrder),
        'window_start_min': const Variable<int>(null),
        'window_end_min': const Variable<int>(null),
        'mode': const Variable<String>('ramadan'),
        'active': const Variable<bool>(true),
      }),
  ]);
}

/// The Ramadan slots as v13 seeded them: copied here, so a later change to
/// `RamadanSlots` can't alter this frozen step. A test checks them against
/// today's `RamadanSlots.all`.
const List<({String id, String key, int sortOrder})> v13RamadanSlots = [
  (id: 'd66f696e-cfcb-5a60-a70d-8a4d21f3c9c0', key: 'suhoor', sortOrder: 0),
  (id: 'd8814590-7c87-5da2-8ad9-de3f1d155c92', key: 'iftar', sortOrder: 1),
  (id: '623c0dd7-e319-5fc0-987a-0b2c33643a0a', key: 'snacks', sortOrder: 2),
];
