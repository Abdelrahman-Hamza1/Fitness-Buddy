import 'dart:convert';
import 'dart:io';

import 'package:fb_domain/fb_domain.dart';
import 'package:test/test.dart';

import '../../tool/generate_body_targets_vectors.dart';

const _path = 'contracts/testdata/sync/body-targets-validation-vectors.json';

File get _file {
  final local = File(_path);
  return local.existsSync() ? local : File('../../$_path');
}

const _targets = {'profile', 'goalPhase', 'targetSettings'};

const _contractPath = 'contracts/openapi/sync-entities.json';

File get _contract {
  final local = File(_contractPath);
  return local.existsSync() ? local : File('../../$_contractPath');
}

/// Sync metadata: in the payload, never read by `TargetRules.wire`.
const _meta = {'createdAtMs', 'origin', 'editedByUser'};

void main() {
  final corpus = jsonDecode(_file.readAsStringSync()) as Map<String, Object?>;
  final payloads = (corpus['payloads']! as List<Object?>)
      .cast<Map<String, Object?>>();
  Map<String, Object?> decoded(Map<String, Object?> p) =>
      jsonDecode(p['rawPayload']! as String) as Map<String, Object?>;

  test('B19 generated vectors match committed bytes', () {
    expect(_file.readAsBytesSync(), utf8.encode(generateBodyTargetsVectors()));
  });

  test('B19 untagged targets cases have serverAccepts equal to '
      'TargetRules.wire', () {
    final targets = [
      for (final p in payloads)
        if (_targets.contains(p['entity'])) p,
    ];
    expect(targets.length, greaterThan(300));
    var untagged = 0;
    for (final p in targets) {
      final id = p['id'];
      final wire = bodyTargetsWireValid(p['entity']! as String, decoded(p));
      expect(p['appWire'], wire, reason: '$id appWire');
      final tag = p['asymmetry'] as String?;
      if (tag == null) {
        untagged++;
        expect(p['serverAccepts'], wire, reason: '$id');
        continue;
      }
      expect(bodyTargetsAsymmetries, contains(tag), reason: '$id');
      expect(p['serverAccepts'], isNot(wire), reason: '$id is tagged $tag');
      // Only a whole-number integer is server-accepted and wire-rejected.
      expect(p['serverAccepts'], tag == 'wholeNumberInteger', reason: '$id');
      if (tag == 'rowId') {
        expect(p['rowId'], isNotNull, reason: '$id');
        expect(p['rule'], 'Row IDs', reason: '$id');
      }
    }
    expect(untagged, greaterThan(250));
    // Every tag is used, and weighIn cases carry only tags from the set.
    expect({
      for (final p in payloads) ?p['asymmetry'] as String?,
    }, bodyTargetsAsymmetries);
    for (final p in payloads.where((p) => p['entity'] == 'weighIn')) {
      expect(p['appWire'], isNull, reason: '${p['id']}');
    }
  });

  test('B19 every README rule has an accepted and a rejected case', () {
    expect(corpus['rules'], [
      for (final MapEntry(:key, :value) in bodyTargetsRules.entries)
        {'id': key, 'readme': value},
    ]);
    final labels = bodyTargetsRules.values.toSet();
    for (final p in payloads) {
      if (p['rule'] case final String rule) {
        expect(labels, contains(rule), reason: '${p['id']}');
        expect(_targets, contains(p['entity']), reason: '${p['id']}');
      }
    }
    for (final label in labels) {
      final cases = payloads.where((p) => p['rule'] == label);
      expect(
        cases.where((p) => p['serverAccepts'] == true),
        isNotEmpty,
        reason: '$label accepted',
      );
      expect(
        cases.where((p) => p['serverAccepts'] == false),
        isNotEmpty,
        reason: '$label rejected',
      );
    }
    // PA3: v7-nibble IDs without the RFC variant are rejected on both sides.
    for (final p in payloads.where(
      (p) => (p['id']! as String).contains('rowId-v7-variant-'),
    )) {
      final id = p['rowId']! as String;
      expect(p['serverAccepts'], isUuidV7(id), reason: '${p['id']}');
    }
  });

  test('TG-001 app-only plausibility outliers are wire-valid and '
      'server-accepted', () {
    final today = LocalDate(2026, 10, 29);
    final cases = payloads.where(
      (p) => (p['id']! as String).startsWith('plausibility-'),
    );
    expect(cases.length, greaterThanOrEqualTo(15));
    for (final p in cases) {
      final id = p['id']! as String;
      final wire = decoded(p);
      expect(p['serverAccepts'], isTrue, reason: id);
      expect(p['appWire'], isTrue, reason: id);
      expect(p['appReads'], isTrue, reason: id);
      expect(p['asymmetry'], isNull, reason: id);
      final rowId = bodyTargetsDefaultRowIds[p['entity']]!;
      final input = switch (p['entity']) {
        'profile' => TargetRules.input.profile(
          ProfileRecord.fromWire(wire)!,
          today: today,
        ),
        'goalPhase' => TargetRules.input.goalPhase(
          GoalPhaseRecord.fromWire(rowId, wire)!,
          today: today,
        ),
        _ => TargetRules.input.targetSettings(
          TargetSettingsRecord.fromWire(rowId, wire)!,
        ),
      };
      // `range` cases break an app-only range; `convention` cases break a
      // convention nobody checks on the wire.
      expect(
        input,
        id.startsWith('plausibility-range-') ? isNotEmpty : isEmpty,
        reason: id,
      );
    }
  });

  test('B19 asymmetry lists are exactly the derived cases', () {
    expect(corpus['serverRejectsAppTolerates'], [
      for (final p in payloads)
        if (p['serverAccepts'] == false && p['appReads'] == true) p['id'],
    ]);
    expect(corpus['serverAcceptsAppSkips'], [
      for (final p in payloads)
        if (p['serverAccepts'] == true && p['appReads'] == false) p['id'],
    ]);
    expect(corpus['serverAcceptsAppSkips'], contains('weighIn2-kg-zero'));
    expect(
      corpus['serverRejectsAppTolerates'],
      containsAll(<String>[
        'targetSettings-protein-percent-100.0000000000000001',
        'profile-heightCm-max-plus-1e-11',
      ]),
    );
  });

  test('B19 schemaOnly cases differ from an accepted base only where '
      'TargetRules.wire never looks', () {
    final entities =
        (jsonDecode(_contract.readAsStringSync())
                as Map<String, Object?>)['entities']!
            as Map<String, Object?>;
    Map<String, Object?> propertiesOf(Map<String, Object?> p) =>
        ((entities[p['entity']]!
                    as Map<String, Object?>)['${p['schemaVersion']}']!
                as Map<String, Object?>)['properties']!
            as Map<String, Object?>;
    bool nullable(Object? property) =>
        switch ((property! as Map<String, Object?>)['type']) {
          final List<Object?> types => types.contains('null'),
          _ => false,
        };

    /// Why [c] isn't [base] plus wire-invisible changes (empty: it is).
    /// Allowed: any metadata change, a member outside the schema, and a
    /// missing member the schema makes nullable (the wire reads it as null).
    List<String> visible(
      Map<String, Object?> c,
      Map<String, Object?> base,
      Map<String, Object?> properties,
    ) {
      final out = <String>[];
      for (final key in {...c.keys, ...base.keys}) {
        if (_meta.contains(key)) continue;
        if (!properties.containsKey(key)) {
          if (base.containsKey(key)) out.add('$key: extra in base');
        } else if (!c.containsKey(key)) {
          if (!nullable(properties[key])) out.add('$key: required missing');
        } else if (jsonEncode(c[key]) != jsonEncode(base[key])) {
          out.add('$key: content changed');
        }
      }
      return out;
    }

    final bases = [
      for (final p in payloads)
        if (p['serverAccepts'] == true &&
            p['asymmetry'] == null &&
            p['deleted'] == false)
          p,
    ];
    final cases = [
      for (final p in payloads)
        if (p['asymmetry'] == 'schemaOnly') p,
    ];
    // 4 member/metadata cases per targets entity, 3 missing nullable
    // members, 1 weighIn v2 extra member.
    expect(cases, hasLength(16));
    for (final c in cases) {
      final properties = propertiesOf(c);
      final candidates = [
        for (final b in bases)
          if (b['entity'] == c['entity'] &&
              b['schemaVersion'] == c['schemaVersion'])
            b,
      ];
      expect(
        candidates.any(
          (b) => visible(decoded(c), decoded(b), properties).isEmpty,
        ),
        isTrue,
        reason:
            '${c['id']} changes something TargetRules.wire reads; '
            'against ${candidates.first['id']}: '
            '${visible(decoded(c), decoded(candidates.first), properties)}',
      );
    }
  });

  test('B19 ids, versions, writer cases and constants are consistent', () {
    final ids = [for (final p in payloads) p['id']];
    expect(ids.toSet(), hasLength(ids.length));
    for (final p in payloads) {
      final id = p['id'];
      final weighIn = p['entity'] == 'weighIn';
      expect(p['schemaVersion'], weighIn ? anyOf(1, 2) : 1, reason: '$id');
      // weighIn v1 has no app reader (A34's upgrader), the rest declare one.
      expect(
        p['appReads'] == null,
        weighIn && p['schemaVersion'] == 1,
        reason: '$id',
      );
      if (weighIn) expect(p.containsKey('rowId'), isFalse, reason: '$id');
    }
    // Tombstones carry the full payload and get the same outcome (D3).
    final byId = {for (final p in payloads) p['id']: p};
    for (final p in payloads) {
      final id = p['id']! as String;
      if (!id.endsWith('-tombstone')) continue;
      final live = byId[id.substring(0, id.length - '-tombstone'.length)]!;
      expect(p['deleted'], isTrue);
      expect(live['deleted'], isFalse);
      for (final key in ['rawPayload', 'serverAccepts', 'rowId', 'rule']) {
        expect(p[key], live[key], reason: '$id $key');
      }
    }
    final writers = (corpus['writerCases']! as List<Object?>)
        .cast<Map<String, Object?>>();
    expect({for (final w in writers) w['entity']}, {..._targets, 'weighIn'});
    for (final w in writers) {
      final p = byId[w['payloadId']]!;
      expect(p['entity'], w['entity']);
      expect(p['serverAccepts'], isTrue, reason: '${w['id']}');
      expect(p['appReads'], isTrue, reason: '${w['id']}');
      expect(p['deleted'], isFalse, reason: '${w['id']}');
    }
    expect(corpus['constants'], {
      'maxNumber': TargetLimits.maxNumber,
      'maxRevision': TargetWireRules.maxRevision,
      'maxNameLength': TargetWireRules.maxNameLength,
      'maxPercent': TargetWireRules.maxPercent,
      'tzOffsetMin': minTzOffsetMinutes,
      'tzOffsetMax': maxTzOffsetMinutes,
      'profileRowId': bodyTargetsProfileRowId,
    });
    final vocabularies = corpus['vocabularies']! as Map<String, Object?>;
    expect(vocabularies['inputUnit'], ['kg', 'lb']);
    expect(vocabularies['expressionKind'], [
      'targetDate',
      'targetRate',
      'weekly',
      'monthly',
    ]);
  });

  test('B19 the percent bound applies to percent macros only', () {
    Map<String, Object?> settings(double value, {required bool percent}) => {
      ...TargetSettingsRecord(
        id: bodyTargetsDefaultRowIds['targetSettings']!,
        revision: 1,
        effectiveFrom: LocalDate(2026, 10, 28),
        baseKcal: 2000,
        basisWeightKg: 80,
      ).toWire(),
      'carbsValue': value,
      'carbsIsPercent': percent,
    };
    const max = TargetWireRules.maxPercent;
    expect(
      TargetRules.wire.targetSettings(settings(max, percent: true)),
      isEmpty,
    );
    expect(TargetRules.wire.targetSettings(settings(max + 1, percent: true)), {
      TargetRuleViolation.number,
    });
    expect(
      TargetRules.wire.targetSettings(settings(max + 1, percent: false)),
      isEmpty,
    );
  });
}
