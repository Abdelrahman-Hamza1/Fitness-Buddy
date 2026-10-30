import 'dart:convert';
import 'dart:io';

import 'package:fb_domain/fb_domain.dart';

/// The custom type the custom bases point at (a UUIDv7, as the app mints).
const String measurementVectorsTypeId = '0199e3c2-5b1a-7c3d-8e4f-0123456789ab';

/// The row IDs the app test uses when a case has no `rowId` (any UUID is a
/// valid measurement row ID; the C# side mints its own).
const Map<String, String> measurementDefaultRowIds = {
  'measurementType': '0199e3c2-5b1a-7c3d-8e4f-0123456789ae',
  'measurement': '0199e3c2-5b1a-7c3d-8e4f-0123456789af',
};

/// The README's wire-rule bullet labels (`contracts/README.md` §
/// "Measurement semantic rules"), keyed by rule ID. A case's `rule` is the
/// label.
const Map<String, String> measurementRules = {
  'M1': 'M1 custom type',
  'M2': 'M2 unit fits kind',
  'M3': 'M3 percent bound',
};

/// Why a `measurement` case's `serverAccepts` may differ from `appWire`
/// (B20 D6). Closed: a new tag is a plan change.
/// - `schemaOnly`: metadata, extra or missing members, bounds, formats,
///   dates; things M1–M3 don't read (server rejects);
/// - `generic`: the server's generic representability pass (unpaired
///   surrogate, U+0000, duplicate key, a number decimal can't hold exactly);
/// - `decimalPrecision`: a value just past 100 that a double rounds onto
///   100 (server rejects with its decimal compare).
///
/// B19's `wholeNumberInteger` isn't needed: M1–M3 read no integer field, so
/// `180.0` for an integer is accepted on both sides. `rowId` isn't either:
/// measurements have no row-ID rule. `measurementType` has no wire rules, so
/// each of its rejections carries `schemaOnly` or `generic`.
const Set<String> measurementAsymmetries = {
  'schemaOnly',
  'generic',
  'decimalPrecision',
};

/// 2^53 − 1, the wire maximum of `measuredAtUtc` and `createdAtMs`. No
/// fb_domain constant: the C# test pins it to the schema.
const int measurementMaxInstant = 9007199254740991;

/// The wire maximum of a type `name`, in UTF-16 units (the schema's
/// `maxLength`; the app's own limit is 40 code points, A15b D15).
const int measurementMaxNameLength = 120;

/// The wire maximum of `origin`, in UTF-16 units.
const int measurementMaxOriginLength = 128;

/// `MeasurementWireRules.holds` on the decoded [payload] (B20 D6), `null`
/// for `measurementType` (no wire rules). False when M1–M3 can't even read
/// it: an unknown `kind` or `inputUnit` code, a `customTypeId` that isn't a
/// string or null (a missing one reads as null, as the table row does), or
/// a non-numeric `value`/`inputValue`; the schema rejects those too.
bool? measurementWireValid(String entity, Map<String, Object?> payload) {
  if (entity == 'measurementType') return null;
  if (entity != 'measurement') throw ArgumentError.value(entity, 'entity');
  final kind = switch (payload['kind']) {
    final String code => MeasurementKind.fromCode(code),
    _ => null,
  };
  final unit = switch (payload['inputUnit']) {
    final String code => MeasurementUnit.fromCode(code),
    _ => null,
  };
  final typeId = payload['customTypeId'];
  final value = payload['value'];
  final inputValue = payload['inputValue'];
  if (kind == null ||
      unit == null ||
      (typeId != null && typeId is! String) ||
      value is! num ||
      inputValue is! num) {
    return false;
  }
  return MeasurementWireRules.holds(
    kind: kind,
    customTypeId: typeId as String?,
    unit: unit,
    value: value.toDouble(),
    inputValue: inputValue.toDouble(),
  );
}

