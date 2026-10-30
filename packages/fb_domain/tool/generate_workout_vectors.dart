import 'dart:convert';
import 'dart:io';

import 'package:fb_domain/fb_domain.dart';

/// The parent and reference IDs the bases point at (UUIDv7s, as the app
/// mints). The app test inserts a live session [workoutVectorsSessionId]
/// with the session exercise [workoutVectorsSessionExerciseId], and a live
/// template [workoutVectorsTemplateId], before a child case.
const String workoutVectorsTemplateId = '0199e3c2-5b1a-7c3d-8e4f-0123456789c1';

/// See [workoutVectorsTemplateId].
const String workoutVectorsSessionId = '0199e3c2-5b1a-7c3d-8e4f-0123456789c2';

/// See [workoutVectorsTemplateId].
const String workoutVectorsSessionExerciseId =
    '0199e3c2-5b1a-7c3d-8e4f-0123456789c3';

/// A custom exercise's ID used as an `exerciseId` (W4's UUID form).
const String workoutVectorsCustomExerciseId =
    '0199e3c2-5b1a-7c3d-8e4f-0123456789c4';

/// The row IDs the app test uses when a case has no `rowId`. Every
/// `weeklyPlanDay` case carries its `rowId` (W5); the other entities have
/// no row-ID rule, so the C# side mints its own.
const Map<String, String> workoutDefaultRowIds = {
  'customExercise': '0199e3c2-5b1a-7c3d-8e4f-0123456789d1',
  'workoutSession': workoutVectorsSessionId,
  'sessionExercise': workoutVectorsSessionExerciseId,
  'workoutSet': '0199e3c2-5b1a-7c3d-8e4f-0123456789d4',
  'workoutTemplate': workoutVectorsTemplateId,
  'workoutTemplateItem': '0199e3c2-5b1a-7c3d-8e4f-0123456789d6',
};

/// The seven entities, in contract order.
const List<String> workoutEntities = [
  'customExercise',
  'workoutSession',
  'sessionExercise',
  'workoutSet',
  'workoutTemplate',
  'workoutTemplateItem',
  'weeklyPlanDay',
];

/// The README's wire-rule bullet labels (`contracts/README.md` § "Workout
/// semantic rules"), keyed by rule ID. A case's `rule` is the label.
const Map<String, String> workoutRules = {
  'W1': 'W1 muscles',
  'W2': 'W2 aliases shape',
  'W3': 'W3 set shape',
  'W4': 'W4 exercise reference',
  'W5': 'W5 plan-day row ID',
};

/// Why a case's `serverAccepts` may differ from `appWire` (B21 D7). Closed:
/// a new tag is a plan change.
/// - `schemaOnly`: metadata, extra or missing members, bounds, formats,
///   lengths, enums W1–W5 don't read (server rejects, wire-valid);
/// - `generic`: the server's representability pass (unpaired surrogate,
///   U+0000, duplicate key, a number decimal can't hold) (server rejects,
///   wire-valid);
/// - `wholeNumberInteger`: `6.0` for an integer field, which the server
///   accepts and Dart decodes as a double (server accepts, wire-invalid).
const Set<String> workoutAsymmetries = {
  'schemaOnly',
  'generic',
  'wholeNumberInteger',
};

/// 2^53 − 1, the wire maximum of integers (`createdAtMs`, `position`, …).
const int workoutMaxInteger = 9007199254740991;

/// The wire maximum of numbers (`kg`, `inputValue`, `distanceMeters`).
const int workoutMaxNumber = 1000000000000;

/// The wire maximum of a name, in UTF-16 units (the app's own limit is 80
/// code points, so every app write fits).
const int workoutMaxNameLength = 160;

/// The wire maximum of `origin`, in UTF-16 units.
const int workoutMaxOriginLength = 128;

const Object _undecodable = Object();

Object? _decodeNested(Object? text) {
  if (text is! String) return _undecodable;
  try {
    return jsonDecode(text);
  } on FormatException {
    return _undecodable;
  }
}

