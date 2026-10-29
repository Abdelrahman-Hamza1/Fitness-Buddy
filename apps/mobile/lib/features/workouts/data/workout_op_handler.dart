import 'package:drift/drift.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/core/changes/op_handler.dart';
import 'package:fb_mobile/core/changes/row_ops.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/db/natural_id.dart';
import 'package:fb_mobile/core/db/tables/workout_tables.dart';
import 'package:fb_mobile/features/workouts/data/workout_columns.dart';

/// The ID of the weekly-plan row of [weekday]: a natural ID, so two devices
/// editing the same weekday write the same row (A36 D7).
String planDayId(DayOfWeek weekday) =>
    naturalId(weeklyPlanDayEntity, '${weekday.isoNumber}');

/// Turns `WorkoutOp`s into workout row writes inside the applier's
/// transaction (A36 D7). Sessions and templates are aggregates: one op plans
/// the parent row and every child row, so the applier's undo restores the
/// whole aggregate atomically.
///
/// Rejections: `RowNotFound` / `VersionConflict` for a parent that is gone
/// or changed; `InvalidOp` with `duplicateId` (an ID already used),
/// `childOwnership` (a child ID that belongs to another aggregate or is a
/// tombstone), `unknownExercise`, `invalidSet` (values don't fit the
/// exercise type, WO-004), `future` (a session after today, WO-011),
/// `typeInUse` (a custom exercise's type changed while sets use it).
/// Undo is refused with `exerciseInUse` when it would remove or retype a
/// custom exercise that sessions or templates now use.
final class WorkoutOpHandler extends ChangeOpHandler<WorkoutOp> {
  /// Bound to the applier's database.
  const new(this.db);

  /// The profile database.
  final AppDatabase db;

  @override
  String get family => WorkoutOp.familyName;

  @override
  Future<OpPlan> plan(WorkoutOp op, TxReader tx, ApplyContext context) =>
      switch (op) {
        CreateCustomExercise() => _createExercise(op, tx),
        UpdateCustomExercise() => _updateExercise(op, tx),
        DeleteCustomExercise(:final exercise) => _deleteExercise(exercise, tx),
        LogWorkoutSession() => _logSession(op, tx, context),
        UpdateWorkoutSession() => _updateSession(op, tx, context),
        DeleteWorkoutSession(:final session) => _deleteSession(session, tx),
        CreateWorkoutTemplate() => _createTemplate(op, tx),
        UpdateWorkoutTemplate() => _updateTemplate(op, tx),
        DeleteWorkoutTemplate(:final template) => _deleteTemplate(template, tx),
        SetPlanDay() => _setPlanDay(op, tx),
      };

  // Custom exercises (WO-003).

  Future<OpPlan> _createExercise(CreateCustomExercise op, TxReader tx) async {
    if (await tx.row(db.customExercises, op.id) != null) _reject('duplicateId');
    return OpPlan(
      [
        InsertRow(
          db.customExercises,
          customExerciseColumns(op.draft).copyWith(id: Value(op.id)),
        ),
      ],
      revertGuards: [_notInUse(op.id)],
    );
  }

  Future<OpPlan> _updateExercise(UpdateCustomExercise op, TxReader tx) async {
    final row = await _live(
      tx,
      db.customExercises,
      customExerciseEntity,
      op.exercise,
    );
    final columns = customExerciseColumns(op.draft);
    final typeChanged = row.exerciseType != op.draft.type.code;
    if (typeChanged && await _inUse(tx.db, row.id)) _reject('typeInUse');
    if (!typeChanged &&
        row.name == columns.name.value &&
        row.aliasesJson == columns.aliasesJson.value &&
        row.equipment == columns.equipment.value) {
      return OpPlan(const []);
    }
    return OpPlan(
      [
        UpdateRow(
          db.customExercises,
          row.id,
          columns,
          expectedVersion: row.version,
        ),
      ],
      revertGuards: [if (typeChanged) _notInUse(row.id)],
    );
  }

  Future<OpPlan> _deleteExercise(VersionedId exercise, TxReader tx) async {
    await _live(tx, db.customExercises, customExerciseEntity, exercise);
    return OpPlan([
      TombstoneRow(
        db.customExercises,
        exercise.id,
        expectedVersion: exercise.expectedVersion,
      ),
    ]);
  }

