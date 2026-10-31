import 'dart:async';

import 'package:fb_domain/fb_domain.dart';
import 'package:fb_domain/testing.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/core/changes/change_providers.dart';
import 'package:fb_mobile/core/ids/id_generator.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/core/undo/undo_stack.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:fb_mobile/features/workouts/application/exercise_library.dart';
import 'package:fb_mobile/features/workouts/application/set_input.dart';
import 'package:fb_mobile/features/workouts/application/workout_actions.dart';
import 'package:fb_mobile/features/workouts/application/workout_log_controller.dart';
import 'package:fb_mobile/features/workouts/application/workout_log_state.dart';
import 'package:fb_mobile/features/workouts/application/workout_views.dart';
import 'package:fb_mobile/features/workouts/data/workout_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override, ProviderListenable;
import 'package:flutter_test/flutter_test.dart';

import '../support/workout_harness.dart';

/// Autosave timers that fire only when a test says so.
final class _Timers {
  final List<_Timer> _all = [];

  Timer create(Duration delay, void Function() callback) {
    final timer = _Timer(callback);
    _all.add(timer);
    return timer;
  }

  /// How many timers are pending.
  int get pending => _all.where((t) => t.isActive).length;

  /// Fires the pending timers (the debounce elapsed).
  void fire() {
    for (final t in [..._all.where((t) => t.isActive)]) {
      t.run();
    }
  }
}

final class _Timer implements Timer {
  new(this._callback);

  final void Function() _callback;
  bool _active = true;

  void run() {
    if (!_active) return;
    _active = false;
    _callback();
  }

  @override
  void cancel() => _active = false;

  @override
  bool get isActive => _active;

  @override
  int get tick => 0;
}

LibraryExercise _exercise(
  int n,
  Muscle primary, {
  ExerciseType type = ExerciseType.weightReps,
}) => LibraryExercise(
  id: wid(n),
  name: 'Exercise $n',
  aliases: const [],
  type: type,
  equipment: Equipment.cable,
  primary: primary,
);

/// A controller harness: the real applier over an in-memory database.
final class _Log {
  new({List<Override> extra = const []}) {
    h = WorkoutHarness();
    undo = UndoStack(
      revert: h.applier.revert,
      apply: h.applier.apply,
      clock: h.clock,
    );
    addTearDown(undo.dispose);
    container = ProviderContainer(
      overrides: [
        changeSetApplierProvider.overrideWithValue(h.applier),
        workoutApplyProvider.overrideWithValue((set) => apply(set)),
        workoutRevertProvider.overrideWithValue((inverse) => revert(inverse)),
        clockProvider.overrideWithValue(h.clock),
        idGeneratorProvider.overrideWithValue(
          SequenceIdGenerator(startMs: 0x0199e3c30000),
        ),
        undoStackProvider.overrideWithValue(undo),
        workoutRepositoryProvider.overrideWithValue(h.repository),
        workoutAutosaveTimerProvider.overrideWithValue(timers.create),
        exerciseLibraryProvider.overrideWith(
          (ref) async => ExerciseLibrary([
            _exercise(1, Muscle.chest),
            _exercise(2, Muscle.triceps),
            _exercise(3, Muscle.chest, type: ExerciseType.repsOnly),
            _exercise(4, Muscle.abs, type: ExerciseType.duration),
          ]),
        ),
        weekStartProvider.overrideWith(
          (ref) => Stream.value(DayOfWeek.saturday),
        ),
        ...extra,
      ],
    );
    addTearDown(container.dispose);
  }

  late final WorkoutHarness h;
  late final UndoStack undo;

  /// What the form writes with: the real applier unless a test replaces it.
  late Future<ApplyResult> Function(ChangeSet) apply = h.applier.apply;

  /// What the form reverts with.
  late Future<ApplyResult> Function(InverseChangeSet) revert = h.applier.revert;
  late final ProviderContainer container;
  final _Timers timers = _Timers();
  final List<ProviderSubscription<Object?>> _subs = [];

  /// Seeds custom exercises 1 and 2 (the library's).
  Future<void> seed() => h.apply([
    CreateCustomExercise(wid(1), benchDraft()),
    CreateCustomExercise(
      wid(2),
      CustomExerciseDraft(
        name: 'Pushdown',
        type: ExerciseType.weightReps,
        equipment: Equipment.cable,
      ),
    ),
    CreateCustomExercise(
      wid(3),
      CustomExerciseDraft(
        name: 'Push-up',
        type: ExerciseType.repsOnly,
        equipment: Equipment.bodyweight,
      ),
    ),
    CreateCustomExercise(
      wid(4),
      CustomExerciseDraft(
        name: 'Plank',
        type: ExerciseType.duration,
        equipment: Equipment.bodyweight,
      ),
    ),
  ]);

  /// Opens a form for [launch] and keeps it alive.
  Future<WorkoutLogController> open(LogLaunch launch) async {
    final provider = workoutLogControllerProvider(launch);
    _subs.add(container.listen(provider, (_, _) {}));
    addTearDown(() {
      for (final s in _subs) {
        s.close();
      }
    });
    final notifier = container.read(provider.notifier);
    final _ = await container.read(provider.future);
    return notifier;
  }

  LogFormState state(LogLaunch launch) =>
      container.read(workoutLogControllerProvider(launch)).requireValue;

  /// Live sessions in the database.
  Future<List<Stored<WorkoutSessionDraft>>> sessions() =>
      h.repository.allSessions();

  /// The version of session [id].
  Future<int> sessionVersion(String id) => h.version('workout_sessions', id);

  /// The debounce elapses for [c]; waits for its write.
  Future<void> fire(WorkoutLogController c) async {
    timers.fire();
    await c.flush();
  }

  /// Reads [provider]'s value, keeping it alive meanwhile.
  Future<T> read<T>(
    ProviderListenable<Future<T>> future,
    ProviderListenable<Object?> provider,
  ) async {
    _subs.add(container.listen(provider, (_, _) {}));
    return await container.read(future);
  }
}

