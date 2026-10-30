import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift_dev/api/migrations_native.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

import 'generated/schema.dart';
import 'generated/schema_v3.dart' as v3;
import 'generated/schema_v4.dart' as v4;

const _hlc = '1760351234567-00000-0199e3c2-5b1a-7c3d-8e4f-0123456789ab';
const _id = '0199e3c2-5b1a-7c3d-8e4f-0123456789ab';
const _names = {
  'setting': 'settings_kv',
  'mealSlot': 'meal_slots',
  'dishGroup': 'dish_groups',
  'diaryEntry': 'diary_entries',
  'dayMark': 'day_marks',
  'savedMeal': 'saved_meals',
  'savedMealItem': 'saved_meal_items',
};
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
  void seed(Batch batch, GeneratedDatabase oldDb, int version) {
    before.clear();
    batch.customStatement(
      "INSERT INTO sync_state (key,value) VALUES ('outbox.capture','1')",
    );
    if (version == 1) {
      batch.customStatement(
        'INSERT INTO sync_outbox (entity,row_id,hlc,deleted) VALUES (?,?,?,?)',
        ['synthetic', _id, _hlc, 0],
      );
    }
    for (final e in _names.entries) {
      if (version == 1 || version == 2 && e.key != 'setting') continue;
      final values = <String, Object?>{
        'id': _id,
        'created_at': 0,
        'updated_hlc': _hlc,
        'version': 1,
        'device_id': _id,
        'deleted_at': null,
      };
      final payload = fixtures[e.key] as Map<String, dynamic>;
      for (final f in payload.entries) {
        if (f.key == 'createdAtMs') continue;
        values[_snake(f.key)] = f.value is bool
            ? (f.value == true ? 1 : 0)
            : f.value;
      }
      batch.customStatement(
        'INSERT INTO ${e.value} (${values.keys.join(',')}) '
        'VALUES (${List.filled(values.length, '?').join(',')})',
        values.values.toList(),
      );
      before[e.value] = [values];
    }
  }

  Future<void> validate(v4.DatabaseAtV4 db, int version) async {
    for (final e in before.entries) {
      final rows = await db.customSelect('SELECT * FROM ${e.key}').get();
      expect(rows.map((r) => r.data).toList(), e.value);
    }
    final out = await db.select(db.syncOutbox).get();
    expect(out.length, version == 1 ? 1 : before.length);
    expect(await db.select(db.personalFoods).get(), isEmpty);
    final triggers = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type='trigger' "
          "AND tbl_name='personal_foods'",
        )
        .get();
    expect(triggers.map((r) => r.read<String>('name')).toSet(), {
      'personal_foods_outbox_ai',
      'personal_foods_outbox_au',
      'personal_foods_no_delete',
    });
    for (final (table, index) in [
      ('diary_entries', 'ix_diary_entries_food'),
      ('saved_meal_items', 'ix_saved_meal_items_food'),
    ]) {
      final columns = await db.customSelect('PRAGMA index_info($index)').get();
      expect(columns.map((r) => r.read<String>('name')), [
        'food_kind',
        'food_id',
      ]);
      final plan = await db
          .customSelect(
            'EXPLAIN QUERY PLAN SELECT * FROM $table '
            "WHERE food_kind='personal' AND food_id='synthetic' "
            'AND deleted_at IS NULL',
          )
          .get();
      expect(plan.map((r) => r.read<String>('detail')).join(), contains(index));
    }
    // Exercise capture after upgrade, rather than only checking SQL names.
    await db.customStatement(
      'INSERT INTO personal_foods '
      '(id,created_at,updated_hlc,version,device_id,origin,edited_by_user,'
      'name_en,state,basis,per100_kcal,per100_protein_g,per100_carbs_g,'
      'per100_fat_g,per100_fiber_g,created_from) '
      'VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)',
      [
        _id,
        0,
        _hlc,
        1,
        _id,
        'direct',
        0,
        'Synthetic',
        'as_sold',
        'g',
        0,
        0,
        0,
        0,
        0,
        'form',
      ],
    );
    expect((await db.select(db.syncOutbox).get()).last.entity, 'personalFood');
  }

  test('migration v3 → v4 keeps every row and adds personal_foods '
      'with its outbox triggers', () async {
    await verifier.testWithDataIntegrity(
      oldVersion: 3,
      newVersion: 4,
      createOld: v3.DatabaseAtV3.new,
      createNew: v4.DatabaseAtV4.new,
      openTestedDatabase: AppDatabase.new,
      createItems: (batch, db) => seed(batch, db, 3),
      validateItems: (db) => validate(db, 3),
    );
  });
}
