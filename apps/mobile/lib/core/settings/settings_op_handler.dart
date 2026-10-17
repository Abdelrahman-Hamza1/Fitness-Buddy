import 'package:drift/drift.dart' show Value;
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/changes/op_handler.dart';
import 'package:fb_mobile/core/changes/row_ops.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/db/natural_id.dart';
import 'package:fb_mobile/core/db/tables/settings_tables.dart';

/// The row ID of setting [key]: the natural ID `setting:<key>` (A01 D6), the
/// same on every device.
String settingRowId(String key) => naturalId(settingEntity, key);

/// Turns [SettingsOp]s into `settings_kv` writes (A01 D16): a put upserts
/// the key's row (reviving it after a reset), a reset tombstones it. Both
/// emit [SettingsChanged], also when undone.
final class SettingsOpHandler extends ChangeOpHandler<SettingsOp> {
  /// The handler, writing the settings [table] of the profile's database.
  const new(this.table);

  /// The settings table.
  final $SettingsKvTable table;

  @override
  String get family => SettingsOp.familyName;

  @override
  Future<OpPlan> plan(SettingsOp op, TxReader tx, ApplyContext context) async {
    final id = settingRowId(op.key);
    final changed = [
      SettingsChanged({op.key}),
    ];
    switch (op) {
      case SettingsPut(:final valueJson):
        return OpPlan(
          [
            UpsertRow(
              table,
              SettingsKvCompanion(id: Value(id), valueJson: Value(valueJson)),
            ),
          ],
          events: changed,
          revertEvents: changed,
        );
      case SettingsReset():
        final meta = await tx.meta(table, id);
        // Already at its default: nothing to write, nothing changed.
        if (meta == null || meta.isDeleted) return OpPlan(const []);
        return OpPlan(
          [TombstoneRow(table, id)],
          events: changed,
          revertEvents: changed,
        );
    }
  }
}
