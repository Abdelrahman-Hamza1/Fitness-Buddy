import 'package:drift/drift.dart';
import 'package:fb_mobile/core/db/tables/sync_columns.dart';
import 'package:fb_mobile/core/db/write_guard.dart';

/// The device id of seeded rows (A01 D7).
const String seedDeviceId = '00000000-0000-0000-0000-000000000000';

/// The HLC of seeded rows: the lowest possible, so any real edit on any device
/// wins over a seed through sync (A01 D7).
const String seedHlc = '0000000000000-00000-$seedDeviceId';

/// Writes seed [rows] into [table] (A01 D7), for migrations, which run before
/// the applier exists.
///
/// Each row gives its `id` (usually a natural id) and its content columns;
/// the sync metadata is fixed: `created_at = 0`, `version = 1`, [seedHlc],
/// [seedDeviceId], `origin = system`, `edited_by_user = 0`. So two fresh
/// databases seed byte-identical rows. An existing row with the same id is
/// kept (a seed never overwrites user data).
///
/// Seeds are not captured: `sync_state['outbox.capture']` is `'0'` while
/// they're written and then set back, all in one transaction. A seeded row
/// reaches the server only once a real edit gives it a real HLC.
Future<void> seedRows<T extends Table, D>(
  DatabaseConnectionUser db,
  TableInfo<T, D> table,
  Iterable<Insertable<D>> rows,
) => runAuthorizedWrite(
  () => db.transaction(() async {
    final previous = await db
        .customSelect(
          "SELECT value FROM sync_state WHERE key = 'outbox.capture'",
        )
        .getSingleOrNull();
    await db.customStatement(
      "INSERT INTO sync_state (key, value) VALUES ('outbox.capture', '0') "
      "ON CONFLICT (key) DO UPDATE SET value = '0'",
    );
    for (final row in rows) {
      final columns = row.toColumns(true);
      final meta = columns.keys.where(
        (c) => c != 'id' && syncColumnNames.contains(c),
      );
      if (meta.isNotEmpty || !columns.containsKey('id')) {
        throw ArgumentError(
          'A seed row gives its id and content columns only, not $meta',
        );
      }
      await db
          .into(table)
          .insert(
            RawValuesInsertable<D>({
              ...columns,
              'created_at': const Variable(0),
              'updated_hlc': const Variable(seedHlc),
              'version': const Variable(1),
              'device_id': const Variable(seedDeviceId),
              'origin': const Variable('system'),
              'edited_by_user': const Variable(false),
            }),
            mode: InsertMode.insertOrIgnore,
          );
    }
    if (previous == null) {
      await db.customStatement(
        "DELETE FROM sync_state WHERE key = 'outbox.capture'",
      );
    } else {
      await db.customStatement(
        "UPDATE sync_state SET value = ? WHERE key = 'outbox.capture'",
        [previous.read<String>('value')],
      );
    }
  }),
);
