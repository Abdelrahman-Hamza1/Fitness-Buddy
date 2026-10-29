import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/db/app_database.dart';

/// Row columns of workout drafts (A36 D1, D7). Pure mapping, no I/O.

/// A custom exercise's content columns.
CustomExercisesCompanion customExerciseColumns(CustomExerciseDraft draft) =>
    CustomExercisesCompanion(
      name: Value(draft.name),
      aliasesJson: Value(jsonEncode(draft.aliases)),
      exerciseType: Value(draft.type.code),
      equipment: Value(draft.equipment.code),
    );

/// A session row's content columns.
WorkoutSessionsCompanion sessionColumns(WorkoutSessionDraft draft) =>
    WorkoutSessionsCompanion(
      localDate: Value(draft.date.toString()),
      name: Value(draft.name),
      startMinute: Value(draft.startTime?.minuteOfDay),
      durationMinutes: Value(draft.durationMinutes),
      templateId: Value(draft.templateId),
    );

/// A session exercise's content columns.
SessionExercisesCompanion sessionExerciseColumns(
  String sessionId,
  SessionExerciseDraft exercise,
  int position,
) => SessionExercisesCompanion(
  sessionId: Value(sessionId),
  exerciseId: Value(exercise.exerciseId),
  position: Value(position),
);

/// A set's content columns. A weight typed in kg stores its kg as the typed
/// value (TD-017).
WorkoutSetsCompanion setColumns(
  String sessionExerciseId,
  LoggedSet set,
  int position,
) {
  final kg = set.values.kg;
  return WorkoutSetsCompanion(
    sessionExerciseId: Value(sessionExerciseId),
    position: Value(position),
    reps: Value(set.values.reps),
    kg: Value(kg),
    inputValue: Value(kg == null ? null : set.inputValue ?? kg),
    inputUnit: Value(kg == null ? null : set.inputUnit.code),
    durationSeconds: Value(set.values.durationSeconds),
    distanceMeters: Value(set.values.distanceMeters),
  );
}

/// A template row's content columns.
WorkoutTemplatesCompanion templateColumns(WorkoutTemplateDraft draft) =>
    WorkoutTemplatesCompanion(name: Value(draft.name));

/// A template item's content columns.
WorkoutTemplateItemsCompanion templateItemColumns(
  String templateId,
  TemplateItemDraft item,
  int position,
) => WorkoutTemplateItemsCompanion(
  templateId: Value(templateId),
  exerciseId: Value(item.exerciseId),
  position: Value(position),
  targetSets: Value(item.sets),
  targetReps: Value(item.reps),
);

/// Whether stored [row] already has [draft]'s session content.
bool sameSession(WorkoutSessionRow row, WorkoutSessionDraft draft) =>
    row.localDate == draft.date.toString() &&
    row.name == draft.name &&
    row.startMinute == draft.startTime?.minuteOfDay &&
    row.durationMinutes == draft.durationMinutes &&
    row.templateId == draft.templateId;

/// Whether stored [row] already is [exercise] at [position] of [sessionId].
bool sameSessionExercise(
  SessionExerciseRow row,
  String sessionId,
  SessionExerciseDraft exercise,
  int position,
) =>
    row.sessionId == sessionId &&
    row.exerciseId == exercise.exerciseId &&
    row.position == position;

/// Whether stored [row] already is [set] at [position] of [parentId].
bool sameSet(WorkoutSetRow row, String parentId, LoggedSet set, int position) {
  final c = setColumns(parentId, set, position);
  return row.sessionExerciseId == parentId &&
      row.position == position &&
      row.reps == c.reps.value &&
      row.kg == c.kg.value &&
      row.inputValue == c.inputValue.value &&
      row.inputUnit == c.inputUnit.value &&
      row.durationSeconds == c.durationSeconds.value &&
      row.distanceMeters == c.distanceMeters.value;
}

/// Whether stored [row] already is [item] at [position] of [templateId].
bool sameTemplateItem(
  WorkoutTemplateItemRow row,
  String templateId,
  TemplateItemDraft item,
  int position,
) =>
    row.templateId == templateId &&
    row.exerciseId == item.exerciseId &&
    row.position == position &&
    row.targetSets == item.sets &&
    row.targetReps == item.reps;