/// B20 synthetic corpus for the `measurementType` and `measurement` (v1)
/// sync entities (`contracts/testdata/README.md`). `serverAccepts` and
/// `appReads` are declarations: C# checks the first against `SyncPayloads`,
/// the app test checks the second against the real mappers. `appWire` is
/// computed here with the real `MeasurementWireRules.holds`.
Map<String, Object?> measurementVectors() {
  final c = _Corpus();
  _bases(c);
  _m1(c);
  _m2(c);
  _m3(c);
  _notWireRules(c);
  _schema(c);
  _members(c);
  _numbersAndGeneric(c);
  _tombstones(c);
  final payloads = c.payloads;
  return {
    'version': 1,
    'constants': {
      'maxPercent': MeasurementWireRules.maxPercent,
      'maxValue': MeasurementBounds.readMax,
      'tzOffsetMin': minTzOffsetMinutes,
      'tzOffsetMax': maxTzOffsetMinutes,
      'maxMeasuredAtUtc': measurementMaxInstant,
      'maxNameLength': measurementMaxNameLength,
      'maxOriginLength': measurementMaxOriginLength,
      'customKind': MeasurementKind.custom.code,
      'percentKind': MeasurementKind.bodyFat.code,
      'percentUnit': MeasurementUnit.percent.code,
    },
    'vocabularies': {
      'kind': [for (final v in MeasurementKind.values) v.code],
      'inputUnit': [for (final v in MeasurementUnit.values) v.code],
    },
    'rules': [
      for (final MapEntry(:key, :value) in measurementRules.entries)
        {'id': key, 'readme': value},
    ],
    'payloads': payloads,
    'serverRejectsAppTolerates': [
      for (final p in payloads)
        if (p['serverAccepts'] == false && p['appReads'] == true) p['id'],
    ],
    'serverAcceptsAppSkips': [
      for (final p in payloads)
        if (p['serverAccepts'] == true && p['appReads'] == false) p['id'],
    ],
    'writerCases': c.writers,
  };
}

final class _Corpus {
  final payloads = <Map<String, Object?>>[];
  final writers = <Map<String, Object?>>[];
  final _raws = <String>[];

  /// A JSON value written as [text] exactly (a number Dart can't encode the
  /// same way, an escaped surrogate).
  String raw(String text) {
    _raws.add(text);
    return '<<raw:${_raws.length - 1}>>';
  }

  String encode(Map<String, Object?> payload) => jsonEncode(payload)
      .replaceAllMapped(
        RegExp('"<<raw:([0-9]+)>>"'),
        (m) => _raws[int.parse(m[1]!)],
      );

  /// Adds the case [id]; with [tombstone], also its full-payload tombstone
  /// `<id>-tombstone` (same outcome, B20 D3). [app] defaults to [server].
  void add(
    String id,
    String entity,
    Map<String, Object?> payload, {
    required bool server,
    String? rowId,
    String? rule,
    String? asymmetry,
    bool? app,
    bool deleted = false,
    bool tombstone = false,
    String? rawPayload,
  }) {
    final text = rawPayload ?? encode(payload);
    final decoded = jsonDecode(text) as Map<String, Object?>;
    for (final (suffix, dead) in [
      ('', deleted),
      if (tombstone) ('-tombstone', true),
    ]) {
      payloads.add({
        'id': '$id$suffix',
        'entity': entity,
        'schemaVersion': 1,
        'rowId': ?rowId,
        'rawPayload': text,
        'deleted': dead,
        'rule': ?rule,
        'asymmetry': ?asymmetry,
        'serverAccepts': server,
        'appWire': measurementWireValid(entity, decoded),
        'appReads': app ?? server,
      });
    }
  }
}

const Map<String, Object?> _meta = {
  'createdAtMs': 0,
  'origin': 'synthetic',
  'editedByUser': false,
};

final EntryTime _time = EntryTime(DateTime.utc(2026, 10, 28, 2, 30), 180);

/// The base type name, as typed and as stored.
const String _typeName = 'Left arm';

/// A payload from [draft]'s getters (A15b D13), in contract order.
Map<String, Object?> _measurement(MeasurementDraft draft) => {
  ..._meta,
  'kind': draft.type.kind.code,
  'customTypeId': draft.type.customTypeId,
  'measuredAtUtc': draft.time.occurredAtUtc.millisecondsSinceEpoch,
  'tzOffsetMin': draft.time.tzOffsetMin,
  'localDate': '${draft.localDate}',
  'value': draft.value,
  'inputValue': draft.input.value,
  'inputUnit': draft.input.unit.code,
};

