import 'package:drift/drift.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/core/changes/change_providers.dart';
import 'package:fb_mobile/core/changes/change_set_applier.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/db/db_providers.dart';
import 'package:fb_mobile/core/settings/setting_key.dart';
import 'package:fb_mobile/core/settings/settings_op_handler.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'settings_store.g.dart';

/// The profile's settings (A01 D16): typed reads and watches over
/// `settings_kv`, and writes only as change sets through the
/// [ChangeSetApplier] (so they sync and can be undone).
///
/// An unset or reset setting reads as its key's default.
final class SettingsStore {
  /// A store reading `db` and writing through `applier`.
  new({required this._db, required this._applier});

  final AppDatabase _db;
  final ChangeSetApplier<AppDatabase> _applier;

  /// The value of [key] now, then each time it changes.
  Stream<T> watch<T>(SettingKey<T> key) =>
      _row(key).watchSingleOrNull().map((row) => _valueOf(key, row)).distinct();

  /// The value of [key].
  Future<T> read<T>(SettingKey<T> key) =>
      _row(key).getSingleOrNull().then((row) => _valueOf(key, row));

  /// Sets [key] to [value], from [origin]. Returns what the applier gave:
  /// the caller decides whether it gets an undo entry.
  Future<ApplyResult> put<T>(
    SettingKey<T> key,
    T value, {
    required Origin origin,
  }) => _applier.apply(
    ChangeSet([
      SettingsOp.put(key.name, key.codec.encode(value)),
    ], origin: origin),
  );

  /// Sets [key] back to its default, from [origin]. Like [put].
  Future<ApplyResult> reset<T>(SettingKey<T> key, {required Origin origin}) =>
      _applier.apply(ChangeSet([SettingsOp.reset(key.name)], origin: origin));

  SimpleSelectStatement<$SettingsKvTable, SettingRow> _row(
    SettingKey<Object?> key,
  ) {
    final id = settingRowId(key.name);
    return _db.select(_db.settingsKv)..where((t) => t.id.equals(id));
  }

  static T _valueOf<T>(SettingKey<T> key, SettingRow? row) =>
      key.valueOf(row == null || row.deletedAt != null ? null : row.valueJson);
}

/// The open profile's settings.
@Riverpod(keepAlive: true)
SettingsStore settingsStore(Ref ref) => SettingsStore(
  db: ref.watch(appDatabaseProvider),
  applier: ref.watch(changeSetApplierProvider),
);
