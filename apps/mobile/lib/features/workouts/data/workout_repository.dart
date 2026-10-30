import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/db/db_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'workout_repository.g.dart';

/// The workout read side over the profile database (read-only composition
/// stays in data, the application-db rule).
@Riverpod(keepAlive: true)
WorkoutRepository workoutRepository(Ref ref) =>
    WorkoutRepository(ref.watch(appDatabaseProvider));

/// A stored aggregate: its row and version, and its content as a draft.
typedef Stored<T> = ({VersionedId ref, T draft});

/// Live reads of workouts (A36): custom exercises, sessions, templates and
/// the weekly plan. Rows the domain can't read (possible only via sync) are
/// left out, never guessed. Built-in exercises come from
/// `OfflineCatalog.exercises`.
final class WorkoutRepository {
  /// Reads [_db].
  const new(this._db);

  final AppDatabase _db;

  /// The live custom exercises, by name.
  Stream<List<Stored<CustomExerciseDraft>>> watchCustomExercises() =>
      (_db.select(_db.customExercises)
            ..where((t) => t.deletedAt.isNull())
            ..orderBy([(t) => OrderingTerm(expression: t.name)]))
          .watch()
          .map((rows) => [for (final r in rows) ?_exercise(r)]);

  /// The weekly plan: each planned weekday's template ID (WO-021). Rest
  /// days, and days pointing at a template that isn't live (a tombstone,
  /// or one not synced yet), are absent.
  Stream<Map<DayOfWeek, String>> watchPlan() => _db
      .customSelect(
        'SELECT 1 FROM weekly_plan_days, workout_templates LIMIT 0',
        readsFrom: {_db.weeklyPlanDays, _db.workoutTemplates},
      )
      .watch()
      .asyncMap((_) => plan());

  /// See [watchPlan].
  Future<Map<DayOfWeek, String>> plan() async {
    final rows = await _db
        .customSelect(
          'SELECT p.weekday, p.template_id FROM weekly_plan_days p '
          'JOIN workout_templates t ON t.id = p.template_id '
          'AND t.deleted_at IS NULL WHERE p.deleted_at IS NULL',
          readsFrom: {_db.weeklyPlanDays, _db.workoutTemplates},
        )
        .get();
    return {
      for (final r in rows)
        if (r.read<int>('weekday') case final day when day >= 1 && day <= 7)
          DayOfWeek.fromIso(day): r.read<String>('template_id'),
    };
  }

  /// The live templates, by name, with their items in order.
  Stream<List<Stored<WorkoutTemplateDraft>>> watchTemplates() => _db
      .customSelect(
        'SELECT 1 FROM workout_templates, workout_template_items LIMIT 0',
        readsFrom: {_db.workoutTemplates, _db.workoutTemplateItems},
      )
      .watch()
      .asyncMap((_) => _templates());

  Future<List<Stored<WorkoutTemplateDraft>>> _templates() =>
      _db.readSnapshot(() async {
        final templates =
            await (_db.select(_db.workoutTemplates)
                  ..where((t) => t.deletedAt.isNull())
                  ..orderBy([(t) => OrderingTerm(expression: t.name)]))
                .get();
        final items =
            await (_db.select(_db.workoutTemplateItems)
                  ..where((t) => t.deletedAt.isNull())
                  ..orderBy([(t) => OrderingTerm(expression: t.position)]))
                .get();
        return [
          for (final t in templates)
            ?_template(t, items.where((i) => i.templateId == t.id)),
        ];
      });

  /// The live sessions from [from] to [to] inclusive, by date then ID, with
  /// their exercises and sets in order (WO-040).
  Stream<List<Stored<WorkoutSessionDraft>>> watchSessions(
    LocalDate from,
    LocalDate to,
  ) => _db
      .customSelect(
        'SELECT 1 FROM workout_sessions, session_exercises, workout_sets '
        'LIMIT 0',
        readsFrom: {_db.workoutSessions, _db.sessionExercises, _db.workoutSets},
      )
      .watch()
      .asyncMap((_) => sessions(from, to));

