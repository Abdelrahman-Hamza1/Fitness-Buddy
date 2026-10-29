import 'dart:convert';
import 'dart:io';

import 'package:fb_domain/fb_domain.dart';

/// `naturalId('profile', 'self')` (TD-070). The app derives it (UUIDv5 in
/// `apps/mobile`), so the corpus writes the literal and the app test proves
/// it equal.
const String bodyTargetsProfileRowId = 'f0b8e132-056c-5b98-8c9b-ff9a6dc1bb96';

/// `naturalId('profile', 'other')`: a UUIDv5 that isn't the profile row.
const String bodyTargetsOtherProfileId = '4e5d373d-7494-53a9-b84b-facb16b0cb21';

/// The row IDs the app and C# tests use when a case has no `rowId`
/// (weighIn rows may have any UUID; the C# side mints its own).
const Map<String, String> bodyTargetsDefaultRowIds = {
  'profile': bodyTargetsProfileRowId,
  'goalPhase': '0199e3c2-5b1a-7c3d-8e4f-0123456789ab',
  'targetSettings': '0199e3c2-5b1a-7c3d-8e4f-0123456789ac',
  'weighIn': '0199e3c2-5b1a-7c3d-8e4f-0123456789ad',
};

/// The README's wire-rule bullet labels (`contracts/README.md` § "Targets
/// semantic rules"), keyed by a stable slug. A case's `rule` is the label
/// (B19 PA4).
const Map<String, String> bodyTargetsRules = {
  'positiveNumbers': 'Positive numbers',
  'expressionFields': 'Expression fields',
  'maintain': 'Maintain',
  'phaseDates': 'Phase dates',
  'macroPairs': 'Macro pairs',
  'acknowledgement': 'Acknowledgement',
  'rowIds': 'Row IDs',
};

/// Why a targets case's `serverAccepts` may differ from `appWire` (B19 D9,
/// PA5). Closed: a new tag is a plan change.
/// - `schemaOnly`: metadata, extra or missing members the wire rules don't
///   read (server rejects);
/// - `generic`: the server's generic representability pass (unpaired
///   surrogate, U+0000, duplicate key, a number decimal can't hold exactly);
/// - `rowId`: the row-ID rule, which `TargetRules.wire` doesn't see;
/// - `wholeNumberInteger`: `1990.0` for an integer (server accepts, raw
///   `TargetRules.wire` rejects: the A34 decoding note);
/// - `decimalPrecision`: a value just past a bound that a double rounds
///   onto it (server rejects with its decimal compare).
const Set<String> bodyTargetsAsymmetries = {
  'schemaOnly',
  'generic',
  'rowId',
  'wholeNumberInteger',
  'decimalPrecision',
};

const _targets = {'profile', 'goalPhase', 'targetSettings'};

/// `TargetRules.wire` on [payload] (sync metadata is ignored there).
bool bodyTargetsWireValid(String entity, Map<String, Object?> payload) =>
    switch (entity) {
      'profile' => TargetRules.wire.profile(payload),
      'goalPhase' => TargetRules.wire.goalPhase(payload),
      'targetSettings' => TargetRules.wire.targetSettings(payload),
      _ => throw ArgumentError.value(entity, 'entity'),
    }.isEmpty;