  // Sessions (WO-010, WO-011).

  Future<OpPlan> _logSession(
    LogWorkoutSession op,
    TxReader tx,
    ApplyContext context,
  ) async {
    await _checkSessionDraft(op.draft, tx, context);
    if (await tx.row(db.workoutSessions, op.id) != null) {
      _reject('duplicateId');
    }
    final exerciseIds = [for (final e in op.draft.exercises) e.id];
    final setIds = [
      for (final e in op.draft.exercises) ...e.sets.map((s) => s.id),
    ];
    if ((await _exercisesById(tx, exerciseIds)).isNotEmpty ||
        (await _setsById(tx, setIds)).isNotEmpty) {
      _reject('duplicateId');
    }
    return OpPlan(
      events: [WorkoutSessionLogged(op.id, op.draft.date)],
      [
        InsertRow(
          db.workoutSessions,
          sessionColumns(op.draft).copyWith(id: Value(op.id)),
        ),
        for (final (i, exercise) in op.draft.exercises.indexed) ...[
          InsertRow(
            db.sessionExercises,
            sessionExerciseColumns(
              op.id,
              exercise,
              i,
            ).copyWith(id: Value(exercise.id)),
          ),
          for (final (j, set) in exercise.sets.indexed)
            InsertRow(
              db.workoutSets,
              setColumns(exercise.id, set, j).copyWith(id: Value(set.id)),
            ),
        ],
      ],
    );
  }

  Future<OpPlan> _updateSession(
    UpdateWorkoutSession op,
    TxReader tx,
    ApplyContext context,
  ) async {
    final session = await _live(
      tx,
      db.workoutSessions,
      workoutSessionEntity,
      op.session,
    );
    await _checkSessionDraft(op.draft, tx, context);
    final liveExercises = await _liveExercisesOf(tx, [session.id]);
    final liveSets = await _liveSetsOf(tx, liveExercises.map((e) => e.id));
    final ownExercises = {for (final e in liveExercises) e.id: e};
    final ownSets = {for (final s in liveSets) s.id: s};

    // Child ownership: an existing child ID must be a live child of this
    // session; anything else (another aggregate, a tombstone) is refused.
    final draftExerciseIds = [for (final e in op.draft.exercises) e.id];
    final draftSetIds = [
      for (final e in op.draft.exercises) ...e.sets.map((s) => s.id),
    ];
    for (final row in await _exercisesById(tx, draftExerciseIds)) {
      if (!ownExercises.containsKey(row.id)) _reject('childOwnership');
    }
    for (final row in await _setsById(tx, draftSetIds)) {
      if (!ownSets.containsKey(row.id)) _reject('childOwnership');
    }

    final sessionChanged = !sameSession(session, op.draft);
    final rows = <RowOp>[];
    for (final (i, exercise) in op.draft.exercises.indexed) {
      final columns = sessionExerciseColumns(session.id, exercise, i);
      final existing = ownExercises[exercise.id];
      if (existing == null) {
        rows.add(
          InsertRow(
            db.sessionExercises,
            columns.copyWith(id: Value(exercise.id)),
          ),
        );
      } else if (!sameSessionExercise(existing, session.id, exercise, i)) {
        rows.add(
          UpdateRow(
            db.sessionExercises,
            exercise.id,
            columns,
            expectedVersion: existing.version,
          ),
        );
      }
      for (final (j, set) in exercise.sets.indexed) {
        final columns = setColumns(exercise.id, set, j);
        final existing = ownSets[set.id];
        if (existing == null) {
          rows.add(
            InsertRow(db.workoutSets, columns.copyWith(id: Value(set.id))),
          );
        } else if (!sameSet(existing, exercise.id, set, j)) {
          rows.add(
            UpdateRow(
              db.workoutSets,
              set.id,
              columns,
              expectedVersion: existing.version,
            ),
          );
        }
      }
    }
    // Removed children become tombstones in the same change set.
    final keptSets = draftSetIds.toSet();
    final keptExercises = draftExerciseIds.toSet();
    rows
      ..addAll([
        for (final set in liveSets)
          if (!keptSets.contains(set.id))
            TombstoneRow(db.workoutSets, set.id, expectedVersion: set.version),
      ])
      ..addAll([
        for (final exercise in liveExercises)
          if (!keptExercises.contains(exercise.id))
            TombstoneRow(
              db.sessionExercises,
              exercise.id,
              expectedVersion: exercise.version,
            ),
      ]);
    if (rows.isEmpty && !sessionChanged) return OpPlan(const []);
    // Every child mutation bumps and checks the session's version (the
    // aggregate revision), so two editors holding the same version conflict
    // and a creation undo can't drop children added later.
    return OpPlan(
      revertGuards: [_restoredSetsFit],
      [
        UpdateRow(
          db.workoutSessions,
          session.id,
          sessionChanged
              ? sessionColumns(op.draft)
              : const WorkoutSessionsCompanion(),
          expectedVersion: session.version,
        ),
        ...rows,
      ],
    );
  }

