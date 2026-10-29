import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Insertable, Table, TableInfo;
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/db/natural_id.dart';
import 'package:fb_mobile/features/targets/data/target_mappers.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../core/db/support/db_support.dart';

const _hlc = '1760351234567-00000-0199e3c2-5b1a-7c3d-8e4f-0123456789ab';
const _device = '0199e3c2-5b1a-7c3d-8e4f-0123456789ab';

/// The row IDs of cases without a `rowId` (the corpus generator's
/// `bodyTargetsDefaultRowIds`; the profile's is `profileRowId`).
const _defaultIds = {
  'goalPhase': '0199e3c2-5b1a-7c3d-8e4f-0123456789ab',
  'targetSettings': '0199e3c2-5b1a-7c3d-8e4f-0123456789ac',
};

const _meta = {'createdAtMs', 'origin', 'editedByUser'};

final Map<String, dynamic> _corpus = jsonDecode(
  File('../../contracts/testdata/sync/body-targets-validation-vectors.json')
      .readAsStringSync(),
) as Map<String, dynamic>;

final List<Map<String, dynamic>> _payloads = (_corpus['payloads'] as List)
    .cast<Map<String, dynamic>>();

Map<String, Object?> _decoded(Map<String, dynamic> p) =>
    jsonDecode(p['rawPayload'] as String) as Map<String, Object?>;

/// The row ID as the server pulls it back: it binds IDs as `Guid`, so the
/// text is lowercase canonical (B19 PA3).
String _rowId(Map<String, dynamic> p) =>
    ((p['rowId'] as String?) ??
            (p['entity'] == 'profile'
                ? profileRowId
                : _defaultIds[p['entity']]!))
        .toLowerCase();

/// The payload's content in its table's SQL row ([fields] as snake_case
/// columns via [columnOfWireField], booleans as 0/1), with fixed sync
/// columns: the metadata mapping is A34's.
Map<String, Object?> _sqlRow(
  String id,
  Map<String, Object?> payload,
  List<String> fields, {
  required bool deleted,
}) => {
  'id': id,
  'created_at': 0,
  'updated_hlc': _hlc,
  'version': 1,
  'deleted_at': deleted ? 1761609600000 : null,
  'device_id': _device,
  'origin': 'sync',
  'edited_by_user': 0,
  for (final field in fields)
    columnOfWireField(field): switch (payload[field]) {
      true => 1,
      false => 0,
      final value => value,
    },
};

/// Doubles as the table hands them back (JSON may write `70` for 70.0).
Map<String, Object?> _normalized(Map<String, Object?> wire) => {
  for (final e in wire.entries)
    e.key: e.value is int && !const {'revision', 'birthYear'}.contains(e.key)
        ? (e.value! as int).toDouble()
        : e.value,
};

Map<String, Object?> _content(Map<String, Object?> payload) => {
  for (final e in payload.entries)
    if (!_meta.contains(e.key)) e.key: e.value,
};

void main() {
  late AppDatabase db;
  setUpAll(() => db = memoryDatabase());

  /// The entity's table, content fields and real decoder.
  (TableInfo<Table, Object?>, List<String>, Object? Function(Object?)) app(
    String entity,
  ) => switch (entity) {
    'profile' => (
      db.profiles,
      TargetWireFields.profile,
      (row) => profileOf(row! as ProfileRow),
    ),
    'goalPhase' => (
      db.goalPhases,
      TargetWireFields.goalPhase,
      (row) => goalPhaseOf(row! as GoalPhaseRow),
    ),
    'targetSettings' => (
      db.targetSettingsRows,
      TargetWireFields.targetSettings,
      (row) => targetSettingsOf(row! as TargetSettingsRow),
    ),
    _ => throw ArgumentError.value(entity),
  };

  test('TG-001 TG-012 TG-040 targets corpus payloads decode through the real '
      'mappers as declared', () {
    final cases = [
      for (final p in _payloads)
        if (p['entity'] != 'weighIn') p,
    ];
    expect(cases, hasLength(greaterThan(300)));
    final mismatches = <String>[];
    var reads = 0;
    for (final p in cases) {
      final (table, fields, decode) = app(p['entity'] as String);
      final sql = _sqlRow(
        _rowId(p),
        _decoded(p),
        fields,
        deleted: p['deleted'] as bool,
      );
      bool read() {
        final Object? row;
        try {
          row = table.map(sql);
          // drift's typed read throws a TypeError for a value the row type
          // can't hold.
          // ignore: avoid_catching_errors
        } on TypeError {
          // A value the typed row can't hold (a missing NOT NULL value, a
          // string in a REAL column): never readable.
          return false;
        } on FormatException {
          return false;
        }
        // The decoders return null for an unreadable row and never throw.
        return decode(row) != null;
      }

      final actual = read();
      if (actual) reads++;
      if (actual != p['appReads']) mismatches.add('${p['id']}: $actual');
    }
    expect(mismatches, isEmpty);
    expect(reads, greaterThan(120));
  });

  test('TG-040 records written by the real column writers equal accepted '
      'corpus payloads', () {
    final byId = {for (final p in _payloads) p['id'] as String: p};
    final writers = [
      for (final w
          in (_corpus['writerCases'] as List).cast<Map<String, dynamic>>())
        if (w['entity'] != 'weighIn') byId[w['payloadId']]!,
    ];
    expect(writers, hasLength(10));
    for (final p in writers) {
      final id = p['id'] as String;
      final rowId = _rowId(p);
      final content = _content(_decoded(p));
      final (
        Insertable<Object?> columns,
        List<String> fields,
      ) = switch (p['entity']) {
        'profile' => (
          profileColumns(ProfileRecord.fromWire(content)!),
          TargetWireFields.profile,
        ),
        'goalPhase' => (
          goalPhaseColumns(GoalPhaseRecord.fromWire(rowId, content)!),
          TargetWireFields.goalPhase,
        ),
        _ => (
          targetSettingsColumns(TargetSettingsRecord.fromWire(rowId, content)!),
          TargetWireFields.targetSettings,
        ),
      };
      expect(wireOfRow(columns, fields), _normalized(content), reason: id);
      expect(wireOfRow(columns, ['id']), {'id': rowId}, reason: id);
    }
  });

  test('B19 profileRowId equals the corpus profile id', () {
    final constants = _corpus['constants'] as Map<String, dynamic>;
    expect(profileRowId, constants['profileRowId']);
    final other = _payloads.singleWhere(
      (p) => p['id'] == 'profile-rowId-other-natural',
    );
    expect(other['rowId'], naturalId('profile', 'other'));
    expect(other['serverAccepts'], isFalse);
  });
}