MeasurementDraft _draft(
  MeasurementTypeRef type,
  double value,
  MeasurementUnit unit,
) => MeasurementDraft(
  type: type,
  time: _time,
  input: MeasurementInput(value, unit),
);

/// The built-in length kinds (every kind but body fat and custom).
final List<MeasurementKind> _lengths = [
  for (final kind in MeasurementKind.builtIns)
    if (kind.isLength) kind,
];

const Map<MeasurementKind, double> _typicalCm = {
  MeasurementKind.waist: 92.5,
  MeasurementKind.chest: 101.2,
  MeasurementKind.hips: 98.4,
  MeasurementKind.arm: 33.1,
  MeasurementKind.thigh: 55.7,
  MeasurementKind.neck: 38.2,
};

Map<String, Object?> _builtIn(MeasurementKind kind) => _measurement(
  _draft(
    MeasurementTypeRef.builtIn(kind),
    _typicalCm[kind]!,
    MeasurementUnit.cm,
  ),
);

final Map<String, Object?> _waist = _builtIn(MeasurementKind.waist);

final Map<String, Object?> _waistInches = _measurement(
  _draft(
    MeasurementTypeRef.builtIn(MeasurementKind.waist),
    36.5,
    MeasurementUnit.inch,
  ),
);

final Map<String, Object?> _bodyFat = _measurement(
  _draft(
    MeasurementTypeRef.builtIn(MeasurementKind.bodyFat),
    18.4,
    MeasurementUnit.percent,
  ),
);

final Map<String, Object?> _customCm = _measurement(
  _draft(
    MeasurementTypeRef.custom(measurementVectorsTypeId),
    34.3,
    MeasurementUnit.cm,
  ),
);

final Map<String, Object?> _customInches = _measurement(
  _draft(
    MeasurementTypeRef.custom(measurementVectorsTypeId),
    13.5,
    MeasurementUnit.inch,
  ),
);

final Map<String, Object?> _type = {
  ..._meta,
  'name': CustomTypeName.normalize(_typeName),
};

Map<String, Object?> _without(Map<String, Object?> payload, String key) =>
    Map.of(payload)..remove(key);

/// [kind]'s base payload.
Map<String, Object?> _baseOf(MeasurementKind kind) => switch (kind) {
  MeasurementKind.bodyFat => _bodyFat,
  MeasurementKind.custom => _customCm,
  _ => _builtIn(kind),
};

void _bases(_Corpus c) {
  void base(String id, Map<String, Object?> payload) {
    c
      ..add(id, 'measurement', payload, server: true, tombstone: true)
      ..writers.add({
        'id': 'writer-$id',
        'entity': 'measurement',
        'payloadId': id,
      });
  }

  c.add(
    'measurementType-base',
    'measurementType',
    _type,
    server: true,
    tombstone: true,
  );
  for (final (id, name) in [
    ('writer-measurementType-base', _typeName),
    ('writer-measurementType-trimmed', '  $_typeName '),
  ]) {
    c.writers.add({
      'id': id,
      'entity': 'measurementType',
      'payloadId': 'measurementType-base',
      'name': name,
    });
  }
  for (final kind in _lengths) {
    base('measurement-base-${kind.code}', _builtIn(kind));
  }
  base('measurement-base-waist-in', _waistInches);
  base('measurement-base-bodyFat', _bodyFat);
  base('measurement-base-custom-cm', _customCm);
  base('measurement-base-custom-in', _customInches);
}

void _m1(_Corpus c) {
  final rule = measurementRules['M1'];
  c
    ..add(
      'measurement-M1-custom-with-type',
      'measurement',
      _customCm,
      server: true,
      rule: rule,
    )
    ..add(
      'measurement-M1-custom-null-type',
      'measurement',
      {..._customCm, 'customTypeId': null},
      server: false,
      rule: rule,
      tombstone: true,
    );
  for (final kind in MeasurementKind.builtIns) {
    c.add(
      'measurement-M1-${kind.code}-with-type',
      'measurement',
      {..._baseOf(kind), 'customTypeId': measurementVectorsTypeId},
      server: false,
      rule: rule,
      tombstone: true,
    );
  }
}