  Future<OpPlan> _deleteSession(VersionedId session, TxReader tx) async {
    await _live(tx, db.workoutSessions, workoutSessionEntity, session);
    final exercises = await _liveExercisesOf(tx, [session.id]);
    final sets = await _liveSetsOf(tx, exercises.map((e) => e.id));
    return OpPlan(
      revertGuards: [_restoredSetsFit],
      [
        for (final set in sets)
          TombstoneRow(db.workoutSets, set.id, expectedVersion: set.version),
        for (final exercise in exercises)
          TombstoneRow(
            db.sessionExercises,
            exercise.id,
            expectedVersion: exercise.version,
          ),
        TombstoneRow(
          db.workoutSessions,
          session.id,
          expectedVersion: session.expectedVersion,
        ),
      ],
    );
  }

  Future<void> _checkSessionDraft(
    WorkoutSessionDraft draft,
    TxReader tx,
    ApplyContext context,
  ) async {
    if (draft.isAfter(context.today)) _reject('future');
    if (draft.templateId case final template?) {
      // A deleted template is fine (history), an unknown one isn't.
      if (await tx.row(db.workoutTemplates, template) == null) {
        _reject('unknownTemplate');
      }
    }
    final types = <String, ExerciseType>{};
    for (final exercise in draft.exercises) {
      final type = types[exercise.exerciseId] ??= await _typeOf(
        tx,
        exercise.exerciseId,
      );
      for (final set in exercise.sets) {
        if (set.values.issueFor(type) != null) _reject('invalidSet');
      }
    }
  }

  // Templates (WO-020).

  Future<OpPlan> _createTemplate(CreateWorkoutTemplate op, TxReader tx) async {
    await _checkTemplateDraft(op.draft, tx);
    if (await tx.row(db.workoutTemplates, op.id) != null) {
      _reject('duplicateId');
    }
    final itemIds = [for (final i in op.draft.items) i.id];
    if ((await _itemsById(tx, itemIds)).isNotEmpty) _reject('duplicateId');
    return OpPlan(
      revertGuards: [_notPlanned(op.id)],
      [
        InsertRow(
          db.workoutTemplates,
          templateColumns(op.draft).copyWith(id: Value(op.id)),
        ),
        for (final (i, item) in op.draft.items.indexed)
          InsertRow(
            db.workoutTemplateItems,
            templateItemColumns(op.id, item, i).copyWith(id: Value(item.id)),
          ),
      ],
    );
  }

  Future<OpPlan> _updateTemplate(UpdateWorkoutTemplate op, TxReader tx) async {
    final template = await _live(
      tx,
      db.workoutTemplates,
      workoutTemplateEntity,
      op.template,
    );
    await _checkTemplateDraft(op.draft, tx);
    final liveItems = await _liveItemsOf(tx, template.id);
    final own = {for (final i in liveItems) i.id: i};
    final draftIds = [for (final i in op.draft.items) i.id];
    for (final row in await _itemsById(tx, draftIds)) {
      if (!own.containsKey(row.id)) _reject('childOwnership');
    }
    final kept = draftIds.toSet();
    final itemRows = <RowOp>[
      for (final (i, item) in op.draft.items.indexed)
        if (own[item.id] case final existing?)
          if (!sameTemplateItem(existing, template.id, item, i))
            UpdateRow(
              db.workoutTemplateItems,
              item.id,
              templateItemColumns(template.id, item, i),
              expectedVersion: existing.version,
            )
          else
            ...const <RowOp>[]
        else
          InsertRow(
            db.workoutTemplateItems,
            templateItemColumns(
              template.id,
              item,
              i,
            ).copyWith(id: Value(item.id)),
          ),
      for (final item in liveItems)
        if (!kept.contains(item.id))
          TombstoneRow(
            db.workoutTemplateItems,
            item.id,
            expectedVersion: item.version,
          ),
    ];
    final renamed = template.name != op.draft.name;
    if (itemRows.isEmpty && !renamed) return OpPlan(const []);
    // Item changes bump and check the template's version too (aggregate
    // revision, see _updateSession).
    return OpPlan([
      UpdateRow(
        db.workoutTemplates,
        template.id,
        renamed ? templateColumns(op.draft) : const WorkoutTemplatesCompanion(),
        expectedVersion: template.version,
      ),
      ...itemRows,
    ]);
  }