  /// See [watchSessions].
  Future<List<Stored<WorkoutSessionDraft>>> sessions(
    LocalDate from,
    LocalDate to,
  ) => _sessionsWhere(
    (t) =>
        t.deletedAt.isNull() &
        t.localDate.isBetweenValues(from.toString(), to.toString()),
  );

  /// Every live session, by date then ID, with exercises and sets: history,
  /// last-time numbers and PR markers derive from it (A37 D24).
  Stream<List<Stored<WorkoutSessionDraft>>> watchAllSessions() => _db
      .customSelect(
        'SELECT 1 FROM workout_sessions, session_exercises, workout_sets '
        'LIMIT 0',
        readsFrom: {_db.workoutSessions, _db.sessionExercises, _db.workoutSets},
      )
      .watch()
      .asyncMap((_) => allSessions());

  /// See [watchAllSessions].
  Future<List<Stored<WorkoutSessionDraft>>> allSessions() =>
      _sessionsWhere((t) => t.deletedAt.isNull());

  /// Live session [id] with its exercises and sets, or `null` (gone, or a
  /// synced row the domain can't read).
  Future<Stored<WorkoutSessionDraft>?> session(String id) async =>
      (await _sessionsWhere((t) => t.id.equals(id) & t.deletedAt.isNull()))
          .firstOrNull;

  /// The IDs of exercises that live sessions or templates use (A37 D15: a
  /// custom exercise can be deleted only while unused).
  Stream<Set<String>> watchExerciseReferences() => _db
      .customSelect(
        'SELECT exercise_id FROM session_exercises WHERE deleted_at IS NULL '
        'UNION SELECT exercise_id FROM workout_template_items '
        'WHERE deleted_at IS NULL',
        readsFrom: {_db.sessionExercises, _db.workoutTemplateItems},
      )
      .watch()
      .map((rows) => {for (final r in rows) r.read<String>('exercise_id')});

  Future<List<Stored<WorkoutSessionDraft>>> _sessionsWhere(
    Expression<bool> Function($WorkoutSessionsTable t) filter,
  ) => _db.readSnapshot(() async {
    final rows =
        await (_db.select(_db.workoutSessions)
              ..where(filter)
              ..orderBy([
                (t) => OrderingTerm(expression: t.localDate),
                (t) => OrderingTerm(expression: t.id),
              ]))
            .get();
    if (rows.isEmpty) return const <Stored<WorkoutSessionDraft>>[];
    final exercises =
        await (_db.select(_db.sessionExercises)
              ..where(
                (t) =>
                    t.deletedAt.isNull() &
                    t.sessionId.isIn(rows.map((r) => r.id)),
              )
              ..orderBy([(t) => OrderingTerm(expression: t.position)]))
            .get();
    final sets = exercises.isEmpty
        ? const <WorkoutSetRow>[]
        : await (_db.select(_db.workoutSets)
                ..where(
                  (t) =>
                      t.deletedAt.isNull() &
                      t.sessionExerciseId.isIn(exercises.map((e) => e.id)),
                )
                ..orderBy([(t) => OrderingTerm(expression: t.position)]))
              .get();
    return [
      for (final r in rows)
        ?_session(r, exercises.where((e) => e.sessionId == r.id), sets),
    ];
  });

  /// [loggedDates], live.
  Stream<Set<LocalDate>> watchLoggedDates(LocalDate from, LocalDate to) => _db
      .customSelect(
        'SELECT 1 FROM workout_sessions LIMIT 0',
        readsFrom: {_db.workoutSessions},
      )
      .watch()
      .asyncMap((_) => loggedDates(from, to));

  /// The dates from [from] to [to] with at least one live session (TG-043,
  /// WO-061).
  Future<Set<LocalDate>> loggedDates(LocalDate from, LocalDate to) async {
    final rows =
        await (_db.selectOnly(_db.workoutSessions, distinct: true)
              ..addColumns([_db.workoutSessions.localDate])
              ..where(
                _db.workoutSessions.deletedAt.isNull() &
                    _db.workoutSessions.localDate.isBetweenValues(
                      from.toString(),
                      to.toString(),
                    ),
              ))
            .get();
    return {
      for (final r in rows)
        ?LocalDate.tryParse(r.read(_db.workoutSessions.localDate)!),
    };
  }