void _m2(_Corpus c) {
  final rule = measurementRules['M2'];
  c
    ..add(
      'measurement-M2-waist-in',
      'measurement',
      _waistInches,
      server: true,
      rule: rule,
    )
    ..add(
      'measurement-M2-bodyFat-percent',
      'measurement',
      _bodyFat,
      server: true,
      rule: rule,
    );
  for (final unit in [MeasurementUnit.cm, MeasurementUnit.inch]) {
    c.add(
      'measurement-M2-bodyFat-${unit.code}',
      'measurement',
      {..._bodyFat, 'inputUnit': unit.code},
      server: false,
      rule: rule,
      tombstone: true,
    );
  }
  for (final kind in [..._lengths, MeasurementKind.custom]) {
    c.add(
      'measurement-M2-${kind.code}-percent',
      'measurement',
      {..._baseOf(kind), 'inputUnit': MeasurementUnit.percent.code},
      server: false,
      rule: rule,
      tombstone: true,
    );
  }
}

void _m3(_Corpus c) {
  final rule = measurementRules['M3'];
  void bodyFat(
    String id,
    Map<String, Object?> changes, {
    required bool server,
    bool? app,
    String? asymmetry,
    bool tombstone = false,
  }) => c.add(
    'measurement-M3-bodyFat-$id',
    'measurement',
    {..._bodyFat, ...changes},
    server: server,
    app: app,
    rule: rule,
    asymmetry: asymmetry,
    tombstone: tombstone,
  );

  bodyFat('100', {'value': 100, 'inputValue': 100}, server: true);
  bodyFat('100.0', {'value': 100.0, 'inputValue': 100.0}, server: true);
  bodyFat(
    'value-100.0000001',
    {'value': 100.0000001, 'inputValue': 100.0},
    server: false,
    tombstone: true,
  );
  bodyFat(
    'inputValue-100.01',
    {'value': 99.0, 'inputValue': 100.01},
    server: false,
    tombstone: true,
  );
  // Inside the wire, below the app's read bound (> 0).
  bodyFat('value-zero', {'value': 0.0}, server: true, app: false);
  bodyFat('value-negative-zero', {'value': -0.0}, server: true, app: false);
  // A double rounds it onto 100; the server's decimal compare doesn't.
  bodyFat(
    'value-100.0000000000000001',
    {'value': c.raw('100.0000000000000001')},
    server: false,
    app: true,
    asymmetry: 'decimalPrecision',
  );
  // Overflow: infinity in Dart, unrepresentable as a decimal.
  bodyFat('value-1e400', {'value': c.raw('1e400')}, server: false);
  // M3 applies to body fat only.
  c.add(
    'measurement-M3-waist-150',
    'measurement',
    {..._waist, 'value': 150.0, 'inputValue': 150.0},
    server: true,
    rule: rule,
  );
}

/// Rules that are app-only or cross-row (B20 D3): all server-accepted.
/// `notWire-range-*` break a local plausibility range,
/// `notWire-convention-*` an app convention nobody checks on the wire.
void _notWireRules(_Corpus c) {
  void measurement(String id, Map<String, Object?> payload, {String? rowId}) =>
      c.add('notWire-$id', 'measurement', payload, server: true, rowId: rowId);

  measurement('range-waist-5cm', {..._waist, 'value': 5.0, 'inputValue': 5.0});
  measurement('range-waist-999999cm', {
    ..._waist,
    'value': 999999.0,
    'inputValue': 999999.0,
  });
  measurement('range-bodyFat-1', {
    ..._bodyFat,
    'value': 1.0,
    'inputValue': 1.0,
  });
  measurement('range-bodyFat-90', {
    ..._bodyFat,
    'value': 90.0,
    'inputValue': 90.0,
  });
  measurement('convention-factor', {..._waistInches, 'value': 50.0});
  measurement('convention-localDate', {..._waist, 'localDate': '2026-01-01'});
  for (final (name, id) in [
    ('type-never-created', '0199e3c2-5b1a-7c3d-8e4f-0123456789ff'),
    ('type-nil', '00000000-0000-0000-0000-000000000000'),
    ('type-v4', '3f2b8c1e-9d4a-4e6f-8b7c-1a2b3c4d5e6f'),
  ]) {
    measurement('convention-$name', {..._customCm, 'customTypeId': id});
  }
  measurement(
    'convention-rowId-v4',
    _waist,
    rowId: '6a1f3e2d-4c5b-4a69-8f7e-0d1c2b3a4958',
  );
  // The app skips an empty or blank name on read (A15b D25).
  for (final (name, text, app) in [
    ('empty', '', false),
    ('blank', '   ', false),
    ('control', 'Left\u0007arm', true),
  ]) {
    c.add(
      'notWire-convention-name-$name',
      'measurementType',
      {..._type, 'name': text},
      server: true,
      app: app,
    );
  }
}