  Future<OpPlan> _deleteTemplate(VersionedId template, TxReader tx) async {
    await _live(tx, db.workoutTemplates, workoutTemplateEntity, template);
    final items = await _liveItemsOf(tx, template.id);
    final planDays =
        await (tx.db.select(db.weeklyPlanDays)..where(
              (t) => t.templateId.equals(template.id) & t.deletedAt.isNull(),
            ))
            .get();
    return OpPlan([
      // Plan days that trained it become rest days (WO-021).
      for (final day in planDays)
        UpdateRow(
          db.weeklyPlanDays,
          day.id,
          const WeeklyPlanDaysCompanion(templateId: Value(null)),
          expectedVersion: day.version,
        ),
      for (final item in items)
        TombstoneRow(
          db.workoutTemplateItems,
          item.id,
          expectedVersion: item.version,
        ),
      TombstoneRow(
        db.workoutTemplates,
        template.id,
        expectedVersion: template.expectedVersion,
      ),
    ]);
  }

  Future<void> _checkTemplateDraft(
    WorkoutTemplateDraft draft,
    TxReader tx,
  ) async {
    for (final item in draft.items) {
      await _typeOf(tx, item.exerciseId);
    }
  }

  // Weekly plan (WO-021).

  Future<OpPlan> _setPlanDay(SetPlanDay op, TxReader tx) async {
    if (op.templateId case final template?) {
      if (await tx.liveRow(db.workoutTemplates, template) == null) {
        throw ChangeRejected(
          RowNotFound(entity: workoutTemplateEntity, id: template),
        );
      }
    }
    final id = planDayId(op.weekday);
    final row = await tx.row(db.weeklyPlanDays, id);
    if (row != null &&
        row.deletedAt == null &&
        row.templateId == op.templateId) {
      return OpPlan(const []);
    }
    return OpPlan([
      UpsertRow(
        db.weeklyPlanDays,
        WeeklyPlanDaysCompanion(
          id: Value(id),
          weekday: Value(op.weekday.isoNumber),
          templateId: Value(op.templateId),
        ),
      ),
    ]);
  }

  // Reads.

  Future<D> _live<T extends Table, D>(
    TxReader tx,
    TableInfo<T, D> table,
    String entity,
    VersionedId ref,
  ) async {
    final row = await tx.liveRow(table, ref.id);
    final meta = row == null ? null : await tx.meta(table, ref.id);
    if (row == null || meta == null) {
      throw ChangeRejected(RowNotFound(entity: entity, id: ref.id));
    }
    if (meta.version != ref.expectedVersion) {
      throw ChangeRejected(
        VersionConflict(
          entity: entity,
          id: ref.id,
          expected: ref.expectedVersion,
          actual: meta.version,
        ),
      );
    }
    return row;
  }

  /// The type of exercise [id]: a custom exercise (tombstones included, so
  /// history stays editable) or a built-in from the attached catalog pack.
  Future<ExerciseType> _typeOf(TxReader tx, String id) async {
    String? code;
    if (id.startsWith('ex:')) {
      if (await db.isCatalogAttached()) {
        final row = await tx.db
            .customSelect(
              'SELECT type FROM ${AppDatabase.catalogSchema}.exercises '
              'WHERE id = ?',
              variables: [Variable.withString(id)],
            )
            .getSingleOrNull();
        code = row?.read<String>('type');
      }
    } else {
      code = (await tx.row(db.customExercises, id))?.exerciseType;
    }
    final type = code == null ? null : ExerciseType.fromCode(code);
    if (type == null) _reject('unknownExercise');
    return type;
  }

