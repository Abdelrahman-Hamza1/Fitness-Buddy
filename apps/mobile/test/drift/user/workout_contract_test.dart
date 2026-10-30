import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Table, TableInfo;
import 'package:fb_mobile/core/db/tables/sync_columns.dart';
import 'package:fb_mobile/core/db/tables/workout_tables.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../core/db/support/db_support.dart';

const _meta = {'createdAtMs', 'origin', 'editedByUser'};

Map<String, Object?> _json(String path) =>
    jsonDecode(File('../../$path').readAsStringSync()) as Map<String, Object?>;

String _camel(String s) =>
    s.replaceAllMapped(RegExp('_([a-z])'), (m) => m[1]!.toUpperCase());

void main() {
  test('B21 workout fixtures map 1:1 to the table columns both ways; every '
      'content column is on the wire', () {
    final db = memoryDatabase();
    final entities =
        _json('contracts/openapi/sync-entities.json')['entities']!
            as Map<String, Object?>;
    final fixtures = _json('contracts/testdata/sync/entity-payloads.json');
    for (final (entity, TableInfo<Table, Object?> table)
        in <(String, TableInfo<Table, Object?>)>[
          (customExerciseEntity, db.customExercises),
          (workoutSessionEntity, db.workoutSessions),
          (sessionExerciseEntity, db.sessionExercises),
          (workoutSetEntity, db.workoutSets),
          (workoutTemplateEntity, db.workoutTemplates),
          (workoutTemplateItemEntity, db.workoutTemplateItems),
          (weeklyPlanDayEntity, db.weeklyPlanDays),
        ]) {
      final schema =
          (entities[entity]! as Map<String, Object?>)['1']!
              as Map<String, Object?>;
      final properties = [
        for (final k in (schema['properties']! as Map<String, Object?>).keys)
          if (!_meta.contains(k)) k,
      ];
      final columns = [
        for (final c in table.$columns)
          if (!syncColumnNames.contains(c.name)) _camel(c.name),
      ];
      // Same fields, same order: every content column is on the wire and
      // nothing else is.
      expect(properties, columns, reason: entity);
      final fixture = fixtures[entity]! as Map<String, Object?>;
      expect(fixture.keys.toList(), [..._meta, ...columns], reason: entity);
    }
  });
}
