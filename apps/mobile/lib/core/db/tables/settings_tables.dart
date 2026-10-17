import 'package:drift/drift.dart';
import 'package:fb_mobile/core/db/tables/sync_columns.dart';

/// The settings store's rows (A01 D16): one synced row per setting key, with
/// the natural id `setting:<key>` (D6). A reset tombstones the row. Entity
/// wire name `setting`.
@DataClassName('SettingRow')
class SettingsKv extends Table with SyncColumns {
  /// The value as JSON text.
  TextColumn get valueJson => text()();
}

/// The entity wire name of a setting row (sync contract, outbox `entity`).
const String settingEntity = 'setting';