/// `WorkoutWireRules` on the decoded [payload] of [entity] (B21 D7), with
/// [rowId] for W5. False when the content doesn't decode to the declared
/// Dart types (a missing member reads as null, as the table row does); for
/// `workoutSession` and `workoutTemplate`, which have no rules, that is the
/// whole check. Metadata isn't read (A34 maps it).
bool workoutWireValid(
  String entity,
  Map<String, Object?> payload, {
  String? rowId,
}) {
  bool text(String k, {bool nullable = false}) =>
      payload[k] is String || (nullable && payload[k] == null);
  bool integer(String k, {bool nullable = false}) =>
      payload[k] is int || (nullable && payload[k] == null);
  bool number(String k, {bool nullable = false}) =>
      payload[k] is num || (nullable && payload[k] == null);
  switch (entity) {
    case 'customExercise':
      return text('name') &&
          text('aliasesJson') &&
          text('exerciseType') &&
          text('equipment') &&
          text('primaryMuscle', nullable: true) &&
          text('secondaryMusclesJson') &&
          WorkoutWireRules.musclesHold(
            payload['primaryMuscle'] as String?,
            _decodeNested(payload['secondaryMusclesJson']),
          ) &&
          WorkoutWireRules.aliasesHold(_decodeNested(payload['aliasesJson']));
    case 'workoutSession':
      return text('localDate') &&
          text('name', nullable: true) &&
          integer('startMinute', nullable: true) &&
          integer('durationMinutes', nullable: true) &&
          text('templateId', nullable: true);
    case 'sessionExercise':
      return text('sessionId') &&
          text('exerciseId') &&
          integer('position') &&
          WorkoutWireRules.isExerciseRef(payload['exerciseId']! as String);
    case 'workoutSet':
      if (!(text('sessionExerciseId') &&
          integer('position') &&
          integer('reps', nullable: true) &&
          number('kg', nullable: true) &&
          number('inputValue', nullable: true) &&
          text('inputUnit', nullable: true) &&
          integer('durationSeconds', nullable: true) &&
          number('distanceMeters', nullable: true))) {
        return false;
      }
      return WorkoutWireRules.setShapeHolds(
        reps: payload['reps'] as int?,
        kg: (payload['kg'] as num?)?.toDouble(),
        inputValue: (payload['inputValue'] as num?)?.toDouble(),
        inputUnit: payload['inputUnit'] as String?,
        durationSeconds: payload['durationSeconds'] as int?,
        distanceMeters: (payload['distanceMeters'] as num?)?.toDouble(),
      );
    case 'workoutTemplate':
      return text('name');
    case 'workoutTemplateItem':
      return text('templateId') &&
          text('exerciseId') &&
          integer('position') &&
          integer('targetSets') &&
          integer('targetReps') &&
          WorkoutWireRules.isExerciseRef(payload['exerciseId']! as String);
    case 'weeklyPlanDay':
      return integer('weekday') &&
          text('templateId', nullable: true) &&
          WorkoutWireRules.planDayIdHolds(
            rowId ?? '',
            payload['weekday']! as int,
          );
  }
  throw ArgumentError.value(entity, 'entity');
}

/// B21 synthetic corpus for the seven workout sync entities (v1)
/// (`contracts/testdata/README.md`). `serverAccepts` and `appReads` are
/// declarations: C# checks the first against `SyncPayloads`, the app test
/// checks the second through the real tables and `WorkoutRepository`.
/// `appWire` is computed here with the real `WorkoutWireRules`.
Map<String, Object?> workoutVectors() {
  final c = _Corpus();
  _bases(c);
  _w1(c);
  _w2(c);
  _w3(c);
  _w4(c);
  _w5(c);
  _notWireRules(c);
  _schema(c);
  _members(c);
  _generic(c);
  _tombstones(c);
  final payloads = c.payloads;
  return {
    'version': 1,
    'constants': {
      'maxSecondaries': Muscle.secondariesMax,
      'maxAliases': WorkoutLimits.aliasesMax,
      'maxCatalogIdLength': WorkoutWireRules.maxCatalogIdLength,
      'maxNameLength': workoutMaxNameLength,
      'maxNumber': workoutMaxNumber,
      'maxInteger': workoutMaxInteger,
      'maxOriginLength': workoutMaxOriginLength,
      'planDayIds': WorkoutWireRules.planDayIds,
    },
    'vocabularies': {
      'exerciseType': [for (final v in ExerciseType.values) v.code],
      'equipment': [for (final v in Equipment.values) v.code],
      'muscle': [for (final v in Muscle.values) v.code],
      'inputUnit': [MassUnit.kilogram.code, MassUnit.pound.code],
    },
    'rules': [
      for (final MapEntry(:key, :value) in workoutRules.entries)
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

  /// A JSON value written as [text] exactly (an escaped surrogate, a number
  /// Dart can't encode the same way).
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
  /// `<id>-tombstone` (same outcome, B21 D5). [app] defaults to [server].
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
        'appWire': workoutWireValid(entity, decoded, rowId: rowId),
        'appReads': app ?? server,
      });
    }
  }

  void writer(String entity, String payloadId) => writers.add({
    'id': 'writer-$payloadId',
    'entity': entity,
    'payloadId': payloadId,
  });
}

const Map<String, Object?> _meta = {
  'createdAtMs': 0,
  'origin': 'synthetic',
  'editedByUser': false,
};

/// A payload from [draft]'s getters, in contract order.
Map<String, Object?> _customExercise(CustomExerciseDraft draft) => {
  ..._meta,
  'name': draft.name,
  'aliasesJson': jsonEncode(draft.aliases),
  'exerciseType': draft.type.code,
  'equipment': draft.equipment.code,
  'primaryMuscle': draft.primaryMuscle?.code,
  'secondaryMusclesJson': jsonEncode([
    for (final m in draft.secondaryMuscles) m.code,
  ]),
};

Map<String, Object?> _session(WorkoutSessionDraft draft) => {
  ..._meta,
  'localDate': '${draft.date}',
  'name': draft.name,
  'startMinute': draft.startTime?.minuteOfDay,
  'durationMinutes': draft.durationMinutes,
  'templateId': draft.templateId,
};

Map<String, Object?> _sessionExercise(SessionExerciseDraft exercise) => {
  ..._meta,
  'sessionId': workoutVectorsSessionId,
  'exerciseId': exercise.exerciseId,
  'position': 0,
};

/// A set row as the app writes it: a weight typed in kg stores its kg as
/// the typed value (TD-017).
Map<String, Object?> _set(LoggedSet set) {
  final kg = set.values.kg;
  return {
    ..._meta,
    'sessionExerciseId': workoutVectorsSessionExerciseId,
    'position': 0,
    'reps': set.values.reps,
    'kg': kg,
    'inputValue': kg == null ? null : set.inputValue ?? kg,
    'inputUnit': kg == null ? null : set.inputUnit.code,
    'durationSeconds': set.values.durationSeconds,
    'distanceMeters': set.values.distanceMeters,
  };
}

