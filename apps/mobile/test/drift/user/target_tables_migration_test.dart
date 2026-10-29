import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift_dev/api/migrations_native.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

import 'generated/schema.dart';
import 'generated/schema_v1.dart' as v1;
import 'generated/schema_v2.dart' as v2;
import 'generated/schema_v3.dart' as v3;
import 'generated/schema_v4.dart' as v4;
import 'generated/schema_v5.dart' as v5;

const _hlc = '1760351234567-00000-0199e3c2-5b1a-7c3d-8e4f-0123456789ab';
const _id = '0199e3c2-5b1a-7c3d-8e4f-0123456789ab';
// Existing synced tables, the schema version that added them, and their
// contract fixture.
const _existing = {
  'setting': ('settings_kv', 2),
  'mealSlot': ('meal_slots', 3),
  'dishGroup': ('dish_groups', 3),
  'diaryEntry': ('diary_entries', 3),
  'dayMark': ('day_marks', 3),
  'savedMeal': ('saved_meals', 3),
  'savedMealItem': ('saved_meal_items', 3),
  'personalFood': ('personal_foods', 4),
};
const _targets = ['profile', 'goal_phases', 'target_settings'];
String _snake(String s) =>
    s.replaceAllMapped(RegExp('[A-Z]'), (m) => '_${m[0]!.toLowerCase()}');

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final verifier = SchemaVerifier(GeneratedHelper());
  final fixtures = jsonDecode(
    File('../../contracts/testdata/sync/entity-payloads.json')
        .readAsStringSync(),
  ) as Map<String, dynamic>;
  final before = <String, List<Map<String, Object?>>>{};
  var outboxBefore = 0;

  void seed(Batch batch, int version) {
    before.clear();
    outboxBefore = 0;
    batch.customStatement(
      "INSERT INTO sync_state (key,value) VALUES ('outbox.capture','1')",
    );
    for (final MapEntry(key: entity, value: (table, since))
        in _existing.entries) {
      if (version < since) continue;
      final values = <String, Object?>{
        'id': _id,
        'created_at': 0,
        'updated_hlc': _hlc,
        'version': 1,
        'device_id': _id,
        'deleted_at': null,
      };
      for (final f in (fixtures[entity] as Map<String, dynamic>).entries) {
        if (f.key == 'createdAtMs') continue;
        values[_snake(f.key)] = f.value is bool
            ? (f.value == true ? 1 : 0)
            : f.value;
      }
      batch.customStatement(
        'INSERT INTO $table (${values.keys.join(',')}) '
        'VALUES (${List.filled(values.length, '?').join(',')})',
        values.values.toList(),
      );
      before[table] = [values];
      outboxBefore++;
    }
  }

  Future<void> validate(v5.DatabaseAtV5 db) async {
    for (final e in before.entries) {
      final rows = await db.customSelect('SELECT * FROM ${e.key}').get();
      expect(rows.map((r) => r.data).toList(), e.value, reason: e.key);
    }
    expect(await db.select(db.syncOutbox).get(), hasLength(outboxBefore));
    for (final table in _targets) {
      expect(
        await db.customSelect('SELECT * FROM $table').get(),
        isEmpty,
        reason: table,
      );
      final triggers = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type='trigger' "
            'AND tbl_name=?',
            variables: [Variable.withString(table)],
          )
          .get();
      expect(triggers.map((r) => r.read<String>('name')).toSet(), {
        '${table}_outbox_ai',
        '${table}_outbox_au',
        '${table}_no_delete',
      });
    }
    for (final (table, index, column) in [
      ('goal_phases', 'ix_goal_phases_start', 'start_date'),
      ('target_settings', 'ix_target_settings_effective', 'effective_from'),
    ]) {
      final columns = await db.customSelect('PRAGMA index_info($index)').get();
      expect(columns.map((r) => r.read<String>('name')), [column]);
      final plan = await db
          .customSelect(
            'EXPLAIN QUERY PLAN SELECT * FROM $table '
            "WHERE $column <= '2026-10-28' AND deleted_at IS NULL",
          )
          .get();
      expect(plan.map((r) => r.read<String>('detail')).join(), contains(index));
    }
    // Capture works on the new tables after the upgrade.
    const meta =
        'id,created_at,updated_hlc,version,device_id,origin,edited_by_user';
    const metaValues = [_id, 0, _hlc, 1, _id, 'direct', 0];
    await db.customStatement(
      'INSERT INTO profile '
      '($meta,sex,birth_year,height_cm,height_input_unit,activity) '
      'VALUES (?,?,?,?,?,?,?,?,?,?,?,?)',
      [...metaValues, 'female', 1990, 165.0, 'cm', 'light'],
    );
    await db.customStatement(
      'INSERT INTO goal_phases ($meta,revision,start_date,goal_type, '
      'expression_kind,kg_per_week,weight_input_unit) '
      'VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)',
      [...metaValues, 1, '2026-10-28', 'lose', 'weekly', -0.5, 'lb'],
    );
    await db.customStatement(
      'INSERT INTO target_settings ($meta,revision,effective_from,mode, '
      'rebalancing,base_kcal,manual,acknowledged,basis_weight_kg, '
      'calories_protein_only) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)',
      [...metaValues, 1, '2026-10-28', 'weekly', 1, 2000.0, 0, 0, 70.0, 0],
    );
    final outbox = await db.select(db.syncOutbox).get();
    expect(outbox.skip(outboxBefore).map((r) => r.entity), [
      'profile',
      'goalPhase',
      'targetSettings',
    ]);
    await expectLater(
      db.customStatement('DELETE FROM target_settings'),
      throwsA(anything),
    );
  }

  test('migration v4 → v5 keeps every row and adds profile, goal_phases and '
      'target_settings with their indexes and outbox triggers', () async {
    await verifier.testWithDataIntegrity(
      oldVersion: 4,
      newVersion: 5,
      createOld: v4.DatabaseAtV4.new,
      createNew: v5.DatabaseAtV5.new,
      openTestedDatabase: AppDatabase.new,
      createItems: (batch, db) => seed(batch, 4),
      validateItems: validate,
    );
  });

  for (final (from, create)
      in <(int, GeneratedDatabase Function(QueryExecutor))>[
        (3, v3.DatabaseAtV3.new),
        (2, v2.DatabaseAtV2.new),
        (1, v1.DatabaseAtV1.new),
      ]) {
    test('migration v$from → v5', () async {
      await verifier.testWithDataIntegrity(
        oldVersion: from,
        newVersion: 5,
        createOld: create,
        createNew: v5.DatabaseAtV5.new,
        openTestedDatabase: AppDatabase.new,
        createItems: (batch, db) => seed(batch, from),
        validateItems: validate,
      );
    });
  }
}
