import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Variable, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/db/write_guard.dart';
import 'package:fb_mobile/features/workouts/data/workout_columns.dart';
import 'package:fb_mobile/features/workouts/data/workout_repository.dart';
import 'package:fb_mobile/features/workouts/workouts.dart' show planDayId;
import 'package:flutter_test/flutter_test.dart';

/// The generator's parent and default row IDs (`workoutDefaultRowIds`).
const _templateId = '0199e3c2-5b1a-7c3d-8e4f-0123456789c1';
const _sessionId = '0199e3c2-5b1a-7c3d-8e4f-0123456789c2';
const _sessionExerciseId = '0199e3c2-5b1a-7c3d-8e4f-0123456789c3';
const Map<String, String> _rowIds = {
  'customExercise': '0199e3c2-5b1a-7c3d-8e4f-0123456789d1',
  'workoutSession': _sessionId,
  'sessionExercise': _sessionExerciseId,
  'workoutSet': '0199e3c2-5b1a-7c3d-8e4f-0123456789d4',
  'workoutTemplate': _templateId,
  'workoutTemplateItem': '0199e3c2-5b1a-7c3d-8e4f-0123456789d6',
};
const _hlc = '1760351234567-00000-0199e3c2-5b1a-7c3d-8e4f-0123456789ab';

const _meta = {'createdAtMs', 'origin', 'editedByUser'};

/// Each entity's table and content fields in contract order (pinned by
/// `workout_contract_test.dart`).
const _tables = {
  'customExercise': (
    'custom_exercises',
    [
      'name',
      'aliasesJson',
      'exerciseType',
      'equipment',
      'primaryMuscle',
      'secondaryMusclesJson',
    ],
  ),
  'workoutSession': (
    'workout_sessions',
    ['localDate', 'name', 'startMinute', 'durationMinutes', 'templateId'],
  ),
  'sessionExercise': (
    'session_exercises',
    ['sessionId', 'exerciseId', 'position'],
  ),
  'workoutSet': (
    'workout_sets',
    [
      'sessionExerciseId',
      'position',
      'reps',
      'kg',
      'inputValue',
      'inputUnit',
      'durationSeconds',
      'distanceMeters',
    ],
  ),
  'workoutTemplate': ('workout_templates', ['name']),
  'workoutTemplateItem': (
    'workout_template_items',
    ['templateId', 'exerciseId', 'position', 'targetSets', 'targetReps'],
  ),
  'weeklyPlanDay': ('weekly_plan_days', ['weekday', 'templateId']),
};

Map<String, dynamic> _json(String path) =>
    jsonDecode(File('../../$path').readAsStringSync()) as Map<String, dynamic>;

final Map<String, dynamic> _corpus = _json(
  'contracts/testdata/sync/workout-validation-vectors.json',
);

final List<Map<String, dynamic>> _payloads = (_corpus['payloads'] as List)
    .cast<Map<String, dynamic>>();

Map<String, Object?> _decoded(Map<String, dynamic> p) =>
    jsonDecode(p['rawPayload'] as String) as Map<String, Object?>;

String _snake(String s) =>
    s.replaceAllMapped(RegExp('[A-Z]'), (m) => '_${m[0]!.toLowerCase()}');

String _camel(String s) =>
    s.replaceAllMapped(RegExp('_([a-z])'), (m) => m[1]!.toUpperCase());

String _rowIdOf(Map<String, dynamic> p) =>
    p['rowId'] as String? ?? _rowIds[p['entity']]!;

/// Test seeding: raw SQL as sync would store it, outside the app's writer.
Future<void> _write(
  AppDatabase db,
  String sql, [
  List<Object?> args = const [],
]) => runAuthorizedWrite(() => db.customStatement(sql, args));

/// Inserts a row of [table] with fixed sync columns and [content] (column →
/// value). False when SQLite or a CHECK refuses it.
Future<bool> _insert(
  AppDatabase db,
  String table,
  String id,
  Map<String, Object?> content, {
  bool deleted = false,
}) async {
  final row = {
    'id': id,
    'created_at': 0,
    'updated_hlc': _hlc,
    'version': 1,
    'deleted_at': deleted ? 1761609600000 : null,
    'device_id': _rowIds['workoutSet'],
    'origin': 'sync',
    'edited_by_user': 0,
    ...content,
  };
  try {
    await _write(
      db,
      'INSERT INTO $table (${row.keys.join(', ')}) '
      'VALUES (${List.filled(row.length, '?').join(', ')})',
      row.values.toList(),
    );
    return true;
  } on Object {
    return false;
  }
}

/// The fixed live parents a child case needs.
Future<void> _parents(AppDatabase db, String entity) async {
  if (entity case 'sessionExercise' || 'workoutSet') {
    expect(
      await _insert(db, 'workout_sessions', _sessionId, {
        'local_date': '2026-10-28',
      }),
      isTrue,
    );
  }
  if (entity == 'workoutSet') {
    expect(
      await _insert(db, 'session_exercises', _sessionExerciseId, {
        'session_id': _sessionId,
        'exercise_id': 'ex:bench_press',
        'position': 0,
      }),
      isTrue,
    );
  }
  if (entity case 'workoutTemplateItem' || 'weeklyPlanDay') {
    expect(
      await _insert(db, 'workout_templates', _templateId, {'name': 'Push'}),
      isTrue,
    );
  }
}