Map<String, Object?> _template(WorkoutTemplateDraft draft) => {
  ..._meta,
  'name': draft.name,
};

Map<String, Object?> _item(TemplateItemDraft item) => {
  ..._meta,
  'templateId': workoutVectorsTemplateId,
  'exerciseId': item.exerciseId,
  'position': 0,
  'targetSets': item.sets,
  'targetReps': item.reps,
};

Map<String, Object?> _planDay(DayOfWeek day, String? templateId) => {
  ..._meta,
  'weekday': day.isoNumber,
  'templateId': templateId,
};

String _dayId(int weekday) => WorkoutWireRules.planDayIds[weekday - 1];

const String _setId = '0199e3c2-5b1a-7c3d-8e4f-0123456789d4';
const String _itemId = '0199e3c2-5b1a-7c3d-8e4f-0123456789d6';

/// The main custom exercise (the fixture's content).
final Map<String, Object?> _exercise = _customExercise(
  CustomExerciseDraft(
    name: 'Incline dumbbell press',
    type: ExerciseType.weightReps,
    equipment: Equipment.dumbbell,
    aliases: const ['incline db press'],
    primaryMuscle: Muscle.chest,
    secondaryMuscles: const [Muscle.shoulders, Muscle.triceps],
  ),
);

final Map<String, Object?> _sessionBare = _session(
  WorkoutSessionDraft(date: LocalDate(2026, 10, 28), exercises: const []),
);

final Map<String, Object?> _sessionFull = _session(
  WorkoutSessionDraft(
    date: LocalDate(2026, 10, 28),
    exercises: const [],
    name: 'Push',
    startTime: LocalTime.ofMinuteOfDay(1080),
    durationMinutes: 55,
    templateId: workoutVectorsTemplateId,
  ),
);

final Map<String, Object?> _sessionExerciseCatalog = _sessionExercise(
  SessionExerciseDraft(
    id: workoutVectorsSessionExerciseId,
    exerciseId: 'ex:bench_press',
    sets: const [],
  ),
);

final Map<String, Object?> _sessionExerciseCustom = _sessionExercise(
  SessionExerciseDraft(
    id: workoutVectorsSessionExerciseId,
    exerciseId: workoutVectorsCustomExerciseId,
    sets: const [],
  ),
);

Map<String, Object?> _setOf(
  SetValues values, {
  double? inputValue,
  MassUnit unit = MassUnit.kilogram,
}) => _set(LoggedSet(_setId, values, inputValue: inputValue, inputUnit: unit));

/// One set per type shape (WO-004), by name.
final Map<String, Map<String, Object?>> _sets = {
  'weight-kg': _setOf(const SetValues(reps: 8, kg: 80)),
  'weight-lb': _setOf(
    const SetValues(reps: 8, kg: 79.83225712),
    inputValue: 176,
    unit: MassUnit.pound,
  ),
  'bodyweight': _setOf(const SetValues(reps: 12)),
  'bodyweight-added': _setOf(const SetValues(reps: 10, kg: 10)),
  'assisted': _setOf(const SetValues(reps: 8, kg: 25)),
  'reps-only': _setOf(const SetValues(reps: 15)),
  'duration': _setOf(const SetValues(durationSeconds: 60)),
  'cardio': _setOf(const SetValues(durationSeconds: 1800)),
  'cardio-distance': _setOf(
    const SetValues(durationSeconds: 1800, distanceMeters: 5000),
  ),
};

final Map<String, Object?> _setBase = _sets['weight-kg']!;
final Map<String, Object?> _setLb = _sets['weight-lb']!;
final Map<String, Object?> _setReps = _sets['reps-only']!;
final Map<String, Object?> _setDuration = _sets['duration']!;

final Map<String, Object?> _templateBase = _template(
  WorkoutTemplateDraft(name: 'Push', items: const []),
);

final Map<String, Object?> _itemBase = _item(
  TemplateItemDraft(
    id: _itemId,
    exerciseId: 'ex:bench_press',
    sets: 3,
    reps: 8,
  ),
);

Map<String, Object?> _without(Map<String, Object?> payload, String key) =>
    Map.of(payload)..remove(key);