NewLog _new([String visit = 'v1', LocalDate? date]) =>
    NewLog(visitId: visit, date: date ?? today);

void main() {
  test('WO-034 nothing is written before the first checked set', () async {
    final log = _Log();
    await log.seed();
    final launch = _new();
    final c = await log.open(launch);
    await c.addExercises([wid(1)]);
    final card = log.state(launch).exercises.single;
    c
      ..editSet(
        card.id,
        card.sets.single.id,
        const SetInput(weight: '80', reps: '8'),
      )
      ..addSet(card.id);
    await log.fire(c);
    expect(await log.sessions(), isEmpty);
    expect(log.state(launch).persisted, isFalse);
    expect(await c.finishVisit(), isA<VisitUnchanged>());
    expect(await log.sessions(), isEmpty);
  });

  test('WO-034 first check logs the session, later edits update it '
      '(debounced, one write in flight)', () async {
    final log = _Log();
    await log.seed();
    final launch = _new();
    final c = await log.open(launch);
    await c.addExercises([wid(1)]);
    var card = log.state(launch).exercises.single;
    final set1 = card.sets.single.id;
    c.editSet(card.id, set1, const SetInput(weight: '80', reps: '8'));
    expect(c.toggleSet(card.id, set1), isTrue);
    // Debounced: nothing until the timer fires.
    expect(await log.sessions(), isEmpty);
    expect(log.timers.pending, 1);
    await log.fire(c);
    final id = log.state(launch).sessionId;
    expect((await log.sessions()).single.ref.id, id);
    expect(log.state(launch).persisted, isTrue);
    expect(await log.sessionVersion(id), 1);

    // Three quick edits: one timer, one coalesced write.
    c.addSet(card.id);
    card = log.state(launch).exercises.single;
    final set2 = card.sets.last.id;
    c
      ..editSet(card.id, set2, const SetInput(weight: '80', reps: '7'))
      ..toggleSet(card.id, set2)
      ..editSet(card.id, set1, const SetInput(weight: '82.5', reps: '8'));
    expect(log.timers.pending, 1);
    await log.fire(c);
    expect(await log.sessionVersion(id), 2);
    final stored = (await log.sessions()).single.draft.exercises.single.sets;
    expect(
      [for (final s in stored) s.values],
      const [SetValues(reps: 8, kg: 82.5), SetValues(reps: 7, kg: 80)],
    );

    // An edit while a write is in flight is written right after it.
    c.editSet(card.id, set2, const SetInput(weight: '80', reps: '6'));
    final first = c.flush();
    c.editSet(card.id, set2, const SetInput(weight: '80', reps: '5'));
    final second = c.flush();
    await Future.wait([first, second]);
    expect(
      (await log.sessions()).single.draft.exercises.single.sets.last.values,
      const SetValues(reps: 5, kg: 80),
    );
    expect(log.state(launch).saveState, LogSaveState.idle);
  });

  test('WO-034 leaving flushes the pending save', () async {
    final log = _Log();
    await log.seed();
    final launch = _new();
    final c = await log.open(launch);
    await c.addExercises([wid(1)]);
    final card = log.state(launch).exercises.single;
    c
      ..editSet(
        card.id,
        card.sets.single.id,
        const SetInput(weight: '60', reps: '10'),
      )
      ..toggleSet(card.id, card.sets.single.id);
    expect(log.timers.pending, 1);
    final result = await c.finishVisit();
    expect(result, isA<VisitSaved>().having((r) => r.created, 'created', true));
    expect(
      (await log.sessions()).single.draft.exercises.single.sets.single.values,
      const SetValues(reps: 10, kg: 60),
    );
    // Its one Undo deletes the new session.
    expect(
      await log.undo.undo((result as VisitSaved).undoId!),
      UndoOutcome.undone,
    );
    expect(await log.sessions(), isEmpty);
  });

  test('WO-034 edit mode opens persisted sets checked', () async {
    final log = _Log();
    await log.seed();
    await log.h.apply([LogWorkoutSession(wid(10), sessionDraft())]);
    final launch = EditLog(wid(10), visitId: 'e1');
    final c = await log.open(launch);
    final form = log.state(launch);
    expect(form.persisted, isTrue);
    expect(form.name, 'Push');
    final sets = form.exercises.single.sets;
    expect([for (final s in sets) s.id], [wid(30), wid(31), wid(32)]);
    expect(sets.every((s) => s.checked), isTrue);
    expect(sets.first.input, const SetInput(weight: '80', reps: '8'));
    // Opening and leaving writes nothing.
    expect(await c.finishVisit(), isA<VisitUnchanged>());
    expect(await log.sessionVersion(wid(10)), 1);
  });

  test('WO-034 uncheck → save → recheck keeps the set ID', () async {
    final log = _Log();
    await log.seed();
    await log.h.apply([LogWorkoutSession(wid(10), sessionDraft())]);
    final launch = EditLog(wid(10), visitId: 'e1');
    final c = await log.open(launch);
    final card = log.state(launch).exercises.single;
    c.toggleSet(card.id, wid(32));
    await log.fire(c);
    expect(await log.h.isTombstone('workout_sets', wid(32)), isTrue);
    c.toggleSet(card.id, wid(32));
    await log.fire(c);
    expect(await log.h.isTombstone('workout_sets', wid(32)), isFalse);
    expect(
      [
        for (final s
            in (await log.sessions()).single.draft.exercises.single.sets)
          s.id,
      ],
      [wid(30), wid(31), wid(32)],
    );
  });

  test('WO-034 an exercise whose last set is unchecked leaves the saved '
      'session, and comes back on re-check', () async {
    final log = _Log();
    await log.seed();
    await log.h.apply([
      LogWorkoutSession(
        wid(10),
        WorkoutSessionDraft(
          date: today,
          exercises: [
            SessionExerciseDraft(
              id: wid(20),
              exerciseId: wid(1),
              sets: [lifted(30, 8, 80)],
            ),
            SessionExerciseDraft(
              id: wid(21),
              exerciseId: wid(2),
              sets: [lifted(40, 12, 30)],
            ),
          ],
        ),
      ),
    ]);
    final launch = EditLog(wid(10), visitId: 'e1');
    final c = await log.open(launch);
    c.toggleSet(wid(21), wid(40));
    await log.fire(c);
    expect(await log.h.isTombstone('session_exercises', wid(21)), isTrue);
    // The card stays in the form.
    expect(log.state(launch).exercises, hasLength(2));
    c.toggleSet(wid(21), wid(40));
    await log.fire(c);
    final exercises = (await log.sessions()).single.draft.exercises;
    expect([for (final e in exercises) e.id], [wid(20), wid(21)]);
    expect(exercises.last.sets.single.id, wid(40));
  });

  test('WO-034 leaving with zero checked sets deletes the persisted session '
      'with an undo that restores it', () async {
    final log = _Log();
    await log.seed();
    await log.h.apply([LogWorkoutSession(wid(10), sessionDraft())]);
    final before = await log.h.state();
    final launch = EditLog(wid(10), visitId: 'e1');
    final c = await log.open(launch);
    for (final s in [wid(30), wid(31), wid(32)]) {
      c.toggleSet(wid(20), s);
    }
    await log.fire(c);
    // Autosave never writes an empty session.
    expect(await log.sessionVersion(wid(10)), 1);
    final result = await c.finishVisit();
    expect(result, isA<VisitDeleted>());
    expect(await log.sessions(), isEmpty);
    expect(
      await log.undo.undo((result as VisitDeleted).undoId),
      UndoOutcome.undone,
    );
    expect(await log.h.state(), before);
  });

  test('WO-034 invalid edit of a checked set keeps the saved value', () async {
    final log = _Log();
    await log.seed();
    await log.h.apply([LogWorkoutSession(wid(10), sessionDraft())]);
    final launch = EditLog(wid(10), visitId: 'e1');
    final c = await log.open(launch);
    c.editSet(wid(20), wid(30), const SetInput(weight: '80', reps: 'x'));
    final row = log.state(launch).exercises.single.sets.first;
    expect(row.issue, WorkoutSetIssue.reps);
    expect(row.saved!.values, const SetValues(reps: 8, kg: 80));
    await log.fire(c);
    expect(await log.sessionVersion(wid(10)), 1);
    // A check with nothing valid is refused with the field error.
    await c.addExercises([wid(2)]);
    final fresh = log.state(launch).exercises.last;
    expect(c.toggleSet(fresh.id, fresh.sets.single.id), isFalse);
    expect(
      log.state(launch).exercises.last.sets.single.issue,
      WorkoutSetIssue.reps,
    );
  });

  test('WO-034 two editors: the second gets a conflict, stops autosaving, '
      'and never overwrites the first', () async {
    final log = _Log();
    await log.seed();
    await log.h.apply([LogWorkoutSession(wid(10), sessionDraft())]);
    final launch = EditLog(wid(10), visitId: 'e1');
    final c = await log.open(launch);
    // The first editor (another screen or device) saves first.
    await log.h.apply([
      UpdateWorkoutSession(
        VersionedId(wid(10), 1),
        sessionDraft(sets: [lifted(30, 10, 100)]),
      ),
    ]);
    final theirs = await log.h.state();
    c.editSet(wid(20), wid(31), const SetInput(weight: '80', reps: '9'));
    await log.fire(c);
    expect(log.state(launch).saveState, LogSaveState.conflict);
    expect(await log.h.state(), theirs);
    // Autosave stopped: later edits schedule nothing and write nothing.
    c.editSet(wid(20), wid(31), const SetInput(weight: '80', reps: '10'));
    expect(log.timers.pending, 0);
    await c.flush();
    expect(await log.h.state(), theirs);
    // Leaving is held until Reload or Keep mine (PA3).
    expect(await c.finishVisit(), isA<VisitConflict>());
    expect(log.state(launch).saveState, LogSaveState.conflict);
    expect(await log.h.state(), theirs);
  });

  test('WO-034 Keep mine after a conflict writes on the fresh version only '
      'when tapped', () async {
    final log = _Log();
    await log.seed();
    await log.h.apply([LogWorkoutSession(wid(10), sessionDraft())]);
    final launch = EditLog(wid(10), visitId: 'e1');
    final c = await log.open(launch);
    await log.h.apply([
      UpdateWorkoutSession(
        VersionedId(wid(10), 1),
        sessionDraft(sets: [lifted(30, 10, 100)]),
      ),
    ]);
    c.editSet(wid(20), wid(31), const SetInput(weight: '80', reps: '9'));
    await log.fire(c);
    expect(log.state(launch).saveState, LogSaveState.conflict);
    expect(await log.sessionVersion(wid(10)), 2);

    await c.keepMine();
    expect(log.state(launch).saveState, LogSaveState.idle);
    expect(await log.sessionVersion(wid(10)), 3);
    final sets = (await log.sessions()).single.draft.exercises.single.sets;
    expect([for (final s in sets) s.id], [wid(30), wid(31), wid(32)]);
    expect(sets[1].values, const SetValues(reps: 9, kg: 80));
    // Autosave resumes on the new version.
    c.editSet(wid(20), wid(32), const SetInput(weight: '80', reps: '6'));
    await log.fire(c);
    expect(await log.sessionVersion(wid(10)), 4);
    final result = await c.finishVisit();
    expect(result, isA<VisitSaved>().having((r) => r.undoId, 'undo', isNull));
  });

  test('WO-012 only checked working sets are saved, in kg with the typed '
      'unit', () async {
    final log = _Log();
    await log.seed();
    final launch = _new();
    final c = await log.open(launch);
    await c.addExercises([wid(1)]);
    final card = log.state(launch).exercises.single;
    c
      ..addSet(card.id)
      ..addSet(card.id);
    final sets = log.state(launch).exercises.single.sets;
    c
      ..editSet(card.id, sets[0].id, const SetInput(weight: '82,5', reps: '5'))
      ..toggleSet(card.id, sets[0].id)
      ..editSet(card.id, sets[1].id, const SetInput(weight: '40', reps: '12'))
      ..editSet(card.id, sets[2].id, const SetInput(weight: '80', reps: '5'))
      ..toggleSet(card.id, sets[2].id);
    await c.finishVisit();
    final stored = (await log.sessions()).single.draft.exercises.single.sets;
    expect([for (final s in stored) s.id], [sets[0].id, sets[2].id]);
    expect(stored.first.values, const SetValues(reps: 5, kg: 82.5));
    expect(stored.first.inputUnit, MassUnit.kilogram);
    expect(stored.first.inputValue, isNull);
    final row = await log.h.db.select(log.h.db.workoutSets).get();
    expect(row.firstWhere((r) => r.id == sets[0].id).inputUnit, 'kg');
  });

  test('WO-024 Repeat copies exercises and set counts with new ids, '
      "unchecked, today's date", () async {
    final log = _Log();
    await log.seed();
    final past = today.plusDays(-3);
    await log.h.apply([LogWorkoutSession(wid(10), sessionDraft(date: past))]);
    final launch = NewLog(visitId: 'r1', date: past, repeatOf: wid(10));
    final c = await log.open(launch);
    final form = log.state(launch);
    expect(form.date, today);
    expect(form.persisted, isFalse);
    expect(form.sessionId, isNot(wid(10)));
    final card = form.exercises.single;
    expect(card.exerciseId, wid(1));
    expect(card.id, isNot(wid(20)));
    expect(card.sets, hasLength(3));
    for (final s in card.sets) {
      expect(s.checked, isFalse);
      expect([wid(30), wid(31), wid(32)], isNot(contains(s.id)));
    }
    expect(card.sets.last.hint, const SetValues(reps: 7, kg: 80));
    // ✓ on an empty row accepts the hint.
    expect(c.toggleSet(card.id, card.sets.last.id), isTrue);
    await c.finishVisit();
    final logged = (await log.sessions()).last;
    expect(logged.draft.date, today);
    expect(
      logged.draft.exercises.single.sets.single.values,
      const SetValues(reps: 7, kg: 80),
    );
  });

  test('WO-011 future dates are refused', () async {
    final log = _Log();
    await log.seed();
    final launch = _new('f1', today.plusDays(2));
    final c = await log.open(launch);
    expect(log.state(launch).date, today);
    expect(c.changeDate(today.plusDays(1)), isFalse);
    expect(log.state(launch).date, today);
    expect(c.changeDate(today.plusDays(-1)), isTrue);
    expect(log.state(launch).date, today.plusDays(-1));
  });

  test('WO-024 week strip marks trained days only (no plan)', () async {
    final log = _Log();
    await log.seed();
    // 2026-10-29 is a Thursday; the week starts on Saturday 10-24.
    await log.h.apply([
      LogWorkoutSession(wid(10), sessionDraft(date: LocalDate(2026, 10, 24))),
      LogWorkoutSession(
        wid(11),
        sessionDraft(
          date: LocalDate(2026, 10, 23),
          exerciseRow: 21,
          sets: [lifted(40, 5, 50)],
        ),
      ),
    ]);
    final week = await log.read<WorkoutWeek>(
      workoutWeekProvider(today).future,
      workoutWeekProvider(today),
    );
    expect(week.days.first, LocalDate(2026, 10, 24));
    expect(week.days.last, LocalDate(2026, 10, 30));
    expect(week.trained, {LocalDate(2026, 10, 24)});
  });

  test("HM-006 Today row shows a logged session's counts and PRs, nothing "
      'without a session', () async {
    final log = _Log();
    await log.seed();
    expect(
      await log.read<TodayWorkout?>(
        todayWorkoutProvider(today).future,
        todayWorkoutProvider(today),
      ),
      isA<TodayWorkoutNone>(),
    );
    await log.h.apply([
      LogWorkoutSession(
        wid(10),
        sessionDraft(date: today.plusDays(-2), name: null),
      ),
      LogWorkoutSession(
        wid(11),
        sessionDraft(name: null, exerciseRow: 21, sets: [lifted(40, 5, 90)]),
      ),
    ]);
    // The live query notices the new rows.
    await pumpEventQueue(times: 100);
    final row =
        (await log.read<TodayWorkout?>(
              todayWorkoutProvider(today).future,
              todayWorkoutProvider(today),
            ))!
            as TodayWorkoutLogged;
    expect(row.summary.id, wid(11));
    expect(row.summary.exerciseCount, 1);
    expect(row.summary.prCount, 1);
    expect(row.summary.title, MuscleGroupsTitle([MuscleGroup.chest]));
    expect(row.more, 0);
    expect(
      await log.read<TodayWorkout?>(
        todayWorkoutProvider(today.plusDays(-1)).future,
        todayWorkoutProvider(today.plusDays(-1)),
      ),
      isA<TodayWorkoutLast>(),
    );
  });

  test('UX-030 an edit visit undoes to the session as it was', () async {
    final log = _Log();
    await log.seed();
    await log.h.apply([LogWorkoutSession(wid(10), sessionDraft())]);
    final before = await log.h.state();
    final launch = EditLog(wid(10), visitId: 'e1');
    final c = await log.open(launch);
    c
      ..removeSet(wid(20), wid(32))
      ..editSet(wid(20), wid(30), const SetInput(weight: '85', reps: '8'));
    await log.fire(c);
    final result = await c.finishVisit() as VisitSaved;
    expect(result.created, isFalse);
    expect(await log.undo.undo(result.undoId!), UndoOutcome.undone);
    expect(await log.h.state(), before);
  });

  group('review round 1: the exit path', () {
    test('WO-034 a thrown write failure keeps the visit open and nothing is '
        'reported saved', () async {
      final log = _Log();
      await log.seed();
      await log.h.apply([LogWorkoutSession(wid(10), sessionDraft())]);
      final launch = EditLog(wid(10), visitId: 'e1');
      final c = await log.open(launch);
      c.editSet(wid(20), wid(31), const SetInput(weight: '80', reps: '9'));
      log.apply = (_) async => throw DatabaseWriteException(13); // SQLITE_FULL
      expect(await c.finishVisit(), isA<VisitFailed>());
      expect(log.state(launch).saveState, LogSaveState.failed);
      // The edit is still in the form, and nothing changed in the database.
      expect(
        log.state(launch).exercises.single.sets[1].saved!.values,
        const SetValues(reps: 9, kg: 80),
      );
      expect(await log.sessionVersion(wid(10)), 1);
      // Retry once storage works again, then leave.
      log.apply = log.h.applier.apply;
      await c.flush();
      expect(log.state(launch).saveState, LogSaveState.idle);
      expect(await c.finishVisit(), isA<VisitSaved>());
      expect(
        (await log.sessions()).single.draft.exercises.single.sets[1].values,
        const SetValues(reps: 9, kg: 80),
      );
    });

    test('WO-034 a refused final save after an earlier autosave keeps the '
        'visit open; Leave without saving keeps the Undo of what was '
        'written', () async {
      final log = _Log();
      await log.seed();
      await log.h.apply([LogWorkoutSession(wid(10), sessionDraft())]);
      final before = await log.h.state();
      final launch = EditLog(wid(10), visitId: 'e1');
      final c = await log.open(launch);
      c.editSet(wid(20), wid(30), const SetInput(weight: '85', reps: '8'));
      await log.fire(c);
      expect(await log.sessionVersion(wid(10)), 2);
      c.editSet(wid(20), wid(31), const SetInput(weight: '85', reps: '8'));
      log.apply = (_) async => const Rejected(InvalidOp('invalidSet'));
      expect(await c.finishVisit(), isA<VisitFailed>());
      expect(await log.sessionVersion(wid(10)), 2);
      final result = await c.discardVisit();
      expect(result, isA<VisitSaved>());
      expect(
        await log.undo.undo((result as VisitSaved).undoId!),
        UndoOutcome.undone,
      );
      expect(await log.h.state(), before);
    });

    test('WO-034 a conflict first seen during the exit flush keeps the form '
        'with Reload / Keep mine', () async {
      final log = _Log();
      await log.seed();
      await log.h.apply([LogWorkoutSession(wid(10), sessionDraft())]);
      final launch = EditLog(wid(10), visitId: 'e1');
      final c = await log.open(launch);
      await c.addExercises([wid(2)]);
      final extra = log.state(launch).exercises.last;
      c
        ..editSet(
          extra.id,
          extra.sets.single.id,
          const SetInput(weight: '30', reps: '12'),
        )
        ..toggleSet(extra.id, extra.sets.single.id);
      // Another editor saves before the debounce fires.
      await log.h.apply([
        UpdateWorkoutSession(
          VersionedId(wid(10), 1),
          sessionDraft(sets: [lifted(30, 10, 100)]),
        ),
      ]);
      expect(await c.finishVisit(), isA<VisitConflict>());
      expect(log.state(launch).saveState, LogSaveState.conflict);
      expect(log.state(launch).exercises, hasLength(2));
      await c.keepMine();
      final result = await c.finishVisit();
      // Compensation stays dropped (PA3): no Undo for this visit.
      expect(result, isA<VisitSaved>().having((r) => r.undoId, 'undo', isNull));
      final exercises = (await log.sessions()).single.draft.exercises;
      expect(
        exercises.last.sets.single.values,
        const SetValues(reps: 12, kg: 30),
      );
    });

    test('WO-034 an edit made while the exit write is pending is written '
        'before the visit closes', () async {
      final log = _Log();
      await log.seed();
      await log.h.apply([LogWorkoutSession(wid(10), sessionDraft())]);
      final launch = EditLog(wid(10), visitId: 'e1');
      final c = await log.open(launch);
      final gate = Completer<void>();
      var writes = 0;
      log.apply = (set) async {
        if (writes++ == 0) await gate.future;
        return await log.h.applier.apply(set);
      };
      c.editSet(wid(20), wid(30), const SetInput(weight: '82.5', reps: '8'));
      final leaving = c.finishVisit();
      await pumpEventQueue();
      c.editSet(wid(20), wid(30), const SetInput(weight: '85', reps: '8'));
      gate.complete();
      expect(await leaving, isA<VisitSaved>());
      expect(
        (await log.sessions()).single.draft.exercises.single.sets.first.values,
        const SetValues(reps: 8, kg: 85),
      );
    });

    test('WO-034 clearing a checked set shows the error and keeps the saved '
        'value (reps only, time, weight × reps)', () async {
      final log = _Log();
      await log.seed();
      final launch = _new();
      final c = await log.open(launch);
      await c.addExercises([wid(3), wid(4), wid(1)]);
      final cards = log.state(launch).exercises;
      final inputs = [
        const SetInput(reps: '20'),
        const SetInput(duration: '1:30'),
        const SetInput(weight: '80', reps: '8'),
      ];
      for (final (i, card) in cards.indexed) {
        c
          ..editSet(card.id, card.sets.single.id, inputs[i])
          ..toggleSet(card.id, card.sets.single.id);
      }
      await log.fire(c);
      final stored = [
        for (final e in (await log.sessions()).single.draft.exercises)
          e.sets.single.values,
      ];
      expect(stored, const [
        SetValues(reps: 20),
        SetValues(durationSeconds: 90),
        SetValues(reps: 8, kg: 80),
      ]);
      for (final card in cards) {
        c.editSet(card.id, card.sets.single.id, const SetInput());
      }
      await log.fire(c);
      for (final (i, card) in log.state(launch).exercises.indexed) {
        final row = card.sets.single;
        expect(row.issue, isNotNull, reason: '$i');
        expect(row.checked, isTrue);
        expect(row.saved!.values, stored[i]);
      }
      expect([
        for (final e in (await log.sessions()).single.draft.exercises)
          e.sets.single.values,
      ], stored);
    });
  });

  group('review round 2: exit races', () {
    test(
      'WO-034 Leave without saving during a running Retry waits for it: '
      'no write after close, and the Undo matches what was written',
      () async {
        final log = _Log();
        await log.seed();
        await log.h.apply([LogWorkoutSession(wid(10), sessionDraft())]);
        final before = await log.h.state();
        final launch = EditLog(wid(10), visitId: 'e1');
        final c = await log.open(launch);
        c.editSet(wid(20), wid(30), const SetInput(weight: '85', reps: '8'));
        log.apply = (_) async => const Rejected(InvalidOp('invalidSet'));
        expect(await c.finishVisit(), isA<VisitFailed>());

        final gate = Completer<void>();
        var writes = 0;
        log.apply = (set) async {
          writes++;
          await gate.future;
          return await log.h.applier.apply(set);
        };
        final retry = c.flush();
        await pumpEventQueue();
        // The failed banner gives way while the Retry runs.
        expect(log.state(launch).saveState, LogSaveState.saving);
        final leaving = c.discardVisit();
        await pumpEventQueue();
        gate.complete();
        await retry;
        final result = await leaving;
        expect(result, isA<VisitSaved>());
        expect(writes, 1);
        expect(await log.sessionVersion(wid(10)), 2);

        // Closed: edits and flushes write nothing.
        c.editSet(wid(20), wid(31), const SetInput(weight: '90', reps: '8'));
        await c.flush();
        expect(writes, 1);
        // The Undo is frozen at the Retry's write and restores the visit.
        expect(
          await log.undo.undo((result as VisitSaved).undoId!),
          UndoOutcome.undone,
        );
        expect(await log.h.state(), before);
      },
    );

    test(
      'WO-034 a set checked again while the final delete runs is kept',
      () async {
        final log = _Log();
        await log.seed();
        await log.h.apply([LogWorkoutSession(wid(10), sessionDraft())]);
        final launch = EditLog(wid(10), visitId: 'e1');
        final c = await log.open(launch);
        for (final set in [wid(30), wid(31), wid(32)]) {
          c.toggleSet(wid(20), set);
        }
        await log.fire(c);
        final gate = Completer<void>();
        log.apply = (set) async {
          if (set.ops.single is DeleteWorkoutSession) await gate.future;
          return await log.h.applier.apply(set);
        };
        final leaving = c.finishVisit();
        await pumpEventQueue();
        expect(c.toggleSet(wid(20), wid(31)), isTrue);
        gate.complete();
        final result = await leaving;
        expect(result, isA<VisitSaved>());
        final sessions = await log.sessions();
        expect(sessions.single.ref.id, wid(10));
        final sets = sessions.single.draft.exercises.single.sets;
        expect([for (final s in sets) s.id], [wid(31)]);
        expect(sets.single.values, const SetValues(reps: 8, kg: 80));
      },
    );
  });

  /// Template `wid(70)` "Push" (2 × 8 of exercise 1, 3 × 10 of exercise 2)
  /// on [days].
  Future<void> seedPlan(_Log log, List<DayOfWeek> days) => log.h.apply([
    CreateWorkoutTemplate(
      wid(70),
      WorkoutTemplateDraft(
        name: 'Push',
        items: [
          TemplateItemDraft(id: wid(71), exerciseId: wid(1), sets: 2, reps: 8),
          TemplateItemDraft(id: wid(72), exerciseId: wid(2), sets: 3, reps: 10),
        ],
      ),
    ),
    for (final day in days) SetPlanDay(day, wid(70)),
  ]);

  test(
    'WO-024 past planned days without a session render like rest days',
    () async {
      final log = _Log();
      await log.seed();
      // 2026-10-29 is a Thursday; the week runs Saturday 10-24 to Friday 10-30.
      await seedPlan(log, [
        DayOfWeek.tuesday,
        DayOfWeek.thursday,
        DayOfWeek.friday,
      ]);
      final week = await log.read<WorkoutWeek>(
        workoutWeekProvider(today).future,
        workoutWeekProvider(today),
      );
      // Tuesday 10-27 was planned and skipped: no hint, nothing "missed".
      expect(week.planned, {
        LocalDate(2026, 10, 29): 'Push',
        LocalDate(2026, 10, 30): 'Push',
      });
      expect(week.trained, isEmpty);
    },
  );

  test("HM-006 planned branch shows today's template only for today or "
      'later', () async {
    final log = _Log();
    await log.seed();
    await seedPlan(log, [
      DayOfWeek.tuesday,
      DayOfWeek.thursday,
      DayOfWeek.friday,
    ]);
    Future<TodayWorkout?> row(LocalDate date) => log.read<TodayWorkout?>(
      todayWorkoutProvider(date).future,
      todayWorkoutProvider(date),
    );
    expect(
      (await row(today) as TodayWorkoutPlanned?)?.template.ref.id,
      wid(70),
    );
    expect(await row(today.plusDays(1)), isA<TodayWorkoutPlanned>());
    // A past planned day without a session shows nothing.
    expect(await row(LocalDate(2026, 10, 27)), isA<TodayWorkoutNone>());
    // Not planned: nothing (no-plan days stay quiet).
    expect(await row(today.plusDays(2)), isA<TodayWorkoutNone>());
    // Once logged, the logged branch wins.
    await log.h.apply([LogWorkoutSession(wid(10), sessionDraft())]);
    await pumpEventQueue(times: 100);
    expect(await row(today), isA<TodayWorkoutLogged>());
  });

  test('WO-020 a template starts the form with its exercises, set counts '
      'and name', () async {
    final log = _Log();
    await log.seed();
    await seedPlan(log, const []);
    final launch = NewLog(visitId: 't1', date: today, templateId: wid(70));
    await log.open(launch);
    final form = log.state(launch);
    expect(form.name, 'Push');
    expect(form.templateId, wid(70));
    expect(form.exercises.map((e) => e.exerciseId), [wid(1), wid(2)]);
    expect(form.exercises.map((e) => e.sets.length), [2, 3]);
  });

  /// Logs a visit from template `wid(70)` with [reps] per exercise card
  /// (60 kg each) and leaves it.
  Future<(_Log, VisitSaved)> templateVisit(List<List<int>> reps) async {
    final log = _Log();
    await log.seed();
    await seedPlan(log, const []);
    final launch = NewLog(visitId: 'o1', date: today, templateId: wid(70));
    final c = await log.open(launch);
    for (final (i, card) in log.state(launch).exercises.indexed) {
      while (log.state(launch).exercises[i].sets.length < reps[i].length) {
        c.addSet(card.id);
      }
      for (final (j, set) in log.state(launch).exercises[i].sets.indexed) {
        if (j >= reps[i].length) {
          c.removeSet(card.id, set.id);
          continue;
        }
        c
          ..editSet(
            card.id,
            set.id,
            SetInput(weight: '60', reps: '${reps[i][j]}'),
          )
          ..toggleSet(card.id, set.id);
      }
    }
    return (log, await c.finishVisit() as VisitSaved);
  }

  test('WO-022 offer appears only when the session differs from its '
      'template', () async {
    // As planned (2 × 8, 3 × 10, the last set a rep short): no offer, and
    // the visit's Undo is recorded at once.
    final (_, same) = await templateVisit([
      [8, 8],
      [10, 10, 9],
    ]);
    expect(same.offer, isNull);
    expect(same.undoId, isNotNull);

    // A third set of the first exercise: offer, Undo held back.
    final (log, differs) = await templateVisit([
      [8, 8, 8],
      [10, 10, 10],
    ]);
    final offer = differs.offer!;
    expect(offer.template.ref.id, wid(70));
    expect(offer.draft.name, 'Push');
    expect(offer.draft.items.map((i) => i.sets), [3, 3]);
    // Kept exercises keep their item rows.
    expect(offer.draft.items.map((i) => i.id), [wid(71), wid(72)]);
    expect(differs.undoId, isNull);
    // Nothing was written to the template by asking.
    final stored = (await log.h.repository.watchTemplates().first).single;
    expect(stored.draft.items.map((i) => i.sets), [2, 3]);
    // Not now: the visit's Undo is recorded then, once.
    final c = log.container.read(
      workoutLogControllerProvider(
        NewLog(visitId: 'o1', date: today, templateId: wid(70)),
      ).notifier,
    );
    expect(c.recordVisitUndo(), isNotNull);
    expect(c.recordVisitUndo(), isNull);
  });

  test('WO-022 offer is absent for sessions without a template', () async {
    final log = _Log();
    await log.seed();
    await seedPlan(log, const []);
    final launch = _new('n1');
    final c = await log.open(launch);
    await c.addExercises([wid(1)]);
    final card = log.state(launch).exercises.single;
    c
      ..editSet(
        card.id,
        card.sets.single.id,
        const SetInput(weight: '80', reps: '8'),
      )
      ..toggleSet(card.id, card.sets.single.id);
    final result = await c.finishVisit() as VisitSaved;
    expect(result.offer, isNull);
    expect(result.undoId, isNotNull);
  });

  test('WO-022 Update writes the template with undo', () async {
    final (log, differs) = await templateVisit([
      [8, 8, 8],
      [10, 10, 10],
    ]);
    final offer = differs.offer!;
    final actions = WorkoutActions(
      apply: log.h.applier.apply,
      undoStack: log.undo,
      ids: SequenceIdGenerator(startMs: 0x0199e3c50000),
      repository: log.h.repository,
    );
    final outcome = await actions.saveTemplate(
      offer.template,
      offer.draft,
    ) as WorkoutActionDone;
    var stored = (await log.h.repository.watchTemplates().first).single;
    expect(stored.draft.items.map((i) => i.sets), [3, 3]);
    expect(await log.undo.undo(outcome.undoId), UndoOutcome.undone);
    stored = (await log.h.repository.watchTemplates().first).single;
    expect(stored.draft.items.map((i) => i.sets), [2, 3]);
  });

  test('WO-022 edits during the template lookup on exit are ignored, never '
      'half-written', () async {
    // The lookup waits until released, like a slow database.
    final release = Completer<void>();
    var started = false;
    late final _Log log;
    log = _Log(
      extra: [
        workoutTemplatesOnceProvider.overrideWithValue(() async {
          started = true;
          await release.future;
          return await log.h.repository.watchTemplates().first;
        }),
      ],
    );
    await log.seed();
    await seedPlan(log, const []);
    final launch = NewLog(visitId: 'g1', date: today, templateId: wid(70));
    final c = await log.open(launch);
    for (final card in log.state(launch).exercises) {
      for (final set in card.sets) {
        c
          ..editSet(card.id, set.id, const SetInput(weight: '60', reps: '9'))
          ..toggleSet(card.id, set.id);
      }
    }
    final leaving = c.finishVisit();
    while (!started) {
      await pumpEventQueue();
    }
    final written = (await log.sessions()).single;
    // In the gap: an edit, and every set unchecked (the last one too).
    final form = log.state(launch);
    final first = form.exercises.first;
    c.editSet(
      first.id,
      first.sets.first.id,
      const SetInput(weight: '99', reps: '1'),
    );
    for (final card in form.exercises) {
      for (final set in card.sets) {
        c.toggleSet(card.id, set.id);
      }
    }
    release.complete();
    final result = await leaving as VisitSaved;
    // The form was frozen: what's stored is what the form shows, and the
    // session wasn't deleted behind the user's back.
    expect(log.state(launch).exercises.first.sets.first.checked, isTrue);
    final stored = (await log.sessions()).single;
    expect(stored.draft, written.draft);
    expect(stored.ref, written.ref);
    // The offer derives from the final saved session (9 reps beat the
    // template's 8: it differs).
    expect(result.offer, isNotNull);
    expect(result.offer!.draft.items.first.reps, 9);
  });

  test('WO-020 Save as template writes a pending autosave first', () async {
    final log = _Log();
    await log.seed();
    await log.h.apply([LogWorkoutSession(wid(10), sessionDraft())]);
    final launch = EditLog(wid(10), visitId: 's1');
    final c = await log.open(launch);
    final card = log.state(launch).exercises.single;
    // A checked set edited: the save is pending, the debounce hasn't fired.
    c.editSet(
      card.id,
      card.sets.first.id,
      const SetInput(weight: '80', reps: '10'),
    );
    final source = (await c.templateSource())!;
    expect(source.exercises.single.sets.first.values.reps, 10);
    // And it's what the database holds.
    final stored = (await log.sessions()).single;
    expect(stored.draft.exercises.single.sets.first.values.reps, 10);
  });

  group('#221 A37c gaps', () {
    test('WO-022 a template lookup that throws on exit still saves; no '
        'offer, and the visit Undo is recorded', () async {
      late final _Log log;
      log = _Log(
        extra: [
          workoutTemplatesOnceProvider.overrideWithValue(
            () async => throw const FormatException('lookup failed'),
          ),
        ],
      );
      await log.seed();
      await seedPlan(log, const []);
      final launch = NewLog(visitId: 'g1', date: today, templateId: wid(70));
      final c = await log.open(launch);
      for (final card in log.state(launch).exercises) {
        for (final set in card.sets) {
          c
            ..editSet(card.id, set.id, const SetInput(weight: '60', reps: '9'))
            ..toggleSet(card.id, set.id);
        }
      }
      final result = await c.finishVisit() as VisitSaved;
      expect(result.offer, isNull);
      expect(result.undoId, isNotNull);
      expect((await log.sessions()).single.draft.templateId, wid(70));
    });

    test('WO-020 Save as template after a conflict gives nothing and writes '
        'nothing', () async {
      final log = _Log();
      await log.seed();
      await log.h.apply([LogWorkoutSession(wid(10), sessionDraft())]);
      final launch = EditLog(wid(10), visitId: 's2');
      final c = await log.open(launch);
      // Another editor saves first.
      await log.h.apply([
        UpdateWorkoutSession(
          VersionedId(wid(10), 1),
          sessionDraft(sets: [lifted(30, 10, 100)]),
        ),
      ]);
      final theirs = await log.h.state();
      c.editSet(wid(20), wid(31), const SetInput(weight: '80', reps: '9'));
      expect(await c.templateSource(), isNull);
      expect(log.state(launch).saveState, LogSaveState.conflict);
      expect(await log.h.state(), theirs);
      expect(await log.h.repository.watchTemplates().first, isEmpty);
    });

    test(
      'WO-020 Save as template after a failed write gives nothing',
      () async {
        final log = _Log();
        await log.seed();
        await log.h.apply([LogWorkoutSession(wid(10), sessionDraft())]);
        final before = await log.h.state();
        final launch = EditLog(wid(10), visitId: 's3');
        final c = await log.open(launch);
        c.editSet(wid(20), wid(31), const SetInput(weight: '80', reps: '9'));
        log.apply = (_) async =>
            throw DatabaseWriteException(13); // SQLITE_FULL
        expect(await c.templateSource(), isNull);
        expect(log.state(launch).saveState, LogSaveState.failed);
        expect(await log.h.state(), before);
      },
    );
  });

  group('review round 3', () {
    test('WO-034 Leave without saving during a Retry with newer edits '
        'pending completes', () async {
      final log = _Log();
      await log.seed();
      await log.h.apply([LogWorkoutSession(wid(10), sessionDraft())]);
      final launch = EditLog(wid(10), visitId: 'e1');
      final c = await log.open(launch);
      c.editSet(wid(20), wid(30), const SetInput(weight: '85', reps: '8'));
      log.apply = (_) async => const Rejected(InvalidOp('invalidSet'));
      expect(await c.finishVisit(), isA<VisitFailed>());
      final gate = Completer<void>();
      log.apply = (set) async {
        await gate.future;
        return await log.h.applier.apply(set);
      };
      final retry = c.flush();
      await pumpEventQueue();
      // A newer edit while the Retry is held.
      c.editSet(wid(20), wid(31), const SetInput(weight: '90', reps: '8'));
      final leaving = c.discardVisit();
      await pumpEventQueue();
      gate.complete();
      await retry.timeout(const Duration(seconds: 5));
      expect(
        await leaving.timeout(const Duration(seconds: 5)),
        isA<VisitSaved>(),
      );
    });

    test('WO-034 a failed restore after the final delete keeps the form; '
        'Retry restores the session and saves the re-checked set', () async {
      final log = _Log();
      await log.seed();
      await log.h.apply([LogWorkoutSession(wid(10), sessionDraft())]);
      final launch = EditLog(wid(10), visitId: 'e1');
      final c = await log.open(launch);
      for (final set in [wid(30), wid(31), wid(32)]) {
        c.toggleSet(wid(20), set);
      }
      await log.fire(c);
      final gate = Completer<void>();
      log
        ..apply = (set) async {
          if (set.ops.single is DeleteWorkoutSession) await gate.future;
          return await log.h.applier.apply(set);
        }
        ..revert = (_) async => throw DatabaseWriteException(10); // I/O
      final leaving = c.finishVisit();
      await pumpEventQueue();
      c.toggleSet(wid(20), wid(31));
      gate.complete();
      expect(await leaving, isA<VisitFailed>());
      expect(log.state(launch).saveState, LogSaveState.failed);
      expect(log.state(launch).exercises.single.sets[1].checked, isTrue);

      log.revert = log.h.applier.revert;
      await c.flush();
      final sessions = await log.sessions();
      expect(sessions.single.ref.id, wid(10));
      expect(
        [for (final s in sessions.single.draft.exercises.single.sets) s.id],
        [wid(31)],
      );
      expect(await c.finishVisit(), isA<VisitSaved>());
    });
  });
}
