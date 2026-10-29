import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Variable;
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/features/body/data/weigh_in_mappers.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../core/db/support/db_support.dart';

const _id = '0199e3c2-5b1a-7c3d-8e4f-0123456789ad';
const _hlc = '1760351234567-00000-0199e3c2-5b1a-7c3d-8e4f-0123456789ab';

const _meta = {'createdAtMs', 'origin', 'editedByUser'};

/// The `weighIn` v2 content fields, in contract order (pinned below).
const _fields = [
  'measuredAtUtc',
  'localDate',
  'kg',
  'note',
  'tzOffsetMin',
  'inputValue',
  'inputUnit',
  'preferredForDay',
];

Map<String, dynamic> _json(String path) =>
    jsonDecode(File('../../$path').readAsStringSync()) as Map<String, dynamic>;

final Map<String, dynamic> _corpus = _json(
  'contracts/testdata/sync/body-targets-validation-vectors.json',
);

final List<Map<String, dynamic>> _v2 = [
  for (final p in (_corpus['payloads'] as List).cast<Map<String, dynamic>>())
    if (p['entity'] == 'weighIn' && p['schemaVersion'] == 2) p,
];

Map<String, Object?> _decoded(Map<String, dynamic> p) =>
    jsonDecode(p['rawPayload'] as String) as Map<String, Object?>;

String _snake(String s) =>
    s.replaceAllMapped(RegExp('[A-Z]'), (m) => '_${m[0]!.toLowerCase()}');

String _camel(String s) =>
    s.replaceAllMapped(RegExp('_([a-z])'), (m) => m[1]!.toUpperCase());

/// The payload's content as a `weigh_ins` SQL row (snake_case, booleans as
/// 0/1) with fixed sync columns: the metadata mapping is A34's.
Map<String, Object?> _sqlRow(
  Map<String, Object?> payload, {
  required bool deleted,
}) => {
  'id': _id,
  'created_at': 0,
  'updated_hlc': _hlc,
  'version': 1,
  'deleted_at': deleted ? 1761609600000 : null,
  'device_id': _id,
  'origin': 'sync',
  'edited_by_user': 0,
  for (final field in _fields)
    _snake(field): switch (payload[field]) {
      true => 1,
      false => 0,
      final value => value,
    },
};

Map<String, Object?> _content(Map<String, Object?> payload) => {
  for (final e in payload.entries)
    if (!_meta.contains(e.key)) e.key: e.value,
};

void main() {
  late AppDatabase db;
  setUpAll(() => db = memoryDatabase());

  test('WB-003 the v2 content fields are the contract weighIn v2 fields', () {
    final v2 =
        ((_json('contracts/openapi/sync-entities.json')['entities']
                    as Map<String, dynamic>)['weighIn']
                as Map<String, dynamic>)['2']
            as Map<String, dynamic>;
    expect(
      (v2['properties'] as Map<String, dynamic>).keys.where(
        (k) => !_meta.contains(k),
      ),
      _fields,
    );
  });

  test('WB-003 weighIn v2 corpus payloads decode through weighInOf as '
      'declared', () {
    expect(_v2, hasLength(greaterThan(40)));
    final mismatches = <String>[];
    var reads = 0;
    for (final p in _v2) {
      final sql = _sqlRow(_decoded(p), deleted: p['deleted'] as bool);
      bool read() {
        final WeighInRow row;
        try {
          row = db.weighIns.map(sql);
          // drift's typed read throws a TypeError for a value the row type
          // can't hold.
          // ignore: avoid_catching_errors
        } on TypeError {
          return false;
        } on FormatException {
          return false;
        }
        try {
          weighInOf(row);
          return true;
        } on WeighInMappingError {
          return false;
        }
      }

      final actual = read();
      if (actual) reads++;
      if (actual != p['appReads']) mismatches.add('${p['id']}: $actual');
    }
    expect(mismatches, isEmpty);
    expect(reads, greaterThan(15));
    // The read bound skips server-valid rows; the corpus lists them.
    expect(
      _corpus['serverAcceptsAppSkips'],
      containsAll(<String>['weighIn2-kg-zero', 'weighIn2-input-zero']),
    );
  });

  test('WB-003 drafts written by weighInColumns equal accepted v2 '
      'payloads', () {
    final byId = {for (final p in _v2) p['id'] as String: p};
    final writers = [
      for (final w
          in (_corpus['writerCases'] as List).cast<Map<String, dynamic>>())
        if (w['entity'] == 'weighIn') byId[w['payloadId']]!,
    ];
    expect(writers, hasLength(2));
    for (final p in writers) {
      final id = p['id'] as String;
      final payload = _decoded(p);
      final draft = WeighInDraft(
        time: EntryTime(
          DateTime.fromMillisecondsSinceEpoch(
            payload['measuredAtUtc']! as int,
            isUtc: true,
          ),
          payload['tzOffsetMin']! as int,
        ),
        input: WeighInInput(
          (payload['inputValue']! as num).toDouble(),
          MassUnit.fromCode(payload['inputUnit']! as String)!,
        ),
        note: payload['note'] as String?,
      );
      expect(draft.validate(), isNull, reason: id);
      final written = {
        for (final MapEntry(:key, :value) in weighInColumns(
          draft,
        ).toColumns(false).entries)
          _camel(key): (value as Variable).value,
        // The handler sets it; a new weigh-in isn't the day's pick.
        'preferredForDay': false,
      };
      expect(written, _content(payload), reason: id);
      final row = db.weighIns.map(_sqlRow(payload, deleted: false));
      expect(weighInOf(row).draft, draft, reason: id);
    }
  });
}
