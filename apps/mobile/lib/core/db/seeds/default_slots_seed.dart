import 'package:drift/drift.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/db/natural_id.dart';
import 'package:fb_mobile/core/db/seed_rows.dart';

/// Seeds the four default meal slots (DY-010, A06 D8) into [table] through
/// [seedRows]: deterministic ids, `created_at = 0`, not captured into the
/// outbox. Used by the v3 migration (with that version's table) and by
/// `onCreate`. An existing row is kept.
///
/// Throws a `StateError` if `DefaultSlots` and the natural ids disagree.
Future<void> seedDefaultSlots<T extends Table, D>(
  DatabaseConnectionUser db,
  TableInfo<T, D> table,
) => _seedSlots(db, table, DefaultSlots.all);

/// Seeds the three Ramadan meal slots (DY-012, A41a D5) like
/// [seedDefaultSlots]: Suhoor, Iftar and Snacks of mode `ramadan`, used by
/// the v13 migration and by `onCreate`. An existing row is kept.
Future<void> seedRamadanSlots<T extends Table, D>(
  DatabaseConnectionUser db,
  TableInfo<T, D> table,
) => _seedSlots(db, table, RamadanSlots.all);

Future<void> _seedSlots<T extends Table, D>(
  DatabaseConnectionUser db,
  TableInfo<T, D> table,
  List<MealSlot> slots,
) {
  final rows = <Insertable<D>>[];
  for (final slot in slots) {
    final key = DefaultSlots.naturalKey(slot.defaultKey!, mode: slot.mode);
    if (naturalId('mealSlot', key) != slot.id) {
      throw StateError('DefaultSlots id of ${slot.defaultKey} is stale');
    }
    rows.add(
      RawValuesInsertable<D>({
        'id': Variable<String>(slot.id),
        'default_key': Variable<String>(slot.defaultKey),
        'name': const Variable<String>(null),
        'sort_order': Variable<int>(slot.sortOrder),
        'window_start_min': Variable<int>(slot.window?.startMin),
        'window_end_min': Variable<int>(slot.window?.endMin),
        'mode': Variable<String>(slot.mode.code),
        'active': const Variable<bool>(true),
      }),
    );
  }
  return seedRows(db, table, rows);
}
