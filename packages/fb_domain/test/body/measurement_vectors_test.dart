import 'dart:convert';
import 'dart:io';

import 'package:fb_domain/fb_domain.dart';
import 'package:test/test.dart';

import '../../tool/generate_measurement_vectors.dart';

File _repoFile(String path) {
  final local = File(path);
  return local.existsSync() ? local : File('../../$path');
}

Map<String, Object?> _json(String path) =>
    jsonDecode(_repoFile(path).readAsStringSync()) as Map<String, Object?>;

const _path = 'contracts/testdata/sync/measurement-validation-vectors.json';

/// The fields M1–M3 read; a `schemaOnly` case may differ from an accepted
/// base only elsewhere (a length's numbers are invisible to M3).
Object? _wireView(Map<String, Object?> p) => jsonEncode([
  p['kind'],
  p['customTypeId'] == null,
  p['inputUnit'],
  if (p['kind'] == 'bodyFat') ...[p['value'], p['inputValue']],
]);

void main() {
  final corpus = _json(_path);
  final payloads = (corpus['payloads']! as List<Object?>)
      .cast<Map<String, Object?>>();
  Map<String, Object?> decoded(Map<String, Object?> p) =>
      jsonDecode(p['rawPayload']! as String) as Map<String, Object?>;

  test('B20 generated vectors match committed bytes', () {
    expect(
      _repoFile(_path).readAsBytesSync(),
      utf8.encode(generateMeasurementVectors()),
    );
  });

  test('B20 untagged measurement cases have serverAccepts equal to '
      'MeasurementWireRules; asymmetry lists are exactly the derived '
      'cases', () {
    var untagged = 0;
    for (final p in payloads) {
      final id = p['id'];
      final entity = p['entity']! as String;
      final tag = p['asymmetry'] as String?;
      if (tag != null) expect(measurementAsymmetries, contains(tag));
      final wire = measurementWireValid(entity, decoded(p));
      expect(p['appWire'], wire, reason: '$id appWire');
      if (entity == 'measurementType') {
        // No wire rules: every rejection is the schema's or generic.
        expect(p['serverAccepts'], tag == null, reason: '$id');
        expect(tag, isNot('decimalPrecision'), reason: '$id');
        continue;
      }
      if (tag == null) {
        untagged++;
        expect(p['serverAccepts'], wire, reason: '$id');
      } else {
        // Every tag marks a server rejection of a wire-valid payload.
        expect(p['serverAccepts'], isFalse, reason: '$id is tagged $tag');
        expect(wire, isTrue, reason: '$id is tagged $tag');
      }
    }
    expect(untagged, greaterThan(100));
    expect({
      for (final p in payloads) ?p['asymmetry'] as String?,
    }, measurementAsymmetries);

    // A schemaOnly measurement equals an accepted base where M1–M3 look.
    final bases = {
      for (final p in payloads)
        if (p['entity'] == 'measurement' &&
            p['serverAccepts'] == true &&
            p['asymmetry'] == null)
          _wireView(decoded(p)),
    };
    for (final p in payloads.where(
      (p) => p['entity'] == 'measurement' && p['asymmetry'] == 'schemaOnly',
    )) {
      expect(bases, contains(_wireView(decoded(p))), reason: '${p['id']}');
    }

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
        'measurement-M3-bodyFat-value-zero',
        'measurement-measuredAtUtc-max',
        'notWire-convention-name-empty',
      ]),
    );
    expect(
      corpus['serverRejectsAppTolerates'],
      containsAll(<String>[
        'measurement-M3-bodyFat-value-100.0000000000000001',
        'measurementType-name-over-max',
      ]),
    );
  });

  test('WB-040 WB-042 app-only plausibility outliers and the variants file '
      'are wire-valid', () {
    final outliers = [
      for (final p in payloads)
        if ((p['id']! as String).startsWith('notWire-')) p,
    ];
    expect(outliers, hasLength(greaterThanOrEqualTo(13)));
    for (final p in outliers) {
      final id = p['id']! as String;
      final wire = decoded(p);
      expect(p['serverAccepts'], isTrue, reason: id);
      expect(p['asymmetry'], isNull, reason: id);
      if (p['entity'] == 'measurementType') {
        // An empty, blank or control-character name breaks the app's rule.
        expect(
          CustomTypeName.validate(wire['name']! as String),
          isNotNull,
          reason: id,
        );
        continue;
      }
      expect(p['appWire'], isTrue, reason: id);
      expect(p['appReads'], isTrue, reason: id);
      final draft = MeasurementDraft(
        type: MeasurementTypeRef(
          kind: MeasurementKind.fromCode(wire['kind']! as String)!,
          customTypeId: wire['customTypeId'] as String?,
        ),
        time: EntryTime(
          DateTime.fromMillisecondsSinceEpoch(
            wire['measuredAtUtc']! as int,
            isUtc: true,
          ),
          wire['tzOffsetMin']! as int,
        ),
        input: MeasurementInput(
          (wire['inputValue']! as num).toDouble(),
          MeasurementUnit.fromCode(wire['inputUnit']! as String)!,
        ),
      );
      // `range` cases break a local range; `convention` cases a convention
      // the draft doesn't carry (factor, local date, type, row ID).
      expect(
        draft.validate(),
        id.startsWith('notWire-range-') ? MeasurementIssue.outOfRange : isNull,
        reason: id,
      );
    }

    final entities =
        _json('contracts/openapi/sync-entities.json')['entities']!
            as Map<String, Object?>;
    final fixtures = _json('contracts/testdata/sync/entity-payloads.json');
    final variants =
        (_json(
                  'contracts/testdata/sync/measurement-payload-variants.json',
                )['cases']!
                as List<Object?>)
            .cast<Map<String, Object?>>();
    final valid = [
      for (final entity in ['measurementType', 'measurement'])
        (entity, fixtures[entity]! as Map<String, Object?>),
      for (final v in variants)
        (v['entity']! as String, v['payload']! as Map<String, Object?>),
    ];
    expect(valid, hasLength(5));
    for (final (entity, payload) in valid) {
      final schema =
          (entities[entity]! as Map<String, Object?>)['1']!
              as Map<String, Object?>;
      expect(
        payload.keys,
        (schema['properties']! as Map<String, Object?>).keys,
        reason: entity,
      );
      expect(measurementWireValid(entity, payload), isNot(isFalse));
    }
  });

  test('B20 rules, tombstones, writer cases, constants and vocabularies are '
      'consistent', () {
    expect(corpus['rules'], [
      for (final MapEntry(:key, :value) in measurementRules.entries)
        {'id': key, 'readme': value},
    ]);
    for (final label in measurementRules.values) {
      final cases = payloads.where((p) => p['rule'] == label);
      expect(cases.where((p) => p['serverAccepts'] == true), isNotEmpty);
      expect(cases.where((p) => p['serverAccepts'] == false), isNotEmpty);
      for (final p in cases) {
        expect(p['entity'], 'measurement', reason: '${p['id']}');
      }
    }
    final ids = [for (final p in payloads) p['id']];
    expect(ids.toSet(), hasLength(ids.length));
    expect(payloads.length, greaterThan(150));
    final byId = {for (final p in payloads) p['id']: p};
    for (final p in payloads) {
      expect(p['schemaVersion'], 1);
      final id = p['id']! as String;
      if (!id.endsWith('-tombstone')) continue;
      // Tombstones carry the full payload and get the same outcome (D3).
      final live = byId[id.substring(0, id.length - '-tombstone'.length)]!;
      expect(p['deleted'], isTrue);
      expect(live['deleted'], isFalse);
      for (final key in ['rawPayload', 'serverAccepts', 'rowId', 'rule']) {
        expect(p[key], live[key], reason: '$id $key');
      }
    }
    final writers = (corpus['writerCases']! as List<Object?>)
        .cast<Map<String, Object?>>();
    expect(
      {for (final w in writers) w['entity']},
      {'measurementType', 'measurement'},
    );
    for (final w in writers) {
      final p = byId[w['payloadId']]!;
      expect(p['entity'], w['entity']);
      expect(p['serverAccepts'], isTrue, reason: '${w['id']}');
      expect(p['appReads'], isTrue, reason: '${w['id']}');
      expect(p['deleted'], isFalse, reason: '${w['id']}');
      expect(w.containsKey('name'), w['entity'] == 'measurementType');
    }
    expect(corpus['constants'], {
      'maxPercent': MeasurementWireRules.maxPercent,
      'maxValue': MeasurementBounds.readMax,
      'tzOffsetMin': minTzOffsetMinutes,
      'tzOffsetMax': maxTzOffsetMinutes,
      'maxMeasuredAtUtc': 9007199254740991,
      'maxNameLength': 120,
      'maxOriginLength': 128,
      'customKind': 'custom',
      'percentKind': 'bodyFat',
      'percentUnit': 'percent',
    });
    expect(corpus['vocabularies'], {
      'kind': [for (final k in MeasurementKind.values) k.code],
      'inputUnit': ['cm', 'in', 'percent'],
    });
  });
}