void _schema(_Corpus c) {
  void m(
    String id,
    Map<String, Object?> payload, {
    required bool server,
    bool? app,
    String? asymmetry,
  }) => c.add(
    'measurement-$id',
    'measurement',
    payload,
    server: server,
    app: app,
    asymmetry: asymmetry,
  );

  for (final (name, base, code) in [
    ('unknown', _waist, 'wrist'),
    ('BodyFat', _bodyFat, 'BodyFat'),
    ('WAIST', _waist, 'WAIST'),
  ]) {
    m('kind-$name', {...base, 'kind': code}, server: false);
  }
  for (final (name, code) in [
    ('inch', 'inch'),
    ('IN', 'IN'),
    ('percent-sign', '%'),
    ('empty', ''),
    ('null', null),
  ]) {
    m('inputUnit-$name', {..._waist, 'inputUnit': code}, server: false);
  }
  // A non-null ID keeps M1 on a custom row; the format is the schema's.
  for (final (name, id) in [
    ('uppercase', measurementVectorsTypeId.toUpperCase()),
    ('no-hyphens', measurementVectorsTypeId.replaceAll('-', '')),
    ('braces', '{$measurementVectorsTypeId}'),
    ('empty', ''),
  ]) {
    m(
      'customTypeId-$name',
      {..._customCm, 'customTypeId': id},
      server: false,
      asymmetry: 'schemaOnly',
    );
  }
  // The row's text column reads 5 as '5', not a UUID.
  m('customTypeId-number', {..._customCm, 'customTypeId': 5}, server: false);

  final measuredAt = _waist['measuredAtUtc']! as int;
  // The read model takes any instant whose wall clock is in years 1–9999.
  for (final (name, value, server, app, tag)
      in <(String, Object, bool, bool, String?)>[
        ('negative', -1, false, true, 'schemaOnly'),
        ('max', measurementMaxInstant, true, false, null),
        ('over-max', measurementMaxInstant + 1, false, false, 'schemaOnly'),
        // The row's integer column truncates 1.5.
        ('1.5', 1.5, false, true, 'schemaOnly'),
        ('whole-number-double', c.raw('$measuredAt.0'), true, true, null),
      ]) {
    m(
      'measuredAtUtc-$name',
      {..._waist, 'measuredAtUtc': value},
      server: server,
      app: app,
      asymmetry: tag,
    );
  }
  for (final (name, value, server, app, tag)
      in <(String, Object, bool, bool, String?)>[
        ('min', minTzOffsetMinutes, true, true, null),
        ('max', maxTzOffsetMinutes, true, true, null),
        ('under-min', minTzOffsetMinutes - 1, false, false, 'schemaOnly'),
        ('over-max', maxTzOffsetMinutes + 1, false, false, 'schemaOnly'),
        // The row's integer column truncates 60.5 and parses "60".
        ('60.5', 60.5, false, true, 'schemaOnly'),
        ('string', '60', false, true, 'schemaOnly'),
        ('whole-number-double', c.raw('180.0'), true, true, null),
      ]) {
    m(
      'tzOffsetMin-$name',
      {..._waist, 'tzOffsetMin': value},
      server: server,
      app: app,
      asymmetry: tag,
    );
  }
  for (final (name, text, server) in [
    ('2026-02-29', '2026-02-29', false),
    ('0000-01-01', '0000-01-01', false),
    ('9999-12-31', '9999-12-31', true),
    ('short-month', '2026-1-28', false),
    ('padded-year', '02026-10-28', false),
    ('arabic-indic-digits', '٢٠٢٦-١٠-٢٨', false),
  ]) {
    m(
      'localDate-$name',
      {..._waist, 'localDate': text},
      server: server,
      asymmetry: server ? null : 'schemaOnly',
    );
  }
  // M3 doesn't read a length's numbers; the app reads (0, 1e6] only.
  for (final field in ['value', 'inputValue']) {
    for (final (name, value, server, app, tag)
        in <(String, Object?, bool, bool, String?)>[
          ('negative', -0.1, false, false, 'schemaOnly'),
          ('max', MeasurementBounds.readMax, true, true, null),
          ('over-max', 1000000.001, false, false, 'schemaOnly'),
          ('null', null, false, false, null),
          ('string', '92.5', false, false, null),
        ]) {
      m(
        '$field-$name',
        {..._waist, field: value},
        server: server,
        app: app,
        asymmetry: tag,
      );
    }
  }

  // measurementType has no wire rules: every rejection is schema-only.
  void t(String id, Object? name, {required bool server, bool? app}) => c.add(
    'measurementType-name-$id',
    'measurementType',
    {..._type, 'name': name},
    server: server,
    app: app,
    asymmetry: server ? null : 'schemaOnly',
  );
  const max = measurementMaxNameLength;
  t('max', 'm' * max, server: true);
  t('over-max', 'm' * (max + 1), server: false, app: true);
  t('supplementary-max', '${'m' * (max - 2)}\u{1f34e}', server: true);
  t(
    'supplementary-over-max',
    '${'m' * (max - 1)}\u{1f34e}',
    server: false,
    app: true,
  );
  t('arabic', 'ذراع يسار', server: true);
  t('null', null, server: false);
  // The row's text column reads 5 as '5'.
  t('number', 5, server: false, app: true);
}