void _bases(_Corpus c) {
  void base(
    String id,
    String entity,
    Map<String, Object?> payload, {
    String? rowId,
  }) {
    c
      ..add(id, entity, payload, server: true, rowId: rowId, tombstone: true)
      ..writer(entity, id);
  }

  base('customExercise-base', 'customExercise', _exercise);
  // Each equipment once, the types in turn, muscles varied.
  for (final (i, equipment) in Equipment.values.indexed) {
    final type = ExerciseType.values[i % ExerciseType.values.length];
    final primary = Muscle.values[(i * 3) % Muscle.values.length];
    base(
      'customExercise-base-${type.code}-${equipment.code}',
      'customExercise',
      _customExercise(
        CustomExerciseDraft(
          name: 'Custom ${equipment.code} ${type.code}',
          type: type,
          equipment: equipment,
          aliases: ['alias $i'],
          primaryMuscle: primary,
          secondaryMuscles: [Muscle.values[(i * 3 + 1) % Muscle.values.length]],
        ),
      ),
    );
  }
  // From before v11: no primary muscle, no secondaries, no aliases.
  base(
    'customExercise-base-legacy',
    'customExercise',
    _customExercise(
      CustomExerciseDraft(
        name: 'Old row',
        type: ExerciseType.repsOnly,
        equipment: Equipment.other,
      ),
    ),
  );
  base(
    'customExercise-base-four-secondaries',
    'customExercise',
    _customExercise(
      CustomExerciseDraft(
        name: 'Clean and press',
        type: ExerciseType.weightReps,
        equipment: Equipment.barbell,
        primaryMuscle: Muscle.shoulders,
        secondaryMuscles: const [
          Muscle.traps,
          Muscle.triceps,
          Muscle.glutes,
          Muscle.quadriceps,
        ],
      ),
    ),
  );
  base('workoutSession-base-bare', 'workoutSession', _sessionBare);
  base('workoutSession-base-full', 'workoutSession', _sessionFull);
  base(
    'sessionExercise-base-catalog',
    'sessionExercise',
    _sessionExerciseCatalog,
  );
  base(
    'sessionExercise-base-custom',
    'sessionExercise',
    _sessionExerciseCustom,
  );
  for (final MapEntry(:key, :value) in _sets.entries) {
    base('workoutSet-base-$key', 'workoutSet', value);
  }
  base('workoutTemplate-base', 'workoutTemplate', _templateBase);
  base('workoutTemplateItem-base', 'workoutTemplateItem', _itemBase);
  // Every weekday: rest on Tuesday, Thursday and Sunday.
  for (final day in DayOfWeek.values) {
    final rest = day.isoNumber.isEven || day.isoNumber == 7;
    base(
      'weeklyPlanDay-base-${day.isoNumber}',
      'weeklyPlanDay',
      _planDay(day, rest ? null : workoutVectorsTemplateId),
      rowId: _dayId(day.isoNumber),
    );
  }
}

void _w1(_Corpus c) {
  final rule = workoutRules['W1'];
  // The app reads secondaries tolerantly (unknown, repeated and the primary
  // dropped, at most 4), so it keeps every W1 rejection it can store.
  void muscles(
    String id,
    String json, {
    required bool server,
    String? primary,
  }) => c.add(
    'customExercise-W1-$id',
    'customExercise',
    {..._exercise, 'primaryMuscle': ?primary, 'secondaryMusclesJson': json},
    server: server,
    rule: rule,
    app: true,
    tombstone: !server,
  );

  muscles(
    'five',
    '["shoulders","triceps","biceps","forearms","abs"]',
    server: false,
  );
  muscles('duplicate', '["shoulders","shoulders"]', server: false);
  muscles('primary-repeated', '["chest"]', server: false);
  muscles('unknown', '["wrist"]', server: false);
  for (final legacy in ['back', 'core', 'full_body']) {
    muscles('legacy-$legacy', '["$legacy"]', server: false);
  }
  muscles('wrong-case', '["Chest"]', server: false, primary: 'triceps');
  muscles('padded', '[" shoulders"]', server: false);
  for (final (name, json) in [
    ('object', '{}'),
    ('string', '"shoulders"'),
    ('null', 'null'),
    ('number', '1'),
    ('number-item', '[1]'),
    ('null-item', '[null]'),
    ('array-item', '[[]]'),
    ('not-json', '[shoulders'),
  ]) {
    muscles('root-$name', json, server: false);
  }
  muscles('escaped', r'["\u0073houlders"]', server: true);
  muscles('whitespace', ' [ "shoulders" ,\n "triceps" ] ', server: true);
  muscles('empty', '[]', server: true);
  c.add(
    'customExercise-W1-no-primary-four',
    'customExercise',
    {
      ..._exercise,
      'primaryMuscle': null,
      'secondaryMusclesJson': '["chest","shoulders","triceps","forearms"]',
    },
    server: true,
    rule: rule,
  );
  // primaryMuscle is the schema's enum: W1 doesn't read its code.
  for (final code in ['wrist', 'back', 'Chest']) {
    c.add(
      'customExercise-primaryMuscle-$code',
      'customExercise',
      {..._exercise, 'primaryMuscle': code},
      server: false,
      asymmetry: 'schemaOnly',
    );
  }
}

void _w2(_Corpus c) {
  final rule = workoutRules['W2'];
  void aliases(String id, String json, {required bool server, bool? app}) =>
      c.add(
        'customExercise-W2-$id',
        'customExercise',
        {..._exercise, 'aliasesJson': json},
        server: server,
        rule: rule,
        app: app,
        tombstone: !server,
      );

  String list(int n) => jsonEncode([for (var i = 0; i < n; i++) 'alias $i']);
  aliases('empty', '[]', server: true);
  aliases('ten', list(10), server: true);
  aliases('eleven', list(11), server: false);
  aliases('object', '{}', server: false);
  aliases('number-item', '["db press",1]', server: false, app: true);
  // Wire-valid; the app's write rule (trimmed, 1–80) hides the row.
  aliases('blank', '["  "]', server: true, app: false);
  aliases('81-code-points', jsonEncode(['a' * 81]), server: true, app: false);
}

