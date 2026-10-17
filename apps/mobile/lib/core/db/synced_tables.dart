import 'package:drift/drift.dart';
import 'package:fb_mobile/core/db/natural_id.dart';
import 'package:fb_mobile/core/db/tables/sync_columns.dart';

/// A table that syncs (A01 D16): its drift table and its entity wire name.
///
/// Every table with the `SyncColumns` mixin is listed in
/// `AppDatabase.syncedTables` and has the three outbox triggers in
/// `sync_triggers.drift` (both checked by
/// `test/core/db/sync_triggers_test.dart`).
final class SyncedTable<T extends Table, D> {
  /// [table] syncs as [entity]. Throws an `ArgumentError` if [entity] isn't
  /// a camelCase wire name of at most 64 characters, if [table] lacks a
  /// sync column, or if `D` isn't the table's row class.
  ///
  /// Give the type arguments explicitly in a list (a list's element type
  /// would otherwise be inferred for them):
  /// `SyncedTable<$SettingsKvTable, SettingRow>(settingsKv, 'setting')`.
  /// The row writer builds rows of type `D`, which drift checks at runtime.
  new(this.table, this.entity) {
    checkEntityWireName(entity);
    if (null is D) {
      throw ArgumentError.value(
        table.actualTableName,
        'table',
        'needs its row class as the type argument D',
      );
    }
    final names = {for (final c in table.$columns) c.name};
    final missing = syncColumnNames.where((c) => !names.contains(c));
    if (missing.isNotEmpty) {
      throw ArgumentError.value(
        table.actualTableName,
        'table',
        'lacks the sync columns $missing',
      );
    }
  }

  /// The drift table.
  final TableInfo<T, D> table;

  /// The entity wire name (sync contract, outbox `entity`), like `setting`.
  final String entity;

  /// The SQL table name, like `settings_kv`.
  String get sqlName => table.actualTableName;

  /// [values] (SQL column name to value) as a row of this table, typed with
  /// its row class `D` (drift checks it at runtime).
  Insertable<D> rawRow(Map<String, Expression<Object>> values) =>
      RawValuesInsertable<D>(values);

  /// The columns that aren't sync metadata: what a write sets and undo
  /// restores (with `deleted_at` and `edited_by_user`, A01 D3).
  List<GeneratedColumn<Object>> get contentColumns => [
    for (final c in table.$columns)
      if (!syncColumnNames.contains(c.name)) c,
  ];
}
