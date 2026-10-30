import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Variable;
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/features/body/data/measurement_mappers.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../core/db/support/db_support.dart';

/// The row IDs used when a case has no `rowId` (the generator's
/// `measurementDefaultRowIds`).
const _rowIds = {
  'measurementType': '0199e3c2-5b1a-7c3d-8e4f-0123456789ae',
  'measurement': '0199e3c2-5b1a-7c3d-8e4f-0123456789af',
};
const _hlc = '1760351234567-00000-0199e3c2-5b1a-7c3d-8e4f-0123456789ab';

const _meta = {'createdAtMs', 'origin', 'editedByUser'};

/// The content fields in contract order (pinned below).
const _fields = {
  'measurementType': ['name'],
  'measurement': [
    'kind',
    'customTypeId',
    'measuredAtUtc',
    'tzOffsetMin',
    'localDate',
    'value',
    'inputValue',
    'inputUnit',
  ],
};

Map<String, dynamic> _json(String path) =>
    jsonDecode(File('../../$path').readAsStringSync()) as Map<String, dynamic>;

final Map<String, dynamic> _corpus = _json(
  'contracts/testdata/sync/measurement-validation-vectors.json',
);

final List<Map<String, dynamic>> _payloads = (_corpus['payloads'] as List)
    .cast<Map<String, dynamic>>();

Map<String, Object?> _decoded(Map<String, dynamic> p) =>
    jsonDecode(p['rawPayload'] as String) as Map<String, Object?>;

String _snake(String s) =>
    s.replaceAllMapped(RegExp('[A-Z]'), (m) => '_${m[0]!.toLowerCase()}');

String _camel(String s) =>
    s.replaceAllMapped(RegExp('_([a-z])'), (m) => m[1]!.toUpperCase());

/// The payload's content as a table row (snake_case; a missing member is a
/// missing column) with fixed sync columns: the metadata mapping is A34's.
Map<String, Object?> _sqlRow(
  String entity,
  Map<String, Object?> payload, {
  required bool deleted,
  String? rowId,
}) => {
  'id': rowId ?? _rowIds[entity],
  'created_at': 0,
  'updated_hlc': _hlc,
  'version': 1,
  'deleted_at': deleted ? 1761609600000 : null,
  'device_id': _rowIds['measurement'],
  'origin': 'sync',
  'edited_by_user': 0,
  for (final field in _fields[entity]!)
    if (payload.containsKey(field)) _snake(field): payload[field],
};

Map<String, Object?> _content(Map<String, Object?> payload) => {
  for (final e in payload.entries)
    if (!_meta.contains(e.key)) e.key: e.value,
};

Map<String, Object?> _written(Map<String, Object> columns) => {
  for (final MapEntry(:key, :value) in columns.entries)
    _camel(key): (value as Variable).value,
};

void main() {
  late AppDatabase db;
  setUpAll(() => db = memoryDatabase());

  test('WB-040 the content fields are the contract measurement and '
      'measurementType fields', () {
    final entities =
        _json('contracts/openapi/sync-entities.json')['entities']
            as Map<String, dynamic>;
    for (final MapEntry(key: entity, value: fields) in _fields.entries) {
      final schema =
          (entities[entity] as Map<String, dynamic>)['1']
              as Map<String, dynamic>;
      expect(
        (schema['properties'] as Map<String, dynamic>).keys.where(
          (k) => !_meta.contains(k),
        ),
        fields,
        reason: entity,
      );
    }
  });

  test('WB-040 WB-042 corpus payloads decode through measurementOf and '
      'measurementTypeOf as declared', () {
    expect(_payloads, hasLength(greaterThan(150)));
    final mismatches = <String>[];
    var reads = 0;
    for (final p in _payloads) {
      final entity = p['entity'] as String;
      final sql = _sqlRow(
        entity,
        _decoded(p),
        deleted: p['deleted'] as bool,
        rowId: p['rowId'] as String?,
      );
      bool read() {
        try {
          if (entity == 'measurement') {
            measurementOf(db.measurements.map(sql));
          } else {
            measurementTypeOf(db.measurementTypes.map(sql));
          }
          return true;
          // drift's typed read throws a TypeError for a value the row type
          // can't hold (a missing column, a string for a number).
          // ignore: avoid_catching_errors
        } on TypeError {
          return false;
        } on FormatException {
          return false;
        } on MeasurementMappingError {
          return false;
        }
      }

      final actual = read();
      if (actual) reads++;
      if (actual != p['appReads']) mismatches.add('${p['id']}: $actual');
    }
    expect(mismatches, isEmpty);
    expect(reads, greaterThan(60));
  });

  test('WB-040 drafts and names written by the real column writers equal '
      'accepted corpus payloads', () {
    final byId = {for (final p in _payloads) p['id'] as String: p};
    final writers = (_corpus['writerCases'] as List)
        .cast<Map<String, dynamic>>();
    expect(writers, hasLength(12));
    for (final w in writers) {
      final id = w['id'] as String;
      final p = byId[w['payloadId']]!;
      final payload = _decoded(p);
      final row = _sqlRow(w['entity'] as String, payload, deleted: false);
      if (w['entity'] == 'measurementType') {
        final name = w['name'] as String;
        expect(CustomTypeName.validate(name), isNull, reason: id);
        expect(
          _written(measurementTypeColumns(name).toColumns(false)),
          _content(payload),
          reason: id,
        );
        expect(
          measurementTypeOf(db.measurementTypes.map(row)).name,
          CustomTypeName.normalize(name),
          reason: id,
        );
        continue;
      }
      final draft = MeasurementDraft(
        type: MeasurementTypeRef(
          kind: MeasurementKind.fromCode(payload['kind']! as String)!,
          customTypeId: payload['customTypeId'] as String?,
        ),
        time: EntryTime(
          DateTime.fromMillisecondsSinceEpoch(
            payload['measuredAtUtc']! as int,
            isUtc: true,
          ),
          payload['tzOffsetMin']! as int,
        ),
        input: MeasurementInput(
          (payload['inputValue']! as num).toDouble(),
          MeasurementUnit.fromCode(payload['inputUnit']! as String)!,
        ),
      );
      expect(draft.validate(), isNull, reason: id);
      expect(
        _written(measurementColumns(draft).toColumns(false)),
        _content(payload),
        reason: id,
      );
      expect(measurementOf(db.measurements.map(row)).draft, draft, reason: id);
    }
  });
}