void _w3(_Corpus c) {
  final rule = workoutRules['W3'];
  // The app reads every stored set (no shape or bound check on read).
  void set(String id, Map<String, Object?> payload, {required bool server}) =>
      c.add(
        'workoutSet-W3-$id',
        'workoutSet',
        payload,
        server: server,
        rule: rule,
        app: true,
        tombstone: !server,
      );

  set('neither-reps-nor-duration', {..._setReps, 'reps': null}, server: false);
  set('reps-and-duration', {..._setReps, 'durationSeconds': 60}, server: false);
  set('kg-with-duration', {
    ..._setDuration,
    'kg': 10,
    'inputValue': 10,
    'inputUnit': 'kg',
  }, server: false);
  set('distance-with-reps', {
    ..._setReps,
    'distanceMeters': 100,
  }, server: false);
  set('kg-without-input', {
    ..._setBase,
    'inputValue': null,
    'inputUnit': null,
  }, server: false);
  set('unit-without-kg', {..._setReps, 'inputUnit': 'kg'}, server: false);
  set('input-without-kg', {..._setReps, 'inputValue': 10}, server: false);
  set('lb-without-kg', {..._setLb, 'kg': null}, server: false);
  // App-only write bounds: inside the wire.
  set('reps-0', {..._setBase, 'reps': 0}, server: true);
  set('reps-1001', {..._setBase, 'reps': 1001}, server: true);
  set('kg-1500', {..._setBase, 'kg': 1500, 'inputValue': 1500}, server: true);
  set('duration-0', {..._setDuration, 'durationSeconds': 0}, server: true);
  set('duration-86401', {
    ..._setDuration,
    'durationSeconds': 86401,
  }, server: true);
  set('distance-0', {
    ..._sets['cardio-distance']!,
    'distanceMeters': 0,
  }, server: true);
  set(
    'reps-with-load-bodyweight-type',
    _sets['bodyweight-added']!,
    server: true,
  );
}

void _w4(_Corpus c) {
  final rule = workoutRules['W4'];
  for (final (entity, base) in [
    ('sessionExercise', _sessionExerciseCatalog),
    ('workoutTemplateItem', _itemBase),
  ]) {
    for (final (name, id, server) in [
      ('catalog', 'ex:bench_press', true),
      ('catalog-60', 'ex:${'a' * 60}', true),
      ('catalog-digits', 'ex:3_4_sit_up', true),
      ('uuid', workoutVectorsCustomExerciseId, true),
      ('prefix-only', 'ex:', false),
      ('catalog-61', 'ex:${'a' * 61}', false),
      ('uppercase-body', 'ex:Bench', false),
      ('hyphen', 'ex:bench-press', false),
      ('uppercase-prefix', 'EX:bench', false),
      ('leading-space', ' ex:bench', false),
      ('trailing-newline', 'ex:bench\n', false),
      ('uuid-uppercase', workoutVectorsCustomExerciseId.toUpperCase(), false),
      (
        'uuid-no-hyphens',
        workoutVectorsCustomExerciseId.replaceAll('-', ''),
        false,
      ),
      ('empty', '', false),
    ]) {
      c.add(
        '$entity-W4-$name',
        entity,
        {...base, 'exerciseId': id},
        server: server,
        rule: rule,
        tombstone: !server && entity == 'sessionExercise',
      );
    }
  }
}

void _w5(_Corpus c) {
  final rule = workoutRules['W5'];
  final wednesday = _planDay(DayOfWeek.wednesday, workoutVectorsTemplateId);
  for (final (name, rowId, server) in [
    ('own-id', _dayId(3), true),
    ('monday-id', _dayId(1), false),
    ('v4', '6a1f3e2d-4c5b-4a69-8f7e-0d1c2b3a4958', false),
    ('v7', '0199e3c2-5b1a-7c3d-8e4f-0123456789e3', false),
  ]) {
    // The app's plan reads the weekday, never the row ID.
    c.add(
      'weeklyPlanDay-W5-$name',
      'weeklyPlanDay',
      wednesday,
      server: server,
      rowId: rowId,
      rule: rule,
      app: true,
      tombstone: !server,
    );
  }
  // weekday is the schema's: 0 and 8 fail the table CHECK too.
  for (final (name, value, app) in [('0', 0, false), ('8', 8, false)]) {
    c.add(
      'weeklyPlanDay-weekday-$name',
      'weeklyPlanDay',
      {...wednesday, 'weekday': value},
      server: false,
      rowId: _dayId(1),
      app: app,
    );
  }
  // SQLite's integer affinity stores "3" as 3.
  c.add(
    'weeklyPlanDay-weekday-string',
    'weeklyPlanDay',
    {...wednesday, 'weekday': '3'},
    server: false,
    rowId: _dayId(3),
    app: true,
  );
  c.add(
    'weeklyPlanDay-weekday-whole-number-double',
    'weeklyPlanDay',
    wednesday,
    rawPayload: c
        .encode(wednesday)
        .replaceFirst('"weekday":3', '"weekday":3.0'),
    server: true,
    rowId: _dayId(3),
    asymmetry: 'wholeNumberInteger',
  );
}