/// B19 synthetic corpus for the `profile`, `goalPhase`, `targetSettings`
/// (v1) and `weighIn` (v1, v2) sync entities (`contracts/testdata/README.md`).
/// `serverAccepts` and `appReads` are declarations: C# checks the first
/// against `SyncPayloads`, the app tests check the second against the real
/// decoders. `appWire` is computed here with the real `TargetRules.wire`.
Map<String, Object?> bodyTargetsVectors() {
  final c = _Corpus();
  _bases(c);
  _positiveNumbers(c);
  _expressionFields(c);
  _maintain(c);
  _phaseDates(c);
  _macroPairs(c);
  _acknowledgement(c);
  _rowIds(c);
  _plausibility(c);
  _targetsSchema(c);
  _numbersAndGeneric(c);
  _weighIn(c);
  final payloads = c.payloads;
  return {
    'version': 1,
    'constants': {
      'maxNumber': TargetLimits.maxNumber,
      'maxRevision': TargetWireRules.maxRevision,
      'maxNameLength': TargetWireRules.maxNameLength,
      'maxPercent': TargetWireRules.maxPercent,
      'tzOffsetMin': minTzOffsetMinutes,
      'tzOffsetMax': maxTzOffsetMinutes,
      'profileRowId': bodyTargetsProfileRowId,
    },
    'vocabularies': {
      'sex': [for (final v in FormulaSex.values) v.name],
      'heightInputUnit': [for (final v in HeightInputUnit.values) v.code],
      'activity': [for (final v in ActivityLevel.values) v.name],
      'goalType': [for (final v in GoalType.values) v.name],
      'expressionKind': [for (final v in GoalExpressionKind.values) v.name],
      'weightInputUnit': [for (final v in GoalWeightUnits.values) v.code],
      'mode': [for (final v in TargetMode.values) v.name],
      'inputUnit': [for (final v in WeighInInput.units) v.code],
    },
    'rules': [
      for (final MapEntry(:key, :value) in bodyTargetsRules.entries)
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
    'writerCases': [
      for (final id in c.writers)
        {
          'id': 'writer-$id',
          'entity': payloads.firstWhere((p) => p['id'] == id)['entity'],
          'payloadId': id,
        },
    ],
  };
}

final class _Corpus {
  final payloads = <Map<String, Object?>>[];
  final writers = <String>[];
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
  /// `<id>-tombstone` (same outcome, B19 D3).
  void add(
    String id,
    String entity,
    Map<String, Object?> payload, {
    required bool server,
    int schemaVersion = 1,
    String? rowId,
    String? rule,
    String? asymmetry,
    bool? app,
    bool deleted = false,
    bool tombstone = false,
    String? rawPayload,
  }) {
    final text = rawPayload ?? encode(payload);
    final isTargets = _targets.contains(entity);
    final decoded = jsonDecode(text) as Map<String, Object?>;
    final wire = isTargets ? bodyTargetsWireValid(entity, decoded) : null;
    final bool? reads;
    if (entity == 'weighIn' && schemaVersion == 1) {
      // No app reader for v1: A34's v1→v2 upgrader (A14 D7).
      reads = null;
    } else if (app != null) {
      reads = app;
    } else if (isTargets) {
      reads = _recordReads(entity, rowId, decoded);
    } else {
      reads = server;
    }
    for (final (suffix, dead) in [
      ('', deleted),
      if (tombstone) ('-tombstone', true),
    ]) {
      payloads.add({
        'id': '$id$suffix',
        'entity': entity,
        'schemaVersion': schemaVersion,
        'rowId': ?rowId,
        'rawPayload': text,
        'deleted': dead,
        'rule': ?rule,
        'asymmetry': ?asymmetry,
        'serverAccepts': server,
        'appWire': wire,
        'appReads': reads,
      });
    }
  }
}

/// The fb_domain record decoders, the default `appReads` for targets (the
/// app reads the row as the server pulls it: a lowercase ID).
bool _recordReads(String entity, String? rowId, Map<String, Object?> wire) {
  final id = (rowId ?? bodyTargetsDefaultRowIds[entity]!).toLowerCase();
  return switch (entity) {
        'profile' => ProfileRecord.fromWire(wire),
        'goalPhase' => GoalPhaseRecord.fromWire(id, wire),
        _ => TargetSettingsRecord.fromWire(id, wire),
      } !=
      null;
}

const Map<String, Object?> _meta = {
  'createdAtMs': 0,
  'origin': 'synthetic',
  'editedByUser': false,
};

final LocalDate _start = LocalDate(2026, 10, 28);

Map<String, Object?> _profile([ProfileRecord? record]) => {
  ..._meta,
  ...(record ??
          const ProfileRecord(
            sex: FormulaSex.female,
            birthYear: 1990,
            heightCm: 165,
            heightInputUnit: HeightInputUnit.centimeter,
            activity: ActivityLevel.light,
          ))
      .toWire(),
};

GoalExpression _expression(GoalExpressionKind kind) => switch (kind) {
  GoalExpressionKind.targetDate => GoalExpression.targetDate(
    72,
    LocalDate(2027, 3, 1),
  ),
  GoalExpressionKind.targetRate => GoalExpression.targetRate(72, 0.5),
  GoalExpressionKind.weekly => GoalExpression.weekly(-0.5),
  GoalExpressionKind.monthly => GoalExpression.monthly(
    -2,
    LocalDate(2026, 11, 1),
  ),
};

Map<String, Object?> _phase(
  GoalExpressionKind kind, {
  GoalType type = GoalType.lose,
  GoalExpression? expression,
  MassUnit unit = MassUnit.kilogram,
}) => {
  ..._meta,
  ...GoalPhaseRecord(
    id: bodyTargetsDefaultRowIds['goalPhase']!,
    revision: 1,
    name: 'Synthetic goal',
    start: _start,
    type: type,
    expression: expression ?? _expression(kind),
    weightInputUnit: unit,
  ).toWire(),
};

Map<String, Object?> _settings({
  bool manual = false,
  bool acknowledged = false,
  TargetMode mode = TargetMode.weekly,
}) => {
  ..._meta,
  ...TargetSettingsRecord(
    id: bodyTargetsDefaultRowIds['targetSettings']!,
    revision: 1,
    effectiveFrom: _start,
    baseKcal: 2150.5,
    basisWeightKg: 82.4,
    mode: mode,
    manual: manual,
    acknowledged: acknowledged,
    shifts: const {DayOfWeek.friday: 1.3},
    macros: MacroSettings(
      protein: MacroOverride.grams(140),
      fat: MacroOverride.percent(25),
      fiberGrams: 30,
    ),
  ).toWire(),
};

/// A v2 payload from [draft]'s getters (A14 D6), with `preferredForDay`.
Map<String, Object?> _weighIn2(WeighInDraft draft, {bool preferred = false}) =>
    {
      ..._meta,
      'measuredAtUtc': draft.time.occurredAtUtc.millisecondsSinceEpoch,
      'localDate': '${draft.localDate}',
      'kg': draft.kg,
      'note': draft.note,
      'tzOffsetMin': draft.time.tzOffsetMin,
      'inputValue': draft.input.value,
      'inputUnit': draft.input.unit.code,
      'preferredForDay': preferred,
    };

final WeighInDraft _draft = WeighInDraft(
  time: EntryTime(DateTime.utc(2026, 10, 28, 5, 30), 180),
  input: const WeighInInput(179, MassUnit.pound),
);

final Map<String, Object?> _weighIn2Base = _weighIn2(_draft);

final Map<String, Object?> _weighIn1Base = {
  for (final MapEntry(:key, :value) in _weighIn2Base.entries)
    if (!_weighInV2Only.contains(key)) key: value,
};

const _weighInV2Only = [
  'tzOffsetMin',
  'inputValue',
  'inputUnit',
  'preferredForDay',
];

Map<String, Object?> _without(Map<String, Object?> payload, String key) =>
    Map.of(payload)..remove(key);

void _bases(_Corpus c) {
  void base(
    String id,
    String entity,
    Map<String, Object?> payload, {
    int schemaVersion = 1,
  }) {
    c
      ..add(
        id,
        entity,
        payload,
        schemaVersion: schemaVersion,
        server: true,
        tombstone: true,
      )
      ..writers.add(id);
  }

  base('profile-base', 'profile', _profile());
  base(
    'profile-ft-in',
    'profile',
    _profile(
      const ProfileRecord(
        sex: FormulaSex.male,
        birthYear: 1985,
        heightCm: 180.34,
        heightInputUnit: HeightInputUnit.feetInches,
        activity: ActivityLevel.moderate,
      ),
    ),
  );
  for (final kind in GoalExpressionKind.values) {
    base('goalPhase-base-${kind.name}', 'goalPhase', _phase(kind));
  }
  base(
    'goalPhase-lb',
    'goalPhase',
    _phase(GoalExpressionKind.weekly, unit: MassUnit.pound),
  );
  base('targetSettings-base', 'targetSettings', _settings());
  base(
    'targetSettings-manual-acknowledged-fixed',
    'targetSettings',
    _settings(manual: true, acknowledged: true, mode: TargetMode.fixed),
  );
  c.add(
    'weighIn1-base',
    'weighIn',
    _weighIn1Base,
    server: true,
    tombstone: true,
  );
  base('weighIn2-base', 'weighIn', _weighIn2Base, schemaVersion: 2);
  base(
    'weighIn2-kg-note',
    'weighIn',
    _weighIn2(
      WeighInDraft(
        time: EntryTime(DateTime.utc(2026, 10, 29, 2), -300),
        input: const WeighInInput(81.4, MassUnit.kilogram),
        note: 'Synthetic note',
      ),
    ),
    schemaVersion: 2,
  );
}

void _positiveNumbers(_Corpus c) {
  const rule = 'Positive numbers';
  final cases = <(String, String, Map<String, Object?>)>[
    ('profile', 'heightCm', _profile()),
    ('targetSettings', 'baseKcal', _settings()),
    ('targetSettings', 'basisWeightKg', _settings()),
    ('goalPhase', 'targetKg', _phase(GoalExpressionKind.targetDate)),
  ];
  for (final (entity, field, base) in cases) {
    final prefix = '$entity-$field';
    c
      ..add(
        '$prefix-zero',
        entity,
        {...base, field: 0.0},
        server: false,
        rule: rule,
        tombstone: true,
      )
      ..add(
        '$prefix-negative-zero',
        entity,
        {...base, field: -0.0},
        server: false,
        rule: rule,
        tombstone: true,
      )
      ..add(
        '$prefix-1e-28',
        entity,
        {...base, field: c.raw('1e-28')},
        server: true,
        rule: rule,
        tombstone: true,
      )
      ..add(
        '$prefix-negative',
        entity,
        {...base, field: -1.0},
        server: false,
        rule: rule,
        tombstone: true,
      );
  }
  c
    ..add(
      'goalPhase-targetKg-zero-targetRate',
      'goalPhase',
      {..._phase(GoalExpressionKind.targetRate), 'targetKg': 0.0},
      server: false,
      rule: rule,
      tombstone: true,
    )
    ..add(
      'goalPhase-targetKg-null-weekly',
      'goalPhase',
      _phase(GoalExpressionKind.weekly),
      server: true,
      rule: rule,
    );
}

void _expressionFields(_Corpus c) {
  const rule = 'Expression fields';
  const on = {
    'targetKg': 72.0,
    'targetDate': '2027-03-01',
    'kgPerWeek': 0.5,
    'monthKg': -2.0,
    'month': '2026-11-01',
  };
  for (final kind in GoalExpressionKind.values) {
    final base = _phase(kind);
    c.add(
      'goalPhase-expression-${kind.name}-exact',
      'goalPhase',
      base,
      server: true,
      rule: rule,
    );
    for (final MapEntry(key: field, :value) in on.entries) {
      final present = base[field] != null;
      c.add(
        'goalPhase-expression-${kind.name}-'
            '${present ? 'without' : 'with'}-$field',
        'goalPhase',
        {...base, field: present ? null : value},
        server: false,
        rule: rule,
        tombstone: true,
      );
    }
  }
  // A target-rate speed is positive; the target sets the direction (R3).
  final rate = _phase(GoalExpressionKind.targetRate);
  for (final (name, value, accepted) in [
    ('zero', 0.0, false),
    ('negative-zero', -0.0, false),
    ('negative', -0.5, false),
    ('positive', 0.5, true),
  ]) {
    c.add(
      'goalPhase-targetRate-speed-$name',
      'goalPhase',
      {...rate, 'kgPerWeek': value},
      server: accepted,
      rule: rule,
      tombstone: !accepted,
    );
  }
}

void _maintain(_Corpus c) {
  const rule = 'Maintain';
  final weekly = _phase(GoalExpressionKind.weekly, type: GoalType.maintain);
  c
    ..add(
      'goalPhase-maintain-weekly-zero',
      'goalPhase',
      {...weekly, 'kgPerWeek': 0.0},
      server: true,
      rule: rule,
      tombstone: true,
    )
    ..writers.add('goalPhase-maintain-weekly-zero')
    ..add(
      'goalPhase-maintain-weekly-negative-zero',
      'goalPhase',
      {...weekly, 'kgPerWeek': -0.0},
      server: true,
      rule: rule,
    )
    ..add(
      'goalPhase-maintain-weekly-0.1',
      'goalPhase',
      {...weekly, 'kgPerWeek': 0.1},
      server: false,
      rule: rule,
      tombstone: true,
    )
    ..add(
      'goalPhase-maintain-monthly',
      'goalPhase',
      {
        ..._phase(GoalExpressionKind.monthly, type: GoalType.maintain),
        'monthKg': 0.0,
      },
      server: false,
      rule: rule,
      tombstone: true,
    )
    ..add(
      'goalPhase-maintain-targetDate',
      'goalPhase',
      _phase(GoalExpressionKind.targetDate, type: GoalType.maintain),
      server: false,
      rule: rule,
      tombstone: true,
    );
}

void _phaseDates(_Corpus c) {
  const rule = 'Phase dates';
  final base = _phase(GoalExpressionKind.weekly);
  for (final (name, end, accepted) in [
    ('end-null', null, true),
    ('end-equals-start', '2026-10-28', true),
    ('end-after-start', '2026-12-31', true),
    ('end-before-start', '2026-10-27', false),
    ('end-year-before-start', '2025-10-28', false),
  ]) {
    c.add(
      'goalPhase-dates-$name',
      'goalPhase',
      {...base, 'endDate': end},
      server: accepted,
      rule: rule,
      tombstone: !accepted,
    );
  }
}

void _macroPairs(_Corpus c) {
  const rule = 'Macro pairs';
  final base = _settings();
  for (final macro in TargetWireFields.macros) {
    final value = '${macro}Value';
    final flag = '${macro}IsPercent';
    final prefix = 'targetSettings-$macro';
    for (final (name, v, f, accepted) in <(String, Object?, bool?, bool)>[
      ('both-null', null, null, true),
      ('value-only', 30.0, null, false),
      ('flag-only-percent', null, true, false),
      ('flag-only-grams', null, false, false),
      ('percent-0', 0.0, true, true),
      ('percent-100', 100.0, true, true),
      ('percent-100.000001', 100.000001, true, false),
      ('percent-101', 101.0, true, false),
      ('grams-5000', 5000.0, false, true),
    ]) {
      c.add(
        '$prefix-$name',
        'targetSettings',
        {...base, value: v, flag: f},
        server: accepted,
        rule: rule,
        tombstone: !accepted,
      );
    }
    // A double reads 100.0000000000000001 as 100.0; the server's decimal
    // compare rejects it (PA5).
    c.add(
      '$prefix-percent-100.0000000000000001',
      'targetSettings',
      {...base, value: c.raw('100.0000000000000001'), flag: true},
      server: false,
      rule: rule,
      asymmetry: 'decimalPrecision',
    );
  }
}

void _acknowledgement(_Corpus c) {
  const rule = 'Acknowledgement';
  for (final manual in [false, true]) {
    for (final acknowledged in [false, true]) {
      final accepted = manual || !acknowledged;
      c.add(
        'targetSettings-manual-$manual-acknowledged-$acknowledged',
        'targetSettings',
        _settings(manual: manual, acknowledged: acknowledged),
        server: accepted,
        rule: rule,
        tombstone: !accepted,
      );
    }
  }
}

void _rowIds(_Corpus c) {
  const rule = 'Row IDs';
  const v4 = '3b241101-e2bb-4255-8caf-4136c566a962';
  const nil = '00000000-0000-0000-0000-000000000000';
  const v7 = '0199e3c2-5b1a-7c3d-8e4f-0123456789ae';
  for (final (name, id, accepted) in [
    ('natural', bodyTargetsProfileRowId, true),
    ('natural-uppercase', bodyTargetsProfileRowId.toUpperCase(), true),
    ('v4', v4, false),
    ('other-natural', bodyTargetsOtherProfileId, false),
    ('nil', nil, false),
    ('v7', v7, false),
  ]) {
    c.add(
      'profile-rowId-$name',
      'profile',
      _profile(),
      rowId: id,
      server: accepted,
      rule: rule,
      asymmetry: accepted ? null : 'rowId',
      tombstone: !accepted,
    );
  }
  for (final (entity, base) in [
    ('goalPhase', _phase(GoalExpressionKind.weekly)),
    ('targetSettings', _settings()),
  ]) {
    for (final (name, id, accepted) in [
      ('v7', v7, true),
      ('v7-variant-b', '0199e3c2-5b1a-7c3d-bf4f-0123456789ae', true),
      ('v7-uppercase', v7.toUpperCase(), true),
      ('v4', v4, false),
      ('v5', bodyTargetsOtherProfileId, false),
      ('nil', nil, false),
      // A version-7 nibble without the RFC variant (PA3).
      ('v7-variant-c', '0199e3c2-5b1a-7c3d-cf4f-0123456789ae', false),
      ('v7-variant-0', '0199e3c2-5b1a-7c3d-0f4f-0123456789ae', false),
    ]) {
      c.add(
        '$entity-rowId-$name',
        entity,
        base,
        rowId: id,
        server: accepted,
        rule: rule,
        asymmetry: accepted ? null : 'rowId',
        tombstone: !accepted,
      );
    }
  }
}

/// App-only plausibility (A13 D15) is never a wire rule: every case here is
/// accepted. `range` cases break a `TargetRules.input` range; `convention`
/// cases break an app convention the server doesn't check.
void _plausibility(_Corpus c) {
  final profile = _profile();
  final weekly = _phase(GoalExpressionKind.weekly);
  final settings = _settings();
  for (final (name, entity, payload)
      in <(String, String, Map<String, Object?>)>[
        ('range-age-150', 'profile', {...profile, 'birthYear': 1876}),
        ('range-age-negative', 'profile', {...profile, 'birthYear': 2100}),
        ('range-height-30', 'profile', {...profile, 'heightCm': 30.0}),
        (
          'range-target-600',
          'goalPhase',
          {..._phase(GoalExpressionKind.targetDate), 'targetKg': 600.0},
        ),
        (
          'range-target-date-past',
          'goalPhase',
          {
            ..._phase(GoalExpressionKind.targetDate),
            'targetDate': '2000-01-01',
          },
        ),
        ('range-weekly-5', 'goalPhase', {...weekly, 'kgPerWeek': -5.0}),
        (
          'range-monthly-20',
          'goalPhase',
          {..._phase(GoalExpressionKind.monthly), 'monthKg': -20.0},
        ),
        ('range-name-41', 'goalPhase', {...weekly, 'name': 'x' * 41}),
        ('range-name-blank', 'goalPhase', {...weekly, 'name': '   '}),
        (
          'range-name-controls',
          'goalPhase',
          {...weekly, 'name': 'Goal\u0007\t'},
        ),
        (
          'range-manual-kcal-50',
          'targetSettings',
          {...settings, 'manual': true, 'baseKcal': 50.0},
        ),
        (
          'range-basis-weight-5',
          'targetSettings',
          {...settings, 'basisWeightKg': 5.0},
        ),
        ('range-shift-5', 'targetSettings', {...settings, 'shiftMon': 5.0}),
        (
          'range-protein-grams-5000',
          'targetSettings',
          {...settings, 'proteinValue': 5000.0},
        ),
        ('range-fiber-900', 'targetSettings', {...settings, 'fiberG': 900.0}),
        ('convention-lose-gaining', 'goalPhase', {...weekly, 'kgPerWeek': 0.5}),
        (
          'convention-month-mid',
          'goalPhase',
          {..._phase(GoalExpressionKind.monthly), 'month': '2026-11-15'},
        ),
        ('range-shift-0', 'targetSettings', {...settings, 'shiftTue': 0.0}),
      ]) {
    c.add('plausibility-$name', entity, payload, server: true);
  }
}

void _targetsSchema(_Corpus c) {
  final profile = _profile();
  final phase = _phase(GoalExpressionKind.weekly);
  final settings = _settings();
  final bases = {
    'profile': profile,
    'goalPhase': phase,
    'targetSettings': settings,
  };
  // Every closed vocabulary: unknown and wrong case.
  for (final (entity, field, unknown, cased) in [
    ('profile', 'sex', 'other', 'Female'),
    ('profile', 'heightInputUnit', 'in', 'CM'),
    ('profile', 'activity', 'extreme', 'Light'),
    ('goalPhase', 'goalType', 'recomp', 'Lose'),
    ('goalPhase', 'expressionKind', 'deadline', 'Weekly'),
    ('goalPhase', 'weightInputUnit', 'st', 'KG'),
    ('targetSettings', 'mode', 'daily', 'Weekly'),
  ]) {
    for (final (name, value) in [
      ('unknown', unknown),
      ('case', cased),
      ('empty', ''),
    ]) {
      c.add('$entity-$field-$name', entity, {
        ...bases[entity]!,
        field: value,
      }, server: false);
    }
  }
  // Name length in UTF-16 units; 🍎 is a surrogate pair (2 units).
  for (final (name, text, accepted) in [
    ('ascii-120', 'x' * 120, true),
    ('ascii-121', 'x' * 121, false),
    ('supplementary-120', '${'x' * 118}\u{1f34e}', true),
    ('supplementary-121', '${'x' * 119}\u{1f34e}', false),
    ('null', null, true),
    ('empty', '', true),
  ]) {
    c.add('goalPhase-name-$name', 'goalPhase', {
      ...phase,
      'name': text,
    }, server: accepted);
  }
  // Dates: `YYYY-MM-DD`, ASCII digits, real days in years 1–9999.
  for (final (name, text, accepted) in [
    ('leap-2028-02-29', '2028-02-29', true),
    ('2026-02-29', '2026-02-29', false),
    ('0000-01-01', '0000-01-01', false),
    ('0001-01-01', '0001-01-01', true),
    ('9999-12-31', '9999-12-31', true),
    ('2026-13-01', '2026-13-01', false),
    ('2026-10-32', '2026-10-32', false),
    ('arabic-indic-digits', '٢٠٢٦-١٠-٢٨', false),
    ('short-month', '2026-1-28', false),
    ('short-year', '226-10-28', false),
    ('padded-day', '2026-10-028', false),
    ('slashes', '2026/10/28', false),
    ('space', ' 2026-10-2', false),
    ('empty', '', false),
  ]) {
    for (final (entity, field) in [
      ('goalPhase', 'startDate'),
      ('targetSettings', 'effectiveFrom'),
    ]) {
      c.add('$entity-$field-$name', entity, {
        ...bases[entity]!,
        field: text,
      }, server: accepted);
    }
  }
  // Integers: ranges, and a whole-number double (the A34 decoding note).
  const max = TargetWireRules.maxRevision;
  for (final (name, value, accepted, tag) in <(String, Object, bool, String?)>[
    ('0', 0, false, null),
    ('1', 1, true, null),
    ('max', max, true, null),
    ('max-plus-1', max + 1, false, null),
    ('2.0', c.raw('2.0'), true, 'wholeNumberInteger'),
    ('2.5', 2.5, false, null),
  ]) {
    for (final entity in ['goalPhase', 'targetSettings']) {
      c.add(
        '$entity-revision-$name',
        entity,
        {...bases[entity]!, 'revision': value},
        server: accepted,
        asymmetry: tag,
        // The app row's integer column truncates; A34 converts whole `num`s.
        app: tag != null || name == '2.5' ? true : null,
      );
    }
  }
  for (final (name, value, accepted, tag) in <(String, Object, bool, String?)>[
    ('0', 0, false, null),
    ('1', 1, true, null),
    ('9999', 9999, true, null),
    ('10000', 10000, false, null),
    ('1990.0', c.raw('1990.0'), true, 'wholeNumberInteger'),
    ('1990.5', 1990.5, false, null),
  ]) {
    c.add(
      'profile-birthYear-$name',
      'profile',
      {...profile, 'birthYear': value},
      server: accepted,
      asymmetry: tag,
      app: tag != null || name == '1990.5' ? true : null,
    );
  }
  // Technical bounds of numbers (0 … 1e6, signed fields −1e6 … 1e6).
  for (final (name, entity, field, value, accepted) in [
    ('heightCm-max', 'profile', 'heightCm', 1000000.0, true),
    ('heightCm-over-max', 'profile', 'heightCm', 1000000.5, false),
    ('kgPerWeek-min', 'goalPhase', 'kgPerWeek', -1000000.0, true),
    ('kgPerWeek-under-min', 'goalPhase', 'kgPerWeek', -1000000.5, false),
    ('fiberG-zero', 'targetSettings', 'fiberG', 0.0, true),
    ('fiberG-negative', 'targetSettings', 'fiberG', -1.0, false),
    ('shiftMon-negative', 'targetSettings', 'shiftMon', -1.0, false),
    ('shiftMon-over-max', 'targetSettings', 'shiftMon', 1000001.0, false),
  ]) {
    c.add(
      '$entity-$name',
      entity,
      {...bases[entity]!, field: value},
      server: accepted,
      // `targetSettingsOf` reads a shift weight outside the wire bounds as
      // NULL (1.0) instead of losing the version.
      app: field == 'shiftMon' ? true : null,
    );
  }
  // A double rounds 1000000.00000000001 onto the maximum (PA5).
  c.add(
    'profile-heightCm-max-plus-1e-11',
    'profile',
    {...profile, 'heightCm': c.raw('1000000.00000000001')},
    server: false,
    asymmetry: 'decimalPrecision',
  );
  // Members and types.
  for (final (entity, base) in [
    ('profile', profile),
    ('goalPhase', phase),
    ('targetSettings', settings),
  ]) {
    c
      ..add(
        '$entity-extra-member',
        entity,
        {...base, 'weightKg': 70.0},
        server: false,
        asymmetry: 'schemaOnly',
      )
      ..add(
        '$entity-missing-createdAtMs',
        entity,
        _without(base, 'createdAtMs'),
        server: false,
        asymmetry: 'schemaOnly',
      )
      ..add(
        '$entity-origin-number',
        entity,
        {...base, 'origin': 5},
        server: false,
        asymmetry: 'schemaOnly',
      )
      ..add(
        '$entity-editedByUser-null',
        entity,
        {...base, 'editedByUser': null},
        server: false,
        asymmetry: 'schemaOnly',
      );
  }
  c
    ..add(
      'profile-missing-activity',
      'profile',
      _without(profile, 'activity'),
      server: false,
    )
    ..add('profile-heightCm-null', 'profile', {
      ...profile,
      'heightCm': null,
    }, server: false)
    ..add('profile-heightCm-string', 'profile', {
      ...profile,
      'heightCm': '165',
    }, server: false)
    ..add(
      'goalPhase-missing-name',
      'goalPhase',
      _without(phase, 'name'),
      server: false,
      asymmetry: 'schemaOnly',
    )
    ..add(
      'goalPhase-missing-endDate',
      'goalPhase',
      _without(phase, 'endDate'),
      server: false,
      asymmetry: 'schemaOnly',
    )
    ..add(
      'goalPhase-name-number',
      'goalPhase',
      {...phase, 'name': 5},
      server: false,
      // The row's text column reads any value as text.
      app: true,
    )
    ..add(
      'targetSettings-missing-shiftSun',
      'targetSettings',
      _without(settings, 'shiftSun'),
      server: false,
      asymmetry: 'schemaOnly',
    )
    ..add(
      'targetSettings-manual-string',
      'targetSettings',
      {...settings, 'manual': 'true'},
      server: false,
      // The row's boolean column reads any non-zero value as true.
      app: true,
    )
    ..add('targetSettings-rebalancing-null', 'targetSettings', {
      ...settings,
      'rebalancing': null,
    }, server: false);
}

void _numbersAndGeneric(_Corpus c) {
  final profile = _profile();
  final phase = _phase(GoalExpressionKind.weekly);
  final settings = _settings();
  for (final (name, text) in [
    ('nan-quoted', '"NaN"'),
    ('infinity-quoted', '"Infinity"'),
    ('1e400', '1e400'),
  ]) {
    c.add('profile-heightCm-$name', 'profile', {
      ...profile,
      'heightCm': c.raw(text),
    }, server: false);
  }
  c
    ..add('goalPhase-kgPerWeek-minus-1e400', 'goalPhase', {
      ...phase,
      'kgPerWeek': c.raw('-1e400'),
    }, server: false)
    // Dart reads 1e-400 as 0.0; decimal can't hold it exactly.
    ..add(
      'targetSettings-fiberG-1e-400',
      'targetSettings',
      {...settings, 'fiberG': c.raw('1e-400')},
      server: false,
      asymmetry: 'generic',
    )
    ..add(
      'targetSettings-basisWeightKg-31-digits',
      'targetSettings',
      {...settings, 'basisWeightKg': c.raw('82.40000000000000000000000000001')},
      server: false,
      asymmetry: 'generic',
    )
    ..add(
      'goalPhase-name-lone-high-surrogate',
      'goalPhase',
      {...phase, 'name': c.raw(r'"x\ud800"')},
      server: false,
      asymmetry: 'generic',
    )
    ..add(
      'goalPhase-name-lone-low-surrogate',
      'goalPhase',
      {...phase, 'name': c.raw(r'"\udc00x"')},
      server: false,
      asymmetry: 'generic',
    )
    ..add(
      'goalPhase-name-nul',
      'goalPhase',
      {...phase, 'name': 'x\u0000'},
      server: false,
      asymmetry: 'generic',
    );
  final raw = c.encode(profile);
  c.add(
    'profile-duplicate-key',
    'profile',
    profile,
    rawPayload: raw.replaceFirst('"heightCm":', '"heightCm":170.0,"heightCm":'),
    server: false,
    asymmetry: 'generic',
  );
}

void _weighIn(_Corpus c) {
  final v2 = _weighIn2Base;
  final v1 = _weighIn1Base;
  void two(
    String id,
    Map<String, Object?> payload, {
    required bool server,
    bool? app,
    String? asymmetry,
    bool deleted = false,
  }) => c.add(
    'weighIn2-$id',
    'weighIn',
    payload,
    schemaVersion: 2,
    server: server,
    app: app,
    asymmetry: asymmetry,
    deleted: deleted,
  );
  void one(String id, Map<String, Object?> payload, {required bool server}) =>
      c.add('weighIn1-$id', 'weighIn', payload, server: server);

  for (final (name, value, accepted, app, tag)
      in <(String, Object, bool, bool?, String?)>[
        ('tz-min', minTzOffsetMinutes, true, null, null),
        ('tz-max', maxTzOffsetMinutes, true, null, null),
        ('tz-zero', 0, true, null, null),
        ('tz-under-min', minTzOffsetMinutes - 1, false, null, null),
        ('tz-over-max', maxTzOffsetMinutes + 1, false, null, null),
        // The row's integer column truncates 60.5 and parses "60".
        ('tz-60.5', 60.5, false, true, null),
        ('tz-string', '60', false, true, null),
        ('tz-60.0', c.raw('60.0'), true, null, 'wholeNumberInteger'),
      ]) {
    two(
      name,
      {...v2, 'tzOffsetMin': value},
      server: accepted,
      app: app,
      asymmetry: tag,
    );
  }
  for (final (name, value, accepted) in <(String, Object?, bool)>[
    ('unit-kg', 'kg', true),
    ('unit-lb', 'lb', true),
    ('unit-upper-kg', 'KG', false),
    ('unit-st', 'st', false),
    ('unit-empty', '', false),
    ('unit-null', null, false),
  ]) {
    two(name, {...v2, 'inputUnit': value}, server: accepted);
  }
  // The app reads only kg (and typed values) in (0, 1e6] (A14 D6), so a
  // server-valid 0 or 1e12 is skipped on read.
  for (final (name, value, accepted, app) in <(String, Object, bool, bool?)>[
    ('input-zero', 0.0, true, false),
    ('input-negative', -0.1, false, null),
    ('input-max', c.raw('1000000000000.0'), true, false),
    ('input-over-max', c.raw('1000000000001.0'), false, null),
  ]) {
    two(name, {...v2, 'inputValue': value}, server: accepted, app: app);
  }
  for (final (name, value, accepted, app) in <(String, Object, bool, bool?)>[
    ('kg-zero', 0.0, true, false),
    ('kg-negative', -0.1, false, null),
  ]) {
    two(name, {...v2, 'kg': value}, server: accepted, app: app);
  }
  two('preferred-true', {...v2, 'preferredForDay': true}, server: true);
  // The row's boolean column reads any non-zero value as true.
  two(
    'preferred-string',
    {...v2, 'preferredForDay': 'true'},
    server: false,
    app: true,
  );
  two('preferred-null', {...v2, 'preferredForDay': null}, server: false);
  for (final field in _weighInV2Only) {
    two('missing-$field', _without(v2, field), server: false);
  }
  two(
    'extra-member',
    {...v2, 'bodyFatPct': 20.0},
    server: false,
    app: true,
    asymmetry: 'schemaOnly',
  );
  two('v1-payload', v1, server: false);
  one('v2-payload', v2, server: false);
  one('kg-zero', {...v1, 'kg': 0.0}, server: true);
  one('tz-member', {...v1, 'tzOffsetMin': 180}, server: false);
  // Note: at most 4096 UTF-16 units; the app doesn't re-check on read.
  for (final (name, text, accepted) in [
    ('ascii-4096', 'x' * 4096, true),
    ('ascii-4097', 'x' * 4097, false),
    ('supplementary-4097', '${'x' * 4095}\u{1f34e}', false),
  ]) {
    two('note-$name', {...v2, 'note': text}, server: accepted, app: true);
  }
  two('note-arabic', {...v2, 'note': 'بعد العيد'}, server: true);
  two(
    'note-lone-surrogate',
    {...v2, 'note': c.raw(r'"x\ud800"')},
    server: false,
    app: true,
    asymmetry: 'generic',
  );
  two(
    'note-nul',
    {...v2, 'note': 'x\u0000'},
    server: false,
    app: true,
    asymmetry: 'generic',
  );
  for (final (name, text, accepted) in [
    ('2026-02-29', '2026-02-29', false),
    ('0000-01-01', '0000-01-01', false),
    ('9999-12-31', '9999-12-31', true),
    ('arabic-indic-digits', '٢٠٢٦-١٠-٢٨', false),
    ('short-month', '2026-1-28', false),
  ]) {
    two('localDate-$name', {...v2, 'localDate': text}, server: accepted);
  }
  // The read model takes any stored instant; the wire's minimum is 0.
  two(
    'measuredAtUtc-negative',
    {...v2, 'measuredAtUtc': -1},
    server: false,
    app: true,
  );
  // A scrubbed tombstone (B19 D11): kg and inputValue 0, note null.
  two(
    'tombstone-scrubbed',
    {...v2, 'kg': 0.0, 'inputValue': 0.0, 'note': null},
    server: true,
    app: false,
    deleted: true,
  );
  two(
    'tombstone-full',
    {...v2, 'note': 'Synthetic note'},
    server: true,
    deleted: true,
  );
}

/// Stable JSON bytes shared by the Dart and C# tests.
String generateBodyTargetsVectors() =>
    '${const JsonEncoder.withIndent('  ').convert(bodyTargetsVectors())}\n';

/// Writes only the corpus; the drift test calls the in-memory function.
void main() {
  File.fromUri(
    Platform.script.resolve(
      '../../../contracts/testdata/sync/body-targets-validation-vectors.json',
    ),
  ).writeAsStringSync(generateBodyTargetsVectors());
}