/// Whether the live row [id] of [entity] shows up through the real
/// repository the way it means.
Future<bool> _reads(
  AppDatabase db,
  WorkoutRepository repo,
  String entity,
  String id,
) async {
  try {
    switch (entity) {
      case 'customExercise':
        return (await repo.watchCustomExercises().first).any(
          (s) => s.ref.id == id,
        );
      case 'workoutSession':
        return await repo.session(id) != null;
      case 'sessionExercise':
        final session = await repo.session(_sessionId);
        return session?.draft.exercises.any((e) => e.id == id) ?? false;
      case 'workoutSet':
        final session = await repo.session(_sessionId);
        return session?.draft.exercises.any(
              (e) => e.sets.any((s) => s.id == id),
            ) ??
            false;
      case 'workoutTemplate':
        return (await repo.watchTemplates().first).any((s) => s.ref.id == id);
      case 'workoutTemplateItem':
        final templates = await repo.watchTemplates().first;
        return templates.any(
          (t) =>
              t.ref.id == _templateId && t.draft.items.any((i) => i.id == id),
        );
      case 'weeklyPlanDay':
        final row =
            (await db
                    .customSelect(
                      'SELECT weekday, template_id FROM weekly_plan_days '
                      'WHERE id = ?',
                      variables: [Variable(id)],
                    )
                    .get())
                .single;
        final plan = await repo.plan();
        final templateId = row.read<String?>('template_id');
        // A rest day is absent from the plan; a planned day maps to its
        // template, which must be live.
        return templateId == null
            ? plan.isEmpty
            : plan.length == 1 &&
                  plan[DayOfWeek.fromIso(row.read<int>('weekday'))] ==
                      templateId;
    }
    throw ArgumentError.value(entity, 'entity');
    // A value the typed row can't hold (drift throws a TypeError).
    // ignore: avoid_catching_errors
  } on TypeError {
    return false;
  }
}

/// Stores [p] (as declared: live or tombstone) on a fresh in-memory
/// database (rows are never deleted, a table trigger); returns whether it
/// stored and, revived as live, whether it reads. [check] runs on that
/// database afterwards.
Future<(bool, bool)> _storeAndRead(
  Map<String, dynamic> p, [
  Future<void> Function(AppDatabase db, WorkoutRepository repo)? check,
]) async {
  final db = AppDatabase(NativeDatabase.memory());
  try {
    final result = await _storeAndReadIn(db, WorkoutRepository(db), p);
    await check?.call(db, WorkoutRepository(db));
    return result;
  } finally {
    await db.close();
  }
}

Future<(bool, bool)> _storeAndReadIn(
  AppDatabase db,
  WorkoutRepository repo,
  Map<String, dynamic> p,
) async {
  final entity = p['entity'] as String;
  final (table, fields) = _tables[entity]!;
  final payload = _decoded(p);
  final id = _rowIdOf(p);
  await _parents(db, entity);
  final stored = await _insert(db, table, id, {
    for (final f in fields)
      if (payload.containsKey(f)) _snake(f): payload[f],
  }, deleted: p['deleted'] as bool);
  if (!stored) return (false, false);
  // A tombstone reads as its live content would (revival, D5).
  await _write(db, 'UPDATE $table SET deleted_at = NULL WHERE id = ?', [id]);
  return (true, await _reads(db, repo, entity, id));
}

Map<String, Object?> _content(Map<String, Object?> payload) => {
  for (final e in payload.entries)
    if (!_meta.contains(e.key)) e.key: e.value,
};

Map<String, Object?> _written(Map<String, Object> columns) => {
  for (final MapEntry(:key, :value) in columns.entries)
    _camel(key): (value as Variable).value,
};