/// Cross-row rules and app-only bounds (B21 D4): all server-accepted. The
/// app hides an orphan child and a plan day without a live template.
void _notWireRules(_Corpus c) {
  const other = '0199e3c2-5b1a-7c3d-8e4f-0123456789ee';
  void add(
    String id,
    String entity,
    Map<String, Object?> payload, {
    required bool app,
    String? rowId,
  }) => c.add(
    'notWire-$id',
    entity,
    payload,
    server: true,
    app: app,
    rowId: rowId,
  );

  add('set-unknown-exercise', 'workoutSet', {
    ..._setBase,
    'sessionExerciseId': other,
  }, app: false);
  add('sessionExercise-unknown-session', 'sessionExercise', {
    ..._sessionExerciseCatalog,
    'sessionId': other,
  }, app: false);
  add('sessionExercise-unknown-custom-exercise', 'sessionExercise', {
    ..._sessionExerciseCatalog,
    'exerciseId': other,
  }, app: true);
  add('item-unknown-template', 'workoutTemplateItem', {
    ..._itemBase,
    'templateId': other,
  }, app: false);
  add('item-unknown-exercise', 'workoutTemplateItem', {
    ..._itemBase,
    'exerciseId': other,
  }, app: true);
  add(
    'planDay-missing-template',
    'weeklyPlanDay',
    {..._planDay(DayOfWeek.friday, other)},
    app: false,
    rowId: _dayId(5),
  );
  add('session-unknown-template', 'workoutSession', {
    ..._sessionFull,
    'templateId': other,
  }, app: true);
  add('session-future-date', 'workoutSession', {
    ..._sessionBare,
    'localDate': '2999-01-01',
  }, app: true);
  add('set-position-gap', 'workoutSet', {
    ..._setBase,
    'position': 7,
  }, app: true);
  add('sessionExercise-position-gap', 'sessionExercise', {
    ..._sessionExerciseCatalog,
    'position': 12,
  }, app: true);
  // App write bounds (the read applies the draft rules, so it hides these).
  add('session-duration-0', 'workoutSession', {
    ..._sessionBare,
    'durationMinutes': 0,
  }, app: false);
  add('session-duration-1441', 'workoutSession', {
    ..._sessionBare,
    'durationMinutes': 1441,
  }, app: false);
  add('item-sets-21', 'workoutTemplateItem', {
    ..._itemBase,
    'targetSets': 21,
  }, app: false);
  add('item-reps-1001', 'workoutTemplateItem', {
    ..._itemBase,
    'targetReps': 1001,
  }, app: false);
  add('exercise-name-blank', 'customExercise', {
    ..._exercise,
    'name': '   ',
  }, app: false);
  add('exercise-name-81', 'customExercise', {
    ..._exercise,
    'name': 'n' * 81,
  }, app: false);
  add('template-name-empty', 'workoutTemplate', {
    ..._templateBase,
    'name': '',
  }, app: false);
  add('session-name-blank', 'workoutSession', {
    ..._sessionBare,
    'name': ' ',
  }, app: false);
  add('exercise-name-arabic', 'customExercise', {
    ..._exercise,
    'name': 'ضغط صدر مائل',
  }, app: true);
  for (final (name, id) in [
    ('v4', '6a1f3e2d-4c5b-4a69-8f7e-0d1c2b3a4958'),
    ('nil', '00000000-0000-0000-0000-000000000000'),
  ]) {
    add('rowId-$name', 'workoutSet', _setBase, app: true, rowId: id);
  }
}