  Future<List<SessionExerciseRow>> _exercisesById(
    TxReader tx,
    List<String> ids,
  ) async => ids.isEmpty
      ? const []
      : await (tx.db.select(
          db.sessionExercises,
        )..where((t) => t.id.isIn(ids))).get();

  Future<List<WorkoutSetRow>> _setsById(TxReader tx, List<String> ids) async =>
      ids.isEmpty
      ? const []
      : await (tx.db.select(
          db.workoutSets,
        )..where((t) => t.id.isIn(ids))).get();

  Future<List<WorkoutTemplateItemRow>> _itemsById(
    TxReader tx,
    List<String> ids,
  ) async => ids.isEmpty
      ? const []
      : await (tx.db.select(
          db.workoutTemplateItems,
        )..where((t) => t.id.isIn(ids))).get();

  Future<List<SessionExerciseRow>> _liveExercisesOf(
    TxReader tx,
    List<String> sessionIds,
  ) => (tx.db.select(
    db.sessionExercises,
  )..where((t) => t.sessionId.isIn(sessionIds) & t.deletedAt.isNull())).get();

  Future<List<WorkoutSetRow>> _liveSetsOf(
    TxReader tx,
    Iterable<String> exerciseIds,
  ) async {
    final ids = exerciseIds.toList();
    if (ids.isEmpty) return const [];
    return await (tx.db.select(db.workoutSets)
          ..where((t) => t.sessionExerciseId.isIn(ids) & t.deletedAt.isNull()))
        .get();
  }

  Future<List<WorkoutTemplateItemRow>> _liveItemsOf(
    TxReader tx,
    String templateId,
  ) =>
      (tx.db.select(db.workoutTemplateItems)..where(
            (t) => t.templateId.equals(templateId) & t.deletedAt.isNull(),
          ))
          .get();

  /// Refuses an undo that would remove or retype custom exercise [id] while
  /// live sessions or templates use it.
  /// References are counted as they will be after the undo, so an undo that
  /// removes the exercise together with the session using it goes through.
  RevertGuard _notInUse(String id) => (q, inverse) async {
    for (final table in ['session_exercises', 'workout_template_items']) {
      if (await _referencedAfter(q, inverse, table, 'exercise_id', id)) {
        _reject('exerciseInUse');
      }
    }
  };

  /// Refuses an undo after which a session exercise it touches has a set
  /// that doesn't fit the exercise's type as it will be then (a custom
  /// exercise retyped since, WO-004). Touched: a restored set's exercise, or
  /// a restored exercise reference, whose sets are then **all** checked,
  /// restored and unchanged alike.
  Future<void> _restoredSetsFit(
    DatabaseConnectionUser q,
    List<RowOp> inverse,
  ) async {
    Map<String, Map<String, Object?>> restored(String table) => {
      for (final op in inverse)
        if (op is RestoreRow && op.table.actualTableName == table)
          op.id: op.snapshot,
    };
    final exercises = restored('session_exercises');
    final customs = restored('custom_exercises');
    final restoredSets = restored('workout_sets');
    final tombstonedSets = {
      for (final op in inverse)
        if (op is TombstoneRow && op.table.actualTableName == 'workout_sets')
          op.id,
    };
    final parents = {
      for (final set in restoredSets.values)
        if (set['deleted_at'] == null) set['session_exercise_id']! as String,
      for (final MapEntry(:key, :value) in exercises.entries)
        if (value['deleted_at'] == null) key,
    };
    final types = <String, ExerciseType?>{};
    for (final parentId in parents) {
      final exercise =
          exercises[parentId] ??
          await _rawRow(q, 'session_exercises', parentId);
      if (exercise == null || exercise['deleted_at'] != null) continue;
      final exerciseId = exercise['exercise_id']! as String;
      final type = types[exerciseId] ??= await _typeAfter(
        q,
        exerciseId,
        customs,
      );
      // The parent's sets after the undo: the live ones now, minus those
      // the undo tombstones or moves away, plus those it restores here.
      final now = await q
          .customSelect(
            'SELECT * FROM workout_sets '
            'WHERE session_exercise_id = ? AND deleted_at IS NULL',
            variables: [Variable.withString(parentId)],
          )
          .get();
      final after = <String, Map<String, Object?>>{
        for (final r in now)
          if (!tombstonedSets.contains(r.data['id']) &&
              !restoredSets.containsKey(r.data['id']))
            r.data['id']! as String: r.data,
        for (final MapEntry(:key, :value) in restoredSets.entries)
          if (value['deleted_at'] == null &&
              value['session_exercise_id'] == parentId)
            key: value,
      };
      for (final set in after.values) {
        final values = SetValues(
          reps: set['reps'] as int?,
          kg: (set['kg'] as num?)?.toDouble(),
          durationSeconds: set['duration_seconds'] as int?,
          distanceMeters: (set['distance_meters'] as num?)?.toDouble(),
        );
        if (type == null || values.issueFor(type) != null) {
          _reject('incompatibleSets');
        }
      }
    }
  }

