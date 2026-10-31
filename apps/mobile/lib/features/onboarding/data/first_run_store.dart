import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/db/db_providers.dart';
import 'package:fb_mobile/core/storage/preferences.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'first_run_store.g.dart';

/// What the first-run gate reads (TD-110): the device marker
/// `PreferenceKeys.firstRun` and whether the open profile holds any data.
final class FirstRunStore {
  /// Over the app's preferences and the open profile's database.
  const new(this._preferences, this._db);

  final SharedPreferencesAsync _preferences;
  final AppDatabase _db;

  /// Whether this phone has had its first run.
  Future<bool> seen() async =>
      await _preferences.getBool(PreferenceKeys.firstRun) ?? false;

  /// Records that it has.
  Future<void> markSeen() =>
      _preferences.setBool(PreferenceKeys.firstRun, true);

  /// Whether the open profile has ever held user data: any row, live or
  /// deleted, in any synced table (diary, foods, saved meals, targets,
  /// weigh-ins, measurements, workouts, settings, Buddy). Meal slots are
  /// left out: the database seeds them.
  Future<bool> hasLocalData() async {
    final db = _db;
    for (final synced in db.syncedTables) {
      final table = synced.table;
      if (table.actualTableName == db.mealSlots.actualTableName) continue;
      final id = table.$columns.first;
      final row =
          await (db.selectOnly(table)
                ..addColumns([id])
                ..limit(1))
              .getSingleOrNull();
      if (row != null) return true;
    }
    return false;
  }
}

/// The app's [FirstRunStore].
@riverpod
FirstRunStore firstRunStore(Ref ref) => FirstRunStore(
  ref.watch(sharedPreferencesProvider),
  ref.watch(appDatabaseProvider),
);