  Stored<CustomExerciseDraft>? _exercise(CustomExerciseRow r) {
    final type = ExerciseType.fromCode(r.exerciseType);
    final equipment = Equipment.fromCode(r.equipment);
    if (type == null || equipment == null) return null;
    try {
      final aliases = (jsonDecode(r.aliasesJson) as List<Object?>)
          .whereType<String>();
      final primary = switch (r.primaryMuscle) {
        final code? => Muscle.fromCode(code),
        null => null,
      };
      return (
        ref: VersionedId(r.id, r.version),
        draft: CustomExerciseDraft(
          name: r.name,
          type: type,
          equipment: equipment,
          aliases: aliases,
          primaryMuscle: primary,
          secondaryMuscles: _secondaries(r.secondaryMusclesJson, primary),
        ),
      );
      // Malformed aliases JSON or a synced row outside the local bounds.
    } on Object {
      return null;
    }
  }

  /// Secondary muscles read tolerantly (a synced row may break the local
  /// bounds): unknown codes, duplicates and the primary dropped, at most 4.
  static List<Muscle> _secondaries(String json, Muscle? primary) {
    try {
      return {
        for (final code
            in (jsonDecode(json) as List<Object?>).whereType<String>())
          if (Muscle.fromCode(code) case final m? when m != primary) m,
      }.take(Muscle.secondariesMax).toList();
      // Malformed JSON: no secondaries, the exercise stays visible.
    } on Object {
      return const [];
    }
  }

  Stored<WorkoutTemplateDraft>? _template(
    WorkoutTemplateRow t,
    Iterable<WorkoutTemplateItemRow> items,
  ) {
    try {
      return (
        ref: VersionedId(t.id, t.version),
        draft: WorkoutTemplateDraft(
          name: t.name,
          items: [
            for (final i in items)
              TemplateItemDraft(
                id: i.id,
                exerciseId: i.exerciseId,
                sets: i.targetSets,
                reps: i.targetReps,
              ),
          ],
        ),
      );
      // A synced row outside the local bounds: left out, never guessed.
      // ignore: avoid_catching_errors
    } on ArgumentError {
      return null;
    }
  }

  Stored<WorkoutSessionDraft>? _session(
    WorkoutSessionRow r,
    Iterable<SessionExerciseRow> exercises,
    List<WorkoutSetRow> sets,
  ) {
    final date = LocalDate.tryParse(r.localDate);
    if (date == null) return null;
    try {
      return (
        ref: VersionedId(r.id, r.version),
        draft: WorkoutSessionDraft(
          date: date,
          name: r.name,
          startTime: switch (r.startMinute) {
            final m? => LocalTime.ofMinuteOfDay(m),
            null => null,
          },
          durationMinutes: r.durationMinutes,
          templateId: r.templateId,
          exercises: [
            for (final e in exercises)
              SessionExerciseDraft(
                id: e.id,
                exerciseId: e.exerciseId,
                sets: [
                  for (final s in sets)
                    if (s.sessionExerciseId == e.id) _set(s),
                ],
              ),
          ],
        ),
      );
      // A synced row outside the local bounds: left out, never guessed.
      // ignore: avoid_catching_errors
    } on ArgumentError {
      return null;
    }
  }

  LoggedSet _set(WorkoutSetRow s) {
    final unit = s.inputUnit == null
        ? MassUnit.kilogram
        : MassUnit.fromCode(s.inputUnit!) ?? MassUnit.kilogram;
    return LoggedSet(
      s.id,
      SetValues(
        reps: s.reps,
        kg: s.kg,
        durationSeconds: s.durationSeconds,
        distanceMeters: s.distanceMeters,
      ),
      // A weight typed in kg stores its kg as the typed value (TD-017).
      inputValue: s.kg == null || unit == MassUnit.kilogram
          ? null
          : s.inputValue,
      inputUnit: unit,
    );
  }
}