/// Members and metadata, for both entities: every member missing, an extra
/// member, wrong metadata types and the metadata boundaries (plan review
/// round 1). The app maps no metadata (A34 owns it), so it reads those.
void _members(_Corpus c) {
  const metadata = {'createdAtMs', 'origin', 'editedByUser'};
  // Missing members M1–M3 read: wire-invalid too, so untagged.
  const wireRead = {'kind', 'value', 'inputValue', 'inputUnit'};
  for (final (entity, base) in [
    ('measurementType', _type),
    ('measurement', _waist),
  ]) {
    void add(
      String id,
      Map<String, Object?> payload, {
      required bool server,
      bool app = true,
      String? asymmetry = 'schemaOnly',
    }) => c.add(
      '$entity-$id',
      entity,
      payload,
      server: server,
      app: app,
      asymmetry: server ? null : asymmetry,
    );

    for (final field in base.keys) {
      add(
        'missing-$field',
        _without(base, field),
        server: false,
        // A missing nullable customTypeId reads as null.
        app: metadata.contains(field) || field == 'customTypeId',
        asymmetry: entity == 'measurement' && wireRead.contains(field)
            ? null
            : 'schemaOnly',
      );
    }
    add('extra-member', {
      ...base,
      entity == 'measurement' ? 'unit' : 'color': 'cm',
    }, server: false);
    add('origin-number', {...base, 'origin': 5}, server: false);
    add('editedByUser-null', {...base, 'editedByUser': null}, server: false);
    add('createdAtMs-string', {...base, 'createdAtMs': '0'}, server: false);
    add('createdAtMs-zero', {...base, 'createdAtMs': 0}, server: true);
    add('createdAtMs-max', {
      ...base,
      'createdAtMs': measurementMaxInstant,
    }, server: true);
    add('createdAtMs-negative', {...base, 'createdAtMs': -1}, server: false);
    add('createdAtMs-over-max', {
      ...base,
      'createdAtMs': measurementMaxInstant + 1,
    }, server: false);
    add('createdAtMs-1.5', {...base, 'createdAtMs': 1.5}, server: false);
    add(
      'createdAtMs-1e400',
      {...base, 'createdAtMs': c.raw('1e400')},
      server: false,
      asymmetry: 'generic',
    );
    add('origin-max', {
      ...base,
      'origin': 'o' * measurementMaxOriginLength,
    }, server: true);
    add('origin-over-max', {
      ...base,
      'origin': 'o' * (measurementMaxOriginLength + 1),
    }, server: false);
  }
}

