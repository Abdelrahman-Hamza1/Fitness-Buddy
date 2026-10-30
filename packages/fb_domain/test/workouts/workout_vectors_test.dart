import 'dart:convert';
import 'dart:io';

import 'package:fb_domain/fb_domain.dart';
import 'package:test/test.dart';

import '../../tool/generate_workout_vectors.dart';

File _repoFile(String path) {
  final local = File(path);
  return local.existsSync() ? local : File('../../$path');
}

Map<String, Object?> _json(String path) =>
    jsonDecode(_repoFile(path).readAsStringSync()) as Map<String, Object?>;

const _path = 'contracts/testdata/sync/workout-validation-vectors.json';

void main() {
  final corpus = _json(_path);
  final payloads = (corpus['payloads']! as List<Object?>)
      .cast<Map<String, Object?>>();
  Map<String, Object?> decoded(Map<String, Object?> p) =>
      jsonDecode(p['rawPayload']! as String) as Map<String, Object?>;

  test('B21 generated vectors match committed bytes', () {
    expect(
      _repoFile(_path).readAsBytesSync(),
      utf8.encode(generateWorkoutVectors()),
    );
  });

  test('B21 untagged cases have serverAccepts equal to WorkoutWireRules; '
      'tags from the closed set; asymmetry lists are exactly the derived '
      'cases', () {
    var untagged = 0;
    for (final p in payloads) {
      final id = p['id'];
      final entity = p['entity']! as String;
      final tag = p['asymmetry'] as String?;
      final wire = workoutWireValid(
        entity,
        decoded(p),
        rowId: p['rowId'] as String?,
      );
      expect(p['appWire'], wire, reason: '$id appWire');
      switch (tag) {
        case null:
          untagged++;
          expect(p['serverAccepts'], wire, reason: '$id');
        case 'wholeNumberInteger':
          expect((p['serverAccepts'], wire), (true, false), reason: '$id');
        default:
          expect(workoutAsymmetries, contains(tag), reason: '$id');
          expect((p['serverAccepts'], wire), (false, true), reason: '$id');
      }
    }
    expect(untagged, greaterThan(200));
    // The builder uses every tag (none is dead).
    expect({
      for (final p in payloads) ?p['asymmetry'] as String?,
    }, workoutAsymmetries);
    expect(corpus['serverRejectsAppTolerates'], [
      for (final p in payloads)
        if (p['serverAccepts'] == false && p['appReads'] == true) p['id'],
    ]);
    expect(corpus['serverAcceptsAppSkips'], [
      for (final p in payloads)
        if (p['serverAccepts'] == true && p['appReads'] == false) p['id'],
    ]);
    expect(
      corpus['serverAcceptsAppSkips'],
      containsAll(<String>[
        'customExercise-W2-blank',
        'notWire-session-duration-0',
        'customExercise-name-max',
      ]),
    );
    expect(
      corpus['serverRejectsAppTolerates'],
      containsAll(<String>[
        'customExercise-W1-five',
        'workoutSet-W3-kg-without-input',
        'weeklyPlanDay-W5-monday-id',
      ]),
    );
  });

  test('B21 workout fixtures satisfy every wire rule', () {
    final entities =
        _json('contracts/openapi/sync-entities.json')['entities']!
            as Map<String, Object?>;
    final fixtures = _json('contracts/testdata/sync/entity-payloads.json');
    for (final entity in workoutEntities) {
      final schema =
          (entities[entity]! as Map<String, Object?>)['1']!
              as Map<String, Object?>;
      final fixture = fixtures[entity]! as Map<String, Object?>;
      expect(
        fixture.keys,
        (schema['properties']! as Map<String, Object?>).keys,
        reason: entity,
      );
      final rowId = entity == 'weeklyPlanDay'
          ? WorkoutWireRules.planDayIds[(fixture['weekday']! as int) - 1]
          : null;
      expect(workoutWireValid(entity, fixture, rowId: rowId), isTrue);
    }
    // The main custom exercise base is the fixture.
    final base = payloads.firstWhere((p) => p['id'] == 'customExercise-base');
    expect(decoded(base), fixtures['customExercise']);
  });

  test('B21 rules, tombstones, writer cases, constants and vocabularies are '
      'consistent', () {
    expect(corpus['rules'], [
      for (final MapEntry(:key, :value) in workoutRules.entries)
        {'id': key, 'readme': value},
    ]);
    const ruleEntities = {
      'W1 muscles': {'customExercise'},
      'W2 aliases shape': {'customExercise'},
      'W3 set shape': {'workoutSet'},
      'W4 exercise reference': {'sessionExercise', 'workoutTemplateItem'},
      'W5 plan-day row ID': {'weeklyPlanDay'},
    };
    for (final label in workoutRules.values) {
      final cases = payloads.where((p) => p['rule'] == label);
      expect(cases.where((p) => p['serverAccepts'] == true), isNotEmpty);
      expect(cases.where((p) => p['serverAccepts'] == false), isNotEmpty);
      expect({for (final p in cases) p['entity']}, ruleEntities[label]);
    }
    final ids = [for (final p in payloads) p['id']];
    expect(ids.toSet(), hasLength(ids.length));
    expect({for (final p in payloads) p['entity']}, workoutEntities.toSet());
    final byId = {for (final p in payloads) p['id']: p};
    for (final p in payloads) {
      expect(p['schemaVersion'], 1);
      // W5: every plan-day case names its row ID; the others only when the
      // row ID is the point.
      if (p['entity'] == 'weeklyPlanDay') expect(p['rowId'], isNotNull);
      final id = p['id']! as String;
      if (!id.endsWith('-tombstone')) continue;
      // Tombstones carry the full payload and get the same outcome (D5).
      final live = byId[id.substring(0, id.length - '-tombstone'.length)]!;
      expect(p['deleted'], isTrue);
      expect(live['deleted'], isFalse);
      for (final key in [
        'rawPayload',
        'serverAccepts',
        'appReads',
        'rowId',
        'rule',
      ]) {
        expect(p[key], live[key], reason: '$id $key');
      }
    }
    final writers = (corpus['writerCases']! as List<Object?>)
        .cast<Map<String, Object?>>();
    expect({for (final w in writers) w['entity']}, workoutEntities.toSet());
    for (final w in writers) {
      final p = byId[w['payloadId']]!;
      expect(p['entity'], w['entity']);
      expect(p['serverAccepts'], isTrue, reason: '${w['id']}');
      expect(p['appReads'], isTrue, reason: '${w['id']}');
      expect(p['deleted'], isFalse, reason: '${w['id']}');
    }
    // Scrubbed tombstones (D10): admissible while W3's null pattern holds.
    for (final entity in [
      'customExercise',
      'workoutSession',
      'workoutTemplate',
      'workoutSet',
    ]) {
      final p = byId['$entity-tombstone-scrubbed']!;
      expect((p['serverAccepts'], p['deleted']), (true, true), reason: entity);
    }
    expect(
      byId['workoutSet-tombstone-scrubbed-nulls']!['serverAccepts'],
      false,
    );
    expect(corpus['constants'], {
      'maxSecondaries': 4,
      'maxAliases': 10,
      'maxCatalogIdLength': 60,
      'maxNameLength': 160,
      'maxNumber': 1000000000000,
      'maxInteger': 9007199254740991,
      'maxOriginLength': 128,
      'planDayIds': WorkoutWireRules.planDayIds,
    });
    expect(corpus['vocabularies'], {
      'exerciseType': [for (final t in ExerciseType.values) t.code],
      'equipment': [for (final e in Equipment.values) e.code],
      'muscle': [for (final m in Muscle.values) m.code],
      'inputUnit': ['kg', 'lb'],
    });
  });
}
