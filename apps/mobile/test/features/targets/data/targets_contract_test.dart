import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Table, TableInfo;
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/db/tables/sync_columns.dart';
import 'package:fb_mobile/features/targets/data/target_mappers.dart';
import 'package:flutter_test/flutter_test.dart';

import 'targets_harness.dart';

const _meta = {'createdAtMs', 'origin', 'editedByUser'};

Map<String, Object?> _json(String path) =>
    jsonDecode(File('../../$path').readAsStringSync()) as Map<String, Object?>;

/// Checks [value] against the sync-schema keyword subset the exporter
/// allows (`tools/scripts/export-sync-schemas.py`). Returns the failures.
List<String> _violations(
  Map<String, Object?> schema,
  Object? value,
  String at,
) {
  final types = switch (schema['type']) {
    final List<Object?> list => list.cast<String>(),
    final Object? one => [one! as String],
  };
  final kind = switch (value) {
    null => 'null',
    bool() => 'boolean',
    int() => 'integer',
    double() => 'number',
    String() => 'string',
    Map<String, Object?>() => 'object',
    _ => 'other',
  };
  if (!types.contains(kind) &&
      !(kind == 'integer' && types.contains('number'))) {
    return ['$at: type'];
  }
  final out = <String>[];
  if (value is num) {
    if (schema['minimum'] case final num min when value < min) {
      out.add('$at: minimum');
    }
    if (schema['maximum'] case final num max when value > max) {
      out.add('$at: maximum');
    }
  }
  if (value is String) {
    if (schema['maxLength'] case final int max when value.length > max) {
      out.add('$at: maxLength');
    }
    if (schema['enum'] case final List<Object?> codes
        when !codes.contains(value)) {
      out.add('$at: enum');
    }
    if (schema['format'] == 'date' && LocalDate.tryParse(value) == null) {
      out.add('$at: format');
    }
  }
  if (value is Map<String, Object?>) {
    final properties = schema['properties']! as Map<String, Object?>;
    if (value.length != properties.length ||
        !value.keys.every(properties.containsKey)) {
      out.add('$at: members');
    }
    for (final MapEntry(:key, value: child) in properties.entries) {
      out.addAll(
        _violations(child! as Map<String, Object?>, value[key], '$at.$key'),
      );
    }
  }
  return out;
}

Map<String, Object?> _content(Map<String, Object?> payload) => {
  for (final e in payload.entries)
    if (!_meta.contains(e.key)) e.key: e.value,
};

/// Doubles as the table hands them back (JSON may write `70` for 70.0).
Map<String, Object?> _normalized(Map<String, Object?> wire) => {
  for (final e in wire.entries)
    e.key: e.value is int && !const {'revision', 'birthYear'}.contains(e.key)
        ? (e.value! as int).toDouble()
        : e.value,
};