void _schema(_Corpus c) {
  void add(
    String id,
    String entity,
    Map<String, Object?> payload, {
    required bool server,
    bool? app,
    String? rowId,
  }) {
    final decoded = jsonDecode(c.encode(payload)) as Map<String, Object?>;
    final wire = workoutWireValid(entity, decoded, rowId: rowId);
    c.add(
      id,
      entity,
      payload,
      server: server,
      app: app,
      rowId: rowId,
      asymmetry: !server && wire ? 'schemaOnly' : null,
    );
  }

  // Codes outside the closed vocabularies fail the table CHECK too.
  for (final code in ['Weight_reps', 'rpe', '']) {
    add(
      'customExercise-exerciseType-${code.isEmpty ? 'empty' : code}',
      'customExercise',
      {..._exercise, 'exerciseType': code},
      server: false,
    );
  }
  for (final code in ['Dumbbell', 'band']) {
    add('customExercise-equipment-$code', 'customExercise', {
      ..._exercise,
      'equipment': code,
    }, server: false);
  }
  for (final code in ['LB', 'oz']) {
    add('workoutSet-inputUnit-$code', 'workoutSet', {
      ..._setLb,
      'inputUnit': code,
    }, server: false);
  }
  for (final (name, value, server, app) in [
    ('min', 0, true, true),
    ('max', 1439, true, true),
    ('negative', -1, false, false),
    ('1440', 1440, false, false),
  ]) {
    add(
      'workoutSession-startMinute-$name',
      'workoutSession',
      {..._sessionFull, 'startMinute': value},
      server: server,
      app: app,
    );
  }
  add('sessionExercise-position-negative', 'sessionExercise', {
    ..._sessionExerciseCatalog,
    'position': -1,
  }, server: false);
  // The row's integer column truncates 1.5 (both reads keep the row).
  add(
    'sessionExercise-position-1.5',
    'sessionExercise',
    {..._sessionExerciseCatalog, 'position': 1.5},
    server: false,
    app: true,
  );
  add('workoutSet-reps-negative', 'workoutSet', {
    ..._setBase,
    'reps': -1,
  }, server: false);
  add(
    'workoutSet-reps-1.5',
    'workoutSet',
    {..._setBase, 'reps': 1.5},
    server: false,
    app: true,
  );
  add('workoutSet-kg-negative', 'workoutSet', {
    ..._setBase,
    'kg': -0.1,
  }, server: false);
  add('workoutSet-kg-max', 'workoutSet', {
    ..._setBase,
    'kg': workoutMaxNumber,
    'inputValue': workoutMaxNumber,
  }, server: true);
  add(
    'workoutSet-kg-over-max',
    'workoutSet',
    {..._setBase, 'kg': c.raw('1000000000000.5')},
    server: false,
    app: true,
  );
  add('workoutSet-distance-negative', 'workoutSet', {
    ..._sets['cardio-distance']!,
    'distanceMeters': -1,
  }, server: false);
  for (final field in ['targetSets', 'targetReps']) {
    add('workoutTemplateItem-$field-0', 'workoutTemplateItem', {
      ..._itemBase,
      field: 0,
    }, server: false);
  }
  for (final (name, text, server, app) in [
    ('2026-02-29', '2026-02-29', false, false),
    ('0000-01-01', '0000-01-01', false, false),
    ('9999-12-31', '9999-12-31', true, true),
    ('short-month', '2026-1-28', false, false),
    ('padded-year', '02026-10-28', false, false),
    ('arabic-indic-digits', '٢٠٢٦-١٠-٢٨', false, false),
    ('datetime', '2026-10-28T10:00', false, false),
  ]) {
    add(
      'workoutSession-localDate-$name',
      'workoutSession',
      {..._sessionBare, 'localDate': text},
      server: server,
      app: app,
    );
  }
  // UUID forms: the parent is never found, or the draft's checkUuid throws.
  for (final (name, f) in [
    ('uppercase', (String s) => s.toUpperCase()),
    ('no-hyphens', (String s) => s.replaceAll('-', '')),
    ('braces', (String s) => '{$s}'),
    ('empty', (String s) => ''),
  ]) {
    add('sessionExercise-sessionId-$name', 'sessionExercise', {
      ..._sessionExerciseCatalog,
      'sessionId': f(workoutVectorsSessionId),
    }, server: false);
    add('workoutSession-templateId-$name', 'workoutSession', {
      ..._sessionFull,
      'templateId': f(workoutVectorsTemplateId),
    }, server: false);
  }
  add('workoutSet-sessionExerciseId-uppercase', 'workoutSet', {
    ..._setBase,
    'sessionExerciseId': workoutVectorsSessionExerciseId.toUpperCase(),
  }, server: false);
  add(
    'weeklyPlanDay-templateId-uppercase',
    'weeklyPlanDay',
    {..._planDay(DayOfWeek.wednesday, workoutVectorsTemplateId.toUpperCase())},
    server: false,
    rowId: _dayId(3),
  );
  // Names: 160 UTF-16 units on the wire, the app reads 1–80 code points.
  const max = workoutMaxNameLength;
  for (final (entity, base) in [
    ('customExercise', _exercise),
    ('workoutSession', _sessionBare),
    ('workoutTemplate', _templateBase),
  ]) {
    add(
      '$entity-name-max',
      entity,
      {...base, 'name': 'm' * max},
      server: true,
      app: false,
    );
    add(
      '$entity-name-over-max',
      entity,
      {...base, 'name': 'm' * (max + 1)},
      server: false,
      app: false,
    );
    add(
      '$entity-name-supplementary-max',
      entity,
      {...base, 'name': '${'m' * (max - 2)}\u{1f34e}'},
      server: true,
      app: false,
    );
    add(
      '$entity-name-supplementary-over-max',
      entity,
      {...base, 'name': '${'m' * (max - 1)}\u{1f34e}'},
      server: false,
      app: false,
    );
    // 80 code points of 2 units each: the app's limit, the wire's.
    add(
      '$entity-name-80-supplementary',
      entity,
      {...base, 'name': '\u{1f34e}' * 80},
      server: true,
      app: true,
    );
  }
  add('workoutSession-name-null', 'workoutSession', {
    ..._sessionFull,
    'name': null,
  }, server: true);
  add('customExercise-name-null', 'customExercise', {
    ..._exercise,
    'name': null,
  }, server: false);
  add(
    'workoutTemplate-name-number',
    'workoutTemplate',
    {..._templateBase, 'name': 5},
    server: false,
    app: true,
  );
  add(
    'customExercise-secondaryMusclesJson-over-max',
    'customExercise',
    {..._exercise, 'secondaryMusclesJson': '[${' ' * 256}]'},
    server: false,
    app: true,
  );
}

/// Members and metadata for `customExercise` and `workoutSet`: every member
/// missing, an extra member, wrong metadata types and the metadata
/// boundaries. The app maps no metadata (A34 owns it).
void _members(_Corpus c) {
  const metadata = {'createdAtMs', 'origin', 'editedByUser'};
  // A missing member is a missing column: its default, or NOT NULL fails.
  const storedWithout = {
    'customExercise': {'aliasesJson', 'primaryMuscle', 'secondaryMusclesJson'},
    'workoutSet': {
      'reps',
      'kg',
      'inputValue',
      'inputUnit',
      'durationSeconds',
      'distanceMeters',
    },
  };
  for (final (entity, base) in [
    ('customExercise', _exercise),
    ('workoutSet', _setBase),
  ]) {
    void add(
      String id,
      Map<String, Object?> payload, {
      required bool server,
      bool app = true,
    }) {
      final decoded = jsonDecode(c.encode(payload)) as Map<String, Object?>;
      final wire = workoutWireValid(entity, decoded);
      c.add(
        '$entity-$id',
        entity,
        payload,
        server: server,
        app: app,
        asymmetry: server == wire ? null : 'schemaOnly',
      );
    }

    for (final field in base.keys) {
      final defaulted =
          metadata.contains(field) || storedWithout[entity]!.contains(field);
      // Without its kg the weight set reads as reps-only; without its reps
      // it reads as a load-only set (both are W3 shapes, the app keeps them).
      add(
        'missing-$field',
        _without(base, field),
        server: false,
        app: defaulted,
      );
    }
    add('extra-member', {...base, 'notes': 'x'}, server: false);
    add('origin-number', {...base, 'origin': 5}, server: false);
    add('editedByUser-null', {...base, 'editedByUser': null}, server: false);
    add('createdAtMs-string', {...base, 'createdAtMs': '0'}, server: false);
    add('createdAtMs-max', {
      ...base,
      'createdAtMs': workoutMaxInteger,
    }, server: true);
    add('createdAtMs-negative', {...base, 'createdAtMs': -1}, server: false);
    add('createdAtMs-over-max', {
      ...base,
      'createdAtMs': workoutMaxInteger + 1,
    }, server: false);
    add('createdAtMs-1.5', {...base, 'createdAtMs': 1.5}, server: false);
    add('origin-max', {
      ...base,
      'origin': 'o' * workoutMaxOriginLength,
    }, server: true);
    add('origin-over-max', {
      ...base,
      'origin': 'o' * (workoutMaxOriginLength + 1),
    }, server: false);
  }
}