  /// The type exercise [id] will have after an undo that restores
  /// [customs]: a restored snapshot, else the stored custom row (tombstones
  /// included), else the attached pack.
  Future<ExerciseType?> _typeAfter(
    DatabaseConnectionUser q,
    String id,
    Map<String, Map<String, Object?>> customs,
  ) async {
    final code = id.startsWith('ex:')
        ? await db.isCatalogAttached()
              ? (await q
                        .customSelect(
                          'SELECT type FROM '
                          '${AppDatabase.catalogSchema}.exercises WHERE id = ?',
                          variables: [Variable.withString(id)],
                        )
                        .getSingleOrNull())
                    ?.read<String>('type')
              : null
        : (customs[id] ??
                  await _rawRow(q, 'custom_exercises', id))?['exercise_type']
              as String?;
    return code == null ? null : ExerciseType.fromCode(code);
  }

  static Future<Map<String, Object?>?> _rawRow(
    DatabaseConnectionUser q,
    String table,
    String id,
  ) async =>
      (await q
              .customSelect(
                'SELECT * FROM $table WHERE id = ?',
                variables: [Variable.withString(id)],
              )
              .getSingleOrNull())
          ?.data;

  /// Refuses an undo that would remove template [id] while live plan days
  /// would still point at it afterwards.
  RevertGuard _notPlanned(String id) => (q, inverse) async {
    if (await _referencedAfter(
      q,
      inverse,
      'weekly_plan_days',
      'template_id',
      id,
    )) {
      _reject('templateInUse');
    }
  };

  /// Whether a row of [table] whose [column] is [value] is live once
  /// [inverse] is applied: the live rows now, minus the ones [inverse]
  /// tombstones or restores to something else, plus the ones it restores to
  /// a live reference.
  static Future<bool> _referencedAfter(
    DatabaseConnectionUser q,
    List<RowOp> inverse,
    String table,
    String column,
    String value,
  ) async {
    final live = {
      for (final r
          in await q
              .customSelect(
                'SELECT id FROM $table '
                'WHERE $column = ? AND deleted_at IS NULL',
                variables: [Variable.withString(value)],
              )
              .get())
        r.read<String>('id'),
    };
    for (final op in inverse) {
      if (op.table.actualTableName != table) continue;
      if (op is TombstoneRow) {
        live.remove(op.id);
      } else if (op is RestoreRow) {
        final snapshot = op.snapshot;
        if (snapshot['deleted_at'] == null && snapshot[column] == value) {
          live.add(op.id);
        } else {
          live.remove(op.id);
        }
      }
    }
    return live.isNotEmpty;
  }

  static Future<bool> _inUse(DatabaseConnectionUser q, String id) async {
    final rows = await q
        .customSelect(
          'SELECT 1 FROM session_exercises '
          'WHERE exercise_id = ?1 AND deleted_at IS NULL '
          'UNION ALL SELECT 1 FROM workout_template_items '
          'WHERE exercise_id = ?1 AND deleted_at IS NULL LIMIT 1',
          variables: [Variable.withString(id)],
        )
        .get();
    return rows.isNotEmpty;
  }
}

Never _reject(String code) => throw ChangeRejected(InvalidOp(code));