void _numbersAndGeneric(_Corpus c) {
  // Quoted, a string: no number on either side.
  for (final (name, text) in [
    ('nan-quoted', '"NaN"'),
    ('infinity-quoted', '"Infinity"'),
  ]) {
    c.add('measurement-bodyFat-value-$name', 'measurement', {
      ..._bodyFat,
      'value': c.raw(text),
    }, server: false);
  }
  // Dart reads ±1e400 as ±infinity and 1e-400 as 0.0, a 31-digit decimal as
  // 92.5; M1–M3 don't bound a length, the representability pass rejects.
  for (final (name, text, app) in [
    ('1e400', '1e400', false),
    ('minus-1e400', '-1e400', false),
    ('1e-400', '1e-400', false),
    ('31-digits', '92.50000000000000000000000000001', true),
  ]) {
    c.add(
      'measurement-waist-value-$name',
      'measurement',
      {..._waist, 'value': c.raw(text)},
      server: false,
      app: app,
      asymmetry: 'generic',
    );
  }
  for (final (name, text) in [
    ('lone-high-surrogate', r'"x\ud800"'),
    ('lone-low-surrogate', r'"\udc00x"'),
  ]) {
    c.add(
      'measurementType-name-$name',
      'measurementType',
      {..._type, 'name': c.raw(text)},
      server: false,
      app: true,
      asymmetry: 'generic',
    );
  }
  c.add(
    'measurementType-name-nul',
    'measurementType',
    {..._type, 'name': 'x\u0000'},
    server: false,
    app: true,
    asymmetry: 'generic',
  );
  // Dart keeps the last duplicate (waist); the server rejects any.
  final raw = c.encode(_waist);
  c.add(
    'measurement-duplicate-kind',
    'measurement',
    _waist,
    rawPayload: raw.replaceFirst('"kind":', '"kind":"bodyFat","kind":'),
    server: false,
    app: true,
    asymmetry: 'generic',
  );
}

/// Scrubbed tombstones (B20 D8, backlog #136): the server checks no
/// scrubbing, so the live rules apply; values 0 are below the app's read
/// bound.
void _tombstones(_Corpus c) {
  c.add(
    'measurementType-tombstone-scrubbed',
    'measurementType',
    {..._type, 'name': ''},
    server: true,
    app: false,
    deleted: true,
  );
  for (final (name, base) in [
    ('waist', _waist),
    ('bodyFat', _bodyFat),
    ('custom', _customCm),
  ]) {
    c.add(
      'measurement-tombstone-scrubbed-$name',
      'measurement',
      {...base, 'value': 0.0, 'inputValue': 0.0},
      server: true,
      app: false,
      deleted: true,
    );
  }
  // Scrubbing must keep the M1–M3 pairing.
  c.add(
    'measurement-tombstone-scrubbed-custom-null-type',
    'measurement',
    {..._customCm, 'customTypeId': null, 'value': 0.0, 'inputValue': 0.0},
    server: false,
    rule: measurementRules['M1'],
    deleted: true,
  );
}

/// Stable JSON bytes shared by the Dart and C# tests.
String generateMeasurementVectors() =>
    '${const JsonEncoder.withIndent('  ').convert(measurementVectors())}\n';

/// Writes only the corpus; the drift test calls the in-memory function.
void main() {
  File.fromUri(
    Platform.script.resolve(
      '../../../contracts/testdata/sync/measurement-validation-vectors.json',
    ),
  ).writeAsStringSync(generateMeasurementVectors());
}