void main() {
  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  test('B21 every server-accepted corpus payload stores in the real '
      'tables', () async {
    final refused = <String>[];
    for (final p in _payloads.where((p) => p['serverAccepts'] == true)) {
      final (stored, _) = await _storeAndRead(p);
      if (!stored) refused.add(p['id'] as String);
    }
    expect(refused, isEmpty);
  });

  test('WO-003 WO-010 WO-020 WO-021 corpus payloads read through '
      'WorkoutRepository as declared', () async {
    expect(_payloads, hasLength(greaterThan(250)));
    final mismatches = <String>[];
    var reads = 0;
    for (final p in _payloads) {
      final (_, actual) = await _storeAndRead(p);
      if (actual) reads++;
      if (actual != p['appReads']) mismatches.add('${p['id']}: $actual');
    }
    expect(mismatches, isEmpty);
    expect(reads, greaterThan(150));
  });

  test('WO-021 WorkoutWireRules.planDayIds equal planDayId for all seven '
      'weekdays', () {
    expect(WorkoutWireRules.planDayIds, [
      for (final day in DayOfWeek.values) planDayId(day),
    ]);
  });

  test('WO-003 WO-010 WO-020 drafts written by the real column writers '
      'equal accepted corpus payloads', () async {
    final byId = {for (final p in _payloads) p['id'] as String: p};
    final writers = (_corpus['writerCases'] as List)
        .cast<Map<String, dynamic>>();
    expect(writers, hasLength(32));
    for (final w in writers) {
      final reason = w['id'] as String;
      final p = byId[w['payloadId']]!;
      final entity = p['entity'] as String;
      final wire = _decoded(p);
      final content = _content(wire);
      final id = _rowIdOf(p);
      final result = await _storeAndRead(p, (db, repo) async {
        switch (entity) {
          case 'customExercise':
            final draft = CustomExerciseDraft(
              name: wire['name']! as String,
              type: ExerciseType.fromCode(wire['exerciseType']! as String)!,
              equipment: Equipment.fromCode(wire['equipment']! as String)!,
              aliases: (jsonDecode(wire['aliasesJson']! as String) as List)
                  .cast<String>(),
              primaryMuscle: switch (wire['primaryMuscle']) {
                final String code => Muscle.fromCode(code),
                _ => null,
              },
              secondaryMuscles: [
                for (final code in (jsonDecode(
                  wire['secondaryMusclesJson']! as String,
                ) as List).cast<String>())
                  Muscle.fromCode(code)!,
              ],
            );
            expect(
              _written(customExerciseColumns(draft).toColumns(false)),
              content,
              reason: reason,
            );
            final read = (await repo.watchCustomExercises().first).single;
            expect(read.draft, draft, reason: reason);
          case 'workoutSession':
            final draft = WorkoutSessionDraft(
              date: LocalDate.tryParse(wire['localDate']! as String)!,
              exercises: const [],
              name: wire['name'] as String?,
              startTime: switch (wire['startMinute']) {
                final int m => LocalTime.ofMinuteOfDay(m),
                _ => null,
              },
              durationMinutes: wire['durationMinutes'] as int?,
              templateId: wire['templateId'] as String?,
            );
            expect(
              _written(sessionColumns(draft).toColumns(false)),
              content,
              reason: reason,
            );
            expect((await repo.session(id))!.draft, draft, reason: reason);
          case 'sessionExercise':
            final exercise = SessionExerciseDraft(
              id: id,
              exerciseId: wire['exerciseId']! as String,
              sets: const [],
            );
            expect(
              _written(
                sessionExerciseColumns(
                  wire['sessionId']! as String,
                  exercise,
                  wire['position']! as int,
                ).toColumns(false),
              ),
              content,
              reason: reason,
            );
            expect(
              (await repo.session(_sessionId))!.draft.exercises.single,
              exercise,
              reason: reason,
            );
          case 'workoutSet':
            final unit = switch (wire['inputUnit']) {
              final String code => MassUnit.fromCode(code)!,
              _ => MassUnit.kilogram,
            };
            final set = LoggedSet(
              id,
              SetValues(
                reps: wire['reps'] as int?,
                kg: (wire['kg'] as num?)?.toDouble(),
                durationSeconds: wire['durationSeconds'] as int?,
                distanceMeters: (wire['distanceMeters'] as num?)?.toDouble(),
              ),
              inputValue: unit == MassUnit.kilogram
                  ? null
                  : (wire['inputValue'] as num?)?.toDouble(),
              inputUnit: unit,
            );
            // The app writes only sets that fit some exercise type (WO-004).
            expect(
              ExerciseType.values.any((t) => set.values.issueFor(t) == null),
              isTrue,
              reason: reason,
            );
            expect(
              _written(
                setColumns(
                  wire['sessionExerciseId']! as String,
                  set,
                  wire['position']! as int,
                ).toColumns(false),
              ),
              content,
              reason: reason,
            );
            final session = (await repo.session(_sessionId))!.draft;
            expect(session.exercises.single.sets.single, set, reason: reason);
          case 'workoutTemplate':
            final draft = WorkoutTemplateDraft(
              name: wire['name']! as String,
              items: const [],
            );
            expect(
              _written(templateColumns(draft).toColumns(false)),
              content,
              reason: reason,
            );
            final read = (await repo.watchTemplates().first).single;
            expect(read.draft, draft, reason: reason);
          case 'workoutTemplateItem':
            final item = TemplateItemDraft(
              id: id,
              exerciseId: wire['exerciseId']! as String,
              sets: wire['targetSets']! as int,
              reps: wire['targetReps']! as int,
            );
            expect(
              _written(
                templateItemColumns(
                  wire['templateId']! as String,
                  item,
                  wire['position']! as int,
                ).toColumns(false),
              ),
              content,
              reason: reason,
            );
            final read = (await repo.watchTemplates().first).single;
            expect(read.draft.items.single, item, reason: reason);
          case 'weeklyPlanDay':
            final day = DayOfWeek.fromIso(wire['weekday']! as int);
            // The op handler writes the natural ID, the weekday and the
            // template (or null for rest).
            expect(planDayId(day), id, reason: reason);
            final plan = await repo.plan();
            expect(plan[day], wire['templateId'], reason: reason);
        }
      });
      expect(result, (true, true), reason: reason);
    }
  });
}