void main() {
  final entities =
      _json('contracts/openapi/sync-entities.json')['entities']!
          as Map<String, Object?>;
  final fixtures = _json('contracts/testdata/sync/entity-payloads.json');
  final variants =
      (_json('contracts/testdata/sync/targets-payload-variants.json')['cases']!
              as List<Object?>)
          .cast<Map<String, Object?>>();
  Map<String, Object?> schemaOf(String entity) =>
      (entities[entity]! as Map<String, Object?>)['1']! as Map<String, Object?>;

  test('PA8 for each of profile, goalPhase and targetSettings the v1 '
      "fixture's properties map 1:1 to the table's content columns "
      '(camelCase ↔ snake_case, both directions), and the mapper reads the '
      'fixture into a row and writes it back unchanged', () async {
    final h = TargetsHarness();
    for (final (entity, fields, TableInfo<Table, Object?> table)
        in <(String, List<String>, TableInfo<Table, Object?>)>[
          (profileEntityName, TargetWireFields.profile, h.db.profiles),
          (goalPhaseEntityName, TargetWireFields.goalPhase, h.db.goalPhases),
          (
            targetSettingsEntityName,
            TargetWireFields.targetSettings,
            h.db.targetSettingsRows,
          ),
        ]) {
      final properties =
          (schemaOf(entity)['properties']! as Map<String, Object?>).keys
              .where((k) => !_meta.contains(k))
              .toList();
      // Same fields, same order, as the domain and the table.
      expect(properties, fields, reason: entity);
      final columns = [
        for (final c in table.$columns)
          if (!syncColumnNames.contains(c.name)) c.name,
      ];
      expect(columns, fields.map(columnOfWireField).toList(), reason: entity);
      expect(
        {for (final c in columns) _camel(c)},
        fields.toSet(),
        reason: entity,
      );
      final fixture = fixtures[entity]! as Map<String, Object?>;
      expect(fixture.keys.toSet(), {..._meta, ...fields}, reason: entity);
    }

    // Each fixture through the real write path and back out of the row.
    final cases = [
      for (final entity in [
        profileEntityName,
        goalPhaseEntityName,
        targetSettingsEntityName,
      ])
        ('fixture-$entity', entity, fixtures[entity]! as Map<String, Object?>),
      for (final c in variants)
        (
          c['id']! as String,
          c['entity']! as String,
          c['payload']! as Map<String, Object?>,
        ),
    ];
    expect(cases, hasLength(3 + 8));
    expect(cases.map((c) => c.$1).toSet(), hasLength(cases.length));
    for (final (id, entity, payload) in cases) {
      expect(_violations(schemaOf(entity), payload, id), isEmpty);
      final wire = _content(payload);
      final round = TargetsHarness();
      switch (entity) {
        case profileEntityName:
          expect(TargetRules.wire.profile(wire), isEmpty, reason: id);
          await round.apply([PutProfile(ProfileRecord.fromWire(wire)!)]);
          final row = await round.db.select(round.db.profiles).getSingle();
          expect(
            wireOfRow(row, TargetWireFields.profile),
            _normalized(wire),
            reason: id,
          );
        case goalPhaseEntityName:
          expect(TargetRules.wire.goalPhase(wire), isEmpty, reason: id);
          final record = GoalPhaseRecord.fromWire(fixtureId(1), wire)!;
          await round.apply([PutGoalPhase(record)]);
          final row = await round.db.select(round.db.goalPhases).getSingle();
          expect(
            wireOfRow(row, TargetWireFields.goalPhase),
            _normalized(wire),
            reason: id,
          );
        case targetSettingsEntityName:
          expect(TargetRules.wire.targetSettings(wire), isEmpty, reason: id);
          final record = TargetSettingsRecord.fromWire(fixtureId(1), wire)!;
          await round.apply([PutTargetSettings(record)]);
          final row = await round.db
              .select(round.db.targetSettingsRows)
              .getSingle();
          expect(
            wireOfRow(row, TargetWireFields.targetSettings),
            _normalized(wire),
            reason: id,
          );
        default:
          fail('unknown entity $entity in $id');
      }
    }
    // The goalPhase fixtures include negative weekly and monthly goals and
    // maintain = weekly 0 (PA4).
    final goals = [
      for (final (_, entity, payload) in cases)
        if (entity == goalPhaseEntityName) payload,
    ];
    expect(
      goals.any(
        (g) => g['expressionKind'] == 'weekly' && (g['kgPerWeek']! as num) < 0,
      ),
      isTrue,
    );
    expect(
      goals.any(
        (g) => g['expressionKind'] == 'monthly' && (g['monthKg']! as num) < 0,
      ),
      isTrue,
    );
    expect(
      goals.any((g) => g['goalType'] == 'maintain' && g['kgPerWeek'] == 0),
      isTrue,
    );
  });

  test('D3 the contract vocabularies and bounds equal the Dart ones', () {
    // The schema check above does reject bad payloads.
    final profile = fixtures[profileEntityName]! as Map<String, Object?>;
    for (final bad in [
      {...profile, 'sex': 'average'},
      {...profile, 'heightCm': -1},
      {...profile, 'birthYear': 1990.5},
      {...profile, 'weightKg': 70},
      {...profile}..remove('activity'),
    ]) {
      expect(_violations(schemaOf(profileEntityName), bad, 'bad'), isNotEmpty);
    }

    List<Object?> codes(String entity, String field) =>
        ((schemaOf(entity)['properties']! as Map<String, Object?>)[field]!
                as Map<String, Object?>)['enum']!
            as List<Object?>;
    Map<String, Object?> property(String entity, String field) =>
        (schemaOf(entity)['properties']! as Map<String, Object?>)[field]!
            as Map<String, Object?>;
    expect(codes('profile', 'sex'), FormulaSex.values.map((v) => v.name));
    expect(
      codes('profile', 'activity'),
      ActivityLevel.values.map((v) => v.name),
    );
    expect(
      codes('profile', 'heightInputUnit'),
      HeightInputUnit.values.map((v) => v.code),
    );
    expect(codes('goalPhase', 'goalType'), GoalType.values.map((v) => v.name));
    expect(
      codes('goalPhase', 'expressionKind'),
      GoalExpressionKind.values.map((v) => v.name),
    );
    expect(
      codes('goalPhase', 'weightInputUnit'),
      GoalWeightUnits.values.map((v) => v.code),
    );
    expect(
      codes('targetSettings', 'mode'),
      TargetMode.values.map((v) => v.name),
    );
    expect(
      property('goalPhase', 'name')['maxLength'],
      TargetWireRules.maxNameLength,
    );
    for (final entity in ['goalPhase', 'targetSettings']) {
      expect(property(entity, 'revision'), {
        'type': 'integer',
        'minimum': 1,
        'maximum': TargetWireRules.maxRevision,
      });
    }
    // Every numeric property of the three schemas, pinned to the Dart
    // bounds: (minimum, maximum, integer). A new numeric field must be added
    // here, so the contract and the wire rules can't drift apart.
    const max = TargetLimits.maxNumber;
    const safe = TargetWireRules.maxRevision;
    const number = (0, max, false);
    const signed = (-max, max, false);
    final pinned = <String, Map<String, (num, num, bool)>>{
      'profile': {
        'createdAtMs': (0, safe, true),
        'birthYear': (1, 9999, true),
        'heightCm': number,
      },
      'goalPhase': {
        'createdAtMs': (0, safe, true),
        'revision': (1, safe, true),
        'targetKg': number,
        'kgPerWeek': signed,
        'monthKg': signed,
      },
      'targetSettings': {
        'createdAtMs': (0, safe, true),
        'revision': (1, safe, true),
        'baseKcal': number,
        'basisWeightKg': number,
        for (final field in TargetWireFields.shifts.values) field: number,
        for (final macro in TargetWireFields.macros) '${macro}Value': number,
        'fiberG': number,
      },
    };
    expect(TargetWireFields.shifts, hasLength(7));
    for (final MapEntry(key: entity, value: table) in pinned.entries) {
      final numeric = {
        for (final MapEntry(:key, :value)
            in (schemaOf(entity)['properties']! as Map<String, Object?>)
                .entries)
          if (switch ((value! as Map<String, Object?>)['type']) {
            final List<Object?> types =>
              types.contains('number') || types.contains('integer'),
            final Object? type => type == 'number' || type == 'integer',
          })
            key: value as Map<String, Object?>,
      };
      expect(numeric.keys.toSet(), table.keys.toSet(), reason: entity);
      for (final MapEntry(key: field, value: (min, max, integer))
          in table.entries) {
        final p = numeric[field]!;
        final types = switch (p['type']) {
          final List<Object?> list => list,
          final Object? one => [one],
        };
        expect(p['minimum'], min, reason: '$entity.$field minimum');
        expect(p['maximum'], max, reason: '$entity.$field maximum');
        expect(
          types.contains('integer'),
          integer,
          reason: '$entity.$field integer',
        );
      }
    }
  });
}

String _camel(String column) =>
    column.replaceAllMapped(RegExp('_([a-z])'), (m) => m[1]!.toUpperCase());

const profileEntityName = 'profile';
const goalPhaseEntityName = 'goalPhase';
const targetSettingsEntityName = 'targetSettings';