void _generic(_Corpus c) {
  void add(
    String id,
    String entity,
    Map<String, Object?> payload, {
    String? rawPayload,
    bool app = true,
  }) => c.add(
    id,
    entity,
    payload,
    rawPayload: rawPayload,
    server: false,
    app: app,
    asymmetry: 'generic',
  );

  add('customExercise-name-lone-high-surrogate', 'customExercise', {
    ..._exercise,
    'name': c.raw(r'"Press\ud800"'),
  });
  add('workoutSession-name-lone-low-surrogate', 'workoutSession', {
    ..._sessionFull,
    'name': c.raw(r'"\udc00Push"'),
  });
  add('customExercise-name-nul', 'customExercise', {
    ..._exercise,
    'name': 'Press\u0000',
  });
  // Inside the nested JSON text: the alias decodes to a lone unit (W2 reads
  // only that it's a string).
  add('customExercise-aliasesJson-nested-lone-surrogate', 'customExercise', {
    ..._exercise,
    'aliasesJson': r'["db\ud800"]',
  });
  add('customExercise-aliasesJson-outer-lone-surrogate', 'customExercise', {
    ..._exercise,
    'aliasesJson': c.raw(r'"[\"db\ud800\"]"'),
  });
  // A muscle code with a lone unit is no code: W1 rejects it as well.
  c.add(
    'customExercise-secondaryMusclesJson-nested-lone-surrogate',
    'customExercise',
    {..._exercise, 'secondaryMusclesJson': r'["triceps\ud800"]'},
    server: false,
    app: true,
  );
  add('workoutSet-kg-1e400', 'workoutSet', {
    ..._setBase,
    'kg': c.raw('1e400'),
    'inputValue': c.raw('1e400'),
  });
  add('workoutSet-kg-31-digits', 'workoutSet', {
    ..._setBase,
    'kg': c.raw('80.00000000000000000000000000001'),
  });
  // Dart keeps the last duplicate (8 reps); the server rejects any.
  final raw = c.encode(_setBase);
  add(
    'workoutSet-duplicate-reps',
    'workoutSet',
    _setBase,
    rawPayload: raw.replaceFirst('"reps":', '"reps":null,"reps":'),
  );
  // The app writes no metadata; the createdAtMs overflow is the server's.
  add('workoutTemplate-createdAtMs-1e400', 'workoutTemplate', {
    ..._templateBase,
    'createdAtMs': c.raw('1e400'),
  });
}

/// Scrubbed tombstones (B21 D10, backlog #136): the server checks no
/// scrubbing, so the live rules apply.
void _tombstones(_Corpus c) {
  void add(
    String id,
    String entity,
    Map<String, Object?> payload, {
    required bool server,
    required bool app,
    String? rule,
  }) => c.add(
    '$entity-tombstone-scrubbed$id',
    entity,
    payload,
    server: server,
    app: app,
    rule: rule,
    deleted: true,
  );

  add(
    '',
    'customExercise',
    {
      ..._exercise,
      'name': '',
      'aliasesJson': '[]',
      'primaryMuscle': null,
      'secondaryMusclesJson': '[]',
    },
    server: true,
    app: false,
  );
  add(
    '',
    'workoutSession',
    {..._sessionFull, 'name': null},
    server: true,
    app: true,
  );
  add(
    '',
    'workoutTemplate',
    {..._templateBase, 'name': ''},
    server: true,
    app: false,
  );
  add(
    '',
    'workoutSet',
    {..._setLb, 'reps': 0, 'kg': 0, 'inputValue': 0},
    server: true,
    app: true,
  );
  add(
    '-cardio',
    'workoutSet',
    {..._sets['cardio-distance']!, 'durationSeconds': 0, 'distanceMeters': 0},
    server: true,
    app: true,
  );
  // Scrubbing must keep W3's null pattern.
  add(
    '-nulls',
    'workoutSet',
    {
      ..._setLb,
      'reps': null,
      'kg': null,
      'inputValue': null,
      'inputUnit': null,
    },
    server: false,
    app: true,
    rule: workoutRules['W3'],
  );
}

/// Stable JSON bytes shared by the Dart and C# tests.
String generateWorkoutVectors() =>
    '${const JsonEncoder.withIndent('  ').convert(workoutVectors())}\n';

/// Writes only the corpus; the tests call the in-memory function.
void main() {
  File.fromUri(
    Platform.script.resolve(
      '../../../contracts/testdata/sync/workout-validation-vectors.json',
    ),
  ).writeAsStringSync(generateWorkoutVectors());
}
