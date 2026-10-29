import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/db/db_providers.dart';
import 'package:fb_mobile/core/db/natural_id.dart';
import 'package:fb_mobile/core/export/export_registry.dart';
import 'package:fb_mobile/core/export/export_snapshot.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'export_snapshot.g.dart';

/// Reads all export data in a single SELECT-only transaction (A11 PA1).
final class ExportSnapshotReader {
  /// Binds the reader to the active profile database.
  new(this._db);
  final AppDatabase _db;

  /// Reads live rows and resolves parent names in the same snapshot.
  Future<ExportSnapshot> read({required Iterable<String> settingNames}) =>
      _db.transaction(() async {
        // Parent names survive deletion/inactivation (A11 PA8).
        final slots = await _db
            .customSelect('SELECT id, name, default_key FROM meal_slots')
            .get();
        final meals = await _db
            .customSelect('SELECT id, name FROM saved_meals')
            .get();
        final slotNames = {
          for (final r in slots)
            r.data['id']: r.data['name'] ?? r.data['default_key'],
        };
        final mealNames = {for (final r in meals) r.data['id']: r.data['name']};
        final keys = {
          for (final name in settingNames) naturalId('setting', name): name,
        };
        final rows = <String, List<Map<String, Object?>>>{};
        for (final spec in exportRegistryV1) {
          final columns = spec.columns
              .where((c) => c.kind != ExportKind.derived)
              .map((c) => c.name)
              .join(', ');
          final order = switch (spec.entity) {
            'diaryEntry' => 'local_date, occurred_at_utc, id',
            'weighIn' => 'local_date, measured_at_utc, id',
            _ => 'id',
          };
          final result = await _db
              .customSelect(
                'SELECT $columns FROM ${spec.table} '
                'WHERE deleted_at IS NULL ORDER BY $order',
              )
              .get();
          rows[spec.entity] = [
            for (final r in result)
              {
                ...r.data,
                if (spec.entity == 'diaryEntry')
                  'meal': slotNames[r.data['slot_id']],
                if (spec.entity == 'savedMealItem')
                  'saved_meal_name': mealNames[r.data['saved_meal_id']],
                if (spec.entity == 'setting') 'key': keys[r.data['id']] ?? '',
              },
          ];
        }
        return ExportSnapshot(schemaVersion: _db.schemaVersion, rows: rows);
      });
}

/// Database boundary: callers receive plain snapshots only.
@Riverpod(keepAlive: true)
Future<ExportSnapshot> Function({required Iterable<String> settingNames})
exportSnapshotReader(Ref ref) =>
    ExportSnapshotReader(ref.watch(appDatabaseProvider)).read;
