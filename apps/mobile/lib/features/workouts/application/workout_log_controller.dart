import 'dart:async';

import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/core/changes/change_providers.dart';
import 'package:fb_mobile/core/ids/id_generator.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/core/undo/undo_stack.dart';
import 'package:fb_mobile/features/workouts/application/exercise_library.dart';
import 'package:fb_mobile/features/workouts/application/set_input.dart';
import 'package:fb_mobile/features/workouts/application/workout_log_state.dart';
import 'package:fb_mobile/features/workouts/data/workout_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'workout_log_controller.g.dart';

/// Starts autosave's debounce timer; tests replace it with a manual one.
typedef AutosaveTimer = Timer Function(
  Duration delay,
  void Function() callback,
);

/// The debounce of "saves as you type" (A37 D8).
const Duration autosaveDelay = Duration(milliseconds: 800);

/// The timer autosave debounces with.
@riverpod
AutosaveTimer workoutAutosaveTimer(Ref ref) => Timer.new;

/// The single writer's apply for the log form; injectable so tests can make
/// a write fail or wait.
@riverpod
Future<ApplyResult> Function(ChangeSet) workoutApply(Ref ref) =>
    ref.watch(changeSetApplierProvider).apply;

/// The single writer's revert for the log form (putting back a session the
/// final delete removed while a set was checked again); injectable so
/// tests can make it fail.
@riverpod
Future<ApplyResult> Function(InverseChangeSet) workoutRevert(Ref ref) =>
    ref.watch(changeSetApplierProvider).revert;

/// Reads the live templates once (the template-update offer, D21);
/// injectable so tests can delay it.
@riverpod
Future<List<Stored<WorkoutTemplateDraft>>> Function() workoutTemplatesOnce(
  Ref ref,
) {
  final repository = ref.watch(workoutRepositoryProvider);
  return () => repository.watchTemplates().first;
}

/// The SQL name of the session table, for `Applied.versionAfter`.
const String _sessionTable = 'workout_sessions';

/// Undo label keys of the log form (the screen maps them to ARB).
abstract final class WorkoutUndoLabels {
  /// A new session was saved.
  static const String saved = 'workoutSaved';

  /// An existing session was updated.
  static const String updated = 'workoutUpdated';

  /// A session was deleted.
  static const String deleted = 'workoutDeleted';
}

/// The log form (WO-034, A37 D7-D9, PA1-PA3): its cards and set rows,
/// "saves as you type" through the applier (debounced, one write in flight,
/// coalescing to the newest form), one Undo per visit as a compensating
/// change set, and a conflict state that stops autosave until Reload or
/// Keep mine. Every write is a change set (`ChangeSetApplier`).
@riverpod
class WorkoutLogController extends _$WorkoutLogController {
  ExerciseLibrary _library = ExerciseLibrary.empty;
  List<SessionEntry> _history = const [];

  /// The session before this visit (`null`: created in this visit).
  WorkoutSessionDraft? _baseline;

  /// The session row's version after the last successful write (or as
  /// opened): the next write's and the compensation's expected version.
  int? _version;

  /// The content as of [_version].
  WorkoutSessionDraft? _lastSaved;

  /// The first change set this visit wrote (the undo entry's ID).
  String? _firstWrite;

  /// The visit's Undo, held back while a template-update offer is asked
  /// (D21): recorded by [recordVisitUndo].
  ChangeSet? _pendingUndo;
  bool _created = false;
  bool _compensationDropped = false;
  bool _finished = false;

  /// Leaving without saving: no new write starts, edits are ignored.
  bool _discarding = false;

  /// The final delete that a re-check must undo before anything else is
  /// written (its restore failed once; retried by the next write).
  Applied? _deleteToRestore;

  /// The visit is closing after its final write (D21's template lookup
  /// runs): edits are ignored, so what was written is final.
  bool _closing = false;

  Timer? _timer;
  Future<_SaveOutcome>? _inFlight;
  bool _dirty = false;

  @override
  Future<LogFormState> build(LogLaunch launch) async {
    ref.onDispose(() => _timer?.cancel());
    final repository = ref.read(workoutRepositoryProvider);
    final today = EntryTime.now(ref.read(clockProvider)).localDate;
    _library = await ref.read(exerciseLibraryProvider.future);
    final all = await repository.allSessions();
    _history = [for (final s in all) (id: s.ref.id, draft: s.draft)];
    switch (launch) {
      case EditLog(:final sessionId):
        final stored = all.where((s) => s.ref.id == sessionId).firstOrNull;
        if (stored == null) throw StateError('the session is gone');
        _baseline = stored.draft;
        return _opened(stored, today);
      case NewLog(
        :final date,
        :final repeatOf,
        :final templateId,
        :final exercises,
      ):
        final ids = ref.read(idGeneratorProvider);
        final day = date.isAfter(today) ? today : date;
        final source = repeatOf == null
            ? null
            : all.where((s) => s.ref.id == repeatOf).firstOrNull;
        final sessionId = ids.next();
        final template = source != null || templateId == null
            ? null
            : (await repository.watchTemplates().first)
                  .where((t) => t.ref.id == templateId)
                  .firstOrNull;
        if (template != null) {
          // From a template (D10, D20): its name and ID, its exercises with
          // the target set counts, last time's numbers as hints.
          final empty = LogFormState(
            sessionId: sessionId,
            date: day,
            today: today,
            name: template.draft.name,
            templateId: template.ref.id,
            exercises: const [],
          );
          return empty.copyWith(
            exercises: [
              for (final item in template.draft.items)
                _newCard(item.exerciseId, ids, empty, sets: item.sets),
            ],
          );
        }
        if (source == null) {
          final empty = LogFormState(
            sessionId: sessionId,
            date: day,
            today: today,
            exercises: const [],
          );
          return empty.copyWith(
            exercises: [
              for (final id in exercises.take(WorkoutLimits.exercisesMax))
                _newCard(id, ids, empty),
            ],
          );
        }
        // Repeat (WO-024, D14): exercises and set counts with new IDs, all
        // unchecked, the old numbers as hints, today's date.
        return LogFormState(
          sessionId: sessionId,
          date: today,
          today: today,
          name: source.draft.name ?? '',
          templateId: source.draft.templateId,
          exercises: [
            for (final e in source.draft.exercises)
              LogExerciseCard(
                id: ids.next(),
                exerciseId: e.exerciseId,
                sets: [
                  for (final s in e.sets)
                    LogSetRow(id: ids.next(), hint: s.values),
                ],
              ),
          ],
        );
    }
  }

  /// A form showing [stored] with every set checked (D8: edit mode).
  LogFormState _opened(Stored<WorkoutSessionDraft> stored, LocalDate today) {
    final draft = stored.draft;
    _version = stored.ref.expectedVersion;
    _lastSaved = draft;
    return LogFormState(
      sessionId: stored.ref.id,
      date: draft.date,
      today: today,
      name: draft.name ?? '',
      templateId: draft.templateId,
      startTime: draft.startTime,
      durationMinutes: draft.durationMinutes,
      persisted: true,
      exercises: [
        for (final e in draft.exercises)
          _openedCard(e, stored.ref.id, draft.date),
      ],
    );
  }

  LogExerciseCard _openedCard(
    SessionExerciseDraft exercise,
    String sessionId,
    LocalDate date,
  ) {
    final type = _library.typeOf(exercise.exerciseId);
    final hints = LastPerformance.of(
      _history,
      exercise.exerciseId,
      date: date,
      sessionId: sessionId,
    );
    return LogExerciseCard(
      id: exercise.id,
      exerciseId: exercise.exerciseId,
      sets: [
        for (final (i, s) in exercise.sets.indexed)
          LogSetRow(
            id: s.id,
            input: type == null
                ? const SetInput()
                : SetInput.of(type, s.values),
            hint: hints.elementAtOrNull(i),
            checked: true,
            saved: s,
          ),
      ],
    );
  }

  LogFormState get _form => state.requireValue;

  /// What "Save as template" copies (WO-020): the session after writing
  /// any pending autosave, or `null` before the first write, after a
  /// conflict or a failed write (the banner says why).
  Future<WorkoutSessionDraft?> templateSource() async {
    if (!ref.mounted || state.value == null) return null;
    _timer?.cancel();
    _timer = null;
    final outcome = await _drain();
    if (!ref.mounted || outcome != _SaveOutcome.saved) return null;
    if (_form.saveState != LogSaveState.idle &&
        _form.saveState != LogSaveState.saving) {
      return null;
    }
    return _lastSaved;
  }

  void _update(LogFormState next, {bool save = true}) {
    if (_finished || _discarding || _closing) return;
    state = AsyncData(next);
    if (save) _schedule();
  }

  void _updateCard(
    String cardId,
    LogExerciseCard Function(LogExerciseCard card) change, {
    bool save = true,
  }) => _update(
    _form.copyWith(
      exercises: _form.exercises.map(
        (card) => card.id == cardId ? change(card) : card,
      ),
    ),
    save: save,
  );

  /// [card] with set [setId] changed by [change].
  static LogExerciseCard _withSet(
    LogExerciseCard card,
    String setId,
    LogSetRow Function(LogSetRow row) change,
  ) => card.withSets(card.sets.map((s) => s.id == setId ? change(s) : s));

  // Exercises.

  /// Adds [exerciseIds] in order (the picker's selection), each with last
  /// time's set count and numbers as hints (one empty set without history).
  Future<void> addExercises(List<String> exerciseIds) async {
    _library = await ref.read(exerciseLibraryProvider.future);
    if (!ref.mounted) return;
    final ids = ref.read(idGeneratorProvider);
    final form = _form;
    final room = WorkoutLimits.exercisesMax - form.exercises.length;
    final cards = [
      for (final exerciseId in exerciseIds.take(room < 0 ? 0 : room))
        _newCard(exerciseId, ids, form),
    ];
    _update(
      form.copyWith(exercises: [...form.exercises, ...cards]),
      save: false,
    );
  }

  /// A card for [exerciseId]: [sets] rows (a template's target), else last
  /// time's set count, else one.
  LogExerciseCard _newCard(
    String exerciseId,
    IdGenerator ids,
    LogFormState form, {
    int? sets,
  }) {
    final hints = LastPerformance.of(
      _history,
      exerciseId,
      date: form.date,
      sessionId: form.sessionId,
    );
    final count =
        sets ??
        (hints.isEmpty ? 1 : hints.length.clamp(1, WorkoutSetBounds.maxSets));
    return LogExerciseCard(
      id: ids.next(),
      exerciseId: exerciseId,
      sets: [
        for (var i = 0; i < count; i++)
          LogSetRow(id: ids.next(), hint: hints.elementAtOrNull(i)),
      ],
    );
  }

  /// Removes card [cardId]: the exercise leaves the saved session (D8).
  void removeExercise(String cardId) => _update(
    _form.copyWith(
      exercises: [
        for (final card in _form.exercises)
          if (card.id != cardId) card,
      ],
    ),
  );

  /// Moves card [cardId] by [delta] places (⋮ move up/down).
  void moveExercise(String cardId, int delta) {
    final cards = [..._form.exercises];
    final from = cards.indexWhere((c) => c.id == cardId);
    final to = from + delta;
    if (from < 0 || to < 0 || to >= cards.length) return;
    cards.insert(to, cards.removeAt(from));
    _update(_form.copyWith(exercises: cards));
  }

  // Sets.

  /// Adds a set to card [cardId]; its hint is last time's same set, else a
  /// copy of the previous row (D7).
  void addSet(String cardId) {
    final card = _form.exercises.firstWhere((c) => c.id == cardId);
    if (card.sets.length >= WorkoutSetBounds.maxSets * 2) return;
    final type = _library.typeOf(card.exerciseId);
    final last = card.sets.lastOrNull;
    final lastTime = LastPerformance.of(
      _history,
      card.exerciseId,
      date: _form.date,
      sessionId: _form.sessionId,
    ).elementAtOrNull(card.sets.length);
    final previous = switch (last) {
      null => null,
      final row when row.saved != null => row.saved!.values,
      final row when type != null && !row.input.isEmpty =>
        row.input.valuesFor(type).issueFor(type) == null
            ? row.input.valuesFor(type)
            : row.hint,
      final row => row.hint,
    };
    final row = LogSetRow(
      id: ref.read(idGeneratorProvider).next(),
      hint: lastTime ?? previous,
    );
    _updateCard(cardId, (c) => c.withSets([...c.sets, row]), save: false);
  }

  /// Deletes set [setId]: it leaves the saved session (D8).
  void removeSet(String cardId, String setId) => _updateCard(
    cardId,
    (c) => c.withSets([
      for (final s in c.sets)
        if (s.id != setId) s,
    ]),
  );

  /// The inputs of set [setId] became [input]. Valid values become the
  /// set's saved value (written if it's checked); invalid ones keep the
  /// last valid value and show a field error on a checked set (D8).
  void editSet(String cardId, String setId, SetInput input) {
    final card = _form.exercises.firstWhere((c) => c.id == cardId);
    final type = _library.typeOf(card.exerciseId);
    if (type == null) return;
    LogSetRow change(LogSetRow row) {
      // Empty fields accept the hint only on an unchecked row; a checked
      // row keeps its last valid value and shows the error (D8).
      if (input.isEmpty) {
        return row.copyWith(
          input: input,
          issue: row.checked ? const SetValues().issueFor(type) : null,
        );
      }
      final values = input.valuesFor(type);
      final issue = values.issueFor(type);
      if (issue != null) {
        return row.copyWith(input: input, issue: row.checked ? issue : null);
      }
      return row.copyWith(input: input, saved: LoggedSet(row.id, values));
    }

    final row = card.sets.firstWhere((s) => s.id == setId);
    _updateCard(cardId, (c) => _withSet(c, setId, change), save: row.checked);
  }

  /// Checks or unchecks set [setId]. Checking with empty inputs accepts the
  /// hint; typed values override it. Returns `false` (and shows the field
  /// error) when there's nothing valid to check.
  bool toggleSet(String cardId, String setId) {
    final card = _form.exercises.firstWhere((c) => c.id == cardId);
    final row = card.sets.firstWhere((s) => s.id == setId);
    if (row.checked) {
      _updateCard(
        cardId,
        (c) => _withSet(c, setId, (s) => s.copyWith(checked: false)),
      );
      return true;
    }
    final type = _library.typeOf(card.exerciseId);
    if (type == null) return false;
    final values = row.input.isEmpty ? row.hint : row.input.valuesFor(type);
    final issue = (values ?? const SetValues()).issueFor(type);
    if (values == null || issue != null) {
      _updateCard(
        cardId,
        (c) => _withSet(c, setId, (s) => s.copyWith(issue: issue)),
        save: false,
      );
      return false;
    }
    _updateCard(
      cardId,
      (c) => _withSet(
        c,
        setId,
        (s) => s.copyWith(
          checked: true,
          saved: LoggedSet(s.id, values),
          input: s.input.isEmpty ? SetInput.of(type, values) : s.input,
        ),
      ),
    );
    return true;
  }

  // Header.

  /// Renames the session; blank = the auto name (D10).
  void rename(String name) {
    final runes = name.runes;
    _update(
      _form.copyWith(
        name: runes.length > WorkoutLimits.nameMax
            ? String.fromCharCodes(runes.take(WorkoutLimits.nameMax))
            : name,
      ),
    );
  }

  /// Moves the session to [date]; refused (`false`) after today (WO-011).
  bool changeDate(LocalDate date) {
    if (date.isAfter(_form.today)) return false;
    _update(_form.copyWith(date: date));
    return true;
  }

  // Autosave (D8).

  void _schedule() {
    if (_form.saveState == LogSaveState.conflict) return;
    // An edit while a write is in flight is written right after it, even
    // if a flush (leaving) cancels the debounce timer.
    if (_inFlight != null) _dirty = true;
    _timer?.cancel();
    _timer = ref.read(workoutAutosaveTimerProvider)(
      autosaveDelay,
      () => unawaited(_save()),
    );
    if (_form.saveState != LogSaveState.saving) {
      state = AsyncData(_form.copyWith(saveState: LogSaveState.saving));
    }
  }

  /// Whether the form holds something not yet written: a draft that
  /// differs from the last successful write.
  bool get _pending {
    final form = _form;
    final draft = form.savedDraft;
    if (draft == null) return false;
    return !form.persisted || draft != _lastSaved || _deleteToRestore != null;
  }

  /// Writes the newest form now: one write in flight; edits during it are
  /// written right after, coalesced. Completes with the last write's
  /// outcome, never with an error (storage failures become
  /// [_SaveOutcome.failed]).
  Future<_SaveOutcome> _save() {
    _timer?.cancel();
    _timer = null;
    if (_inFlight case final running?) {
      _dirty = true;
      return running;
    }
    final done = Completer<_SaveOutcome>();
    _inFlight = done.future;
    unawaited(() async {
      var outcome = _SaveOutcome.saved;
      try {
        do {
          _dirty = false;
          outcome = await _writeOnce();
        } while (_dirty && ref.mounted && outcome == _SaveOutcome.saved);
      } finally {
        _inFlight = null;
        done.complete(outcome);
      }
    }());
    return done.future;
  }

  Future<_SaveOutcome> _writeOnce() async {
    if (!ref.mounted || _finished || _discarding) return _SaveOutcome.saved;
    final form = _form;
    if (form.saveState == LogSaveState.conflict) return _SaveOutcome.conflict;
    final draft = form.savedDraft;
    // The session the final delete removed comes back first (its restore
    // failed once); then the form is written on top as usual.
    if (draft != null && _deleteToRestore != null) {
      if (form.saveState == LogSaveState.failed) {
        _setSaveState(LogSaveState.saving);
      }
      final restored = await _restoreDeleted();
      if (restored != _SaveOutcome.saved || !ref.mounted) return restored;
      return await _writeOnce();
    }
    if (draft == null || (form.persisted && draft == _lastSaved)) {
      if (_timer == null) _setSaveState(LogSaveState.idle);
      return _SaveOutcome.saved;
    }
    // A retry after a failure: the failed banner (and its Leave without
    // saving) gives way while the write runs.
    if (form.saveState == LogSaveState.failed) {
      _setSaveState(LogSaveState.saving);
    }
    final op = form.persisted
        ? UpdateWorkoutSession(VersionedId(form.sessionId, _version!), draft)
        : LogWorkoutSession(form.sessionId, draft);
    final ApplyResult result;
    try {
      result = await ref.read(workoutApplyProvider)(
        ChangeSet([op], origin: Origin.direct),
      );
      // Disk full, I/O, a corrupt file: content-free, the form keeps it.
    } on Exception {
      if (ref.mounted) _setSaveState(LogSaveState.failed);
      return _SaveOutcome.failed;
    }
    if (!ref.mounted) return _SaveOutcome.saved;
    switch (result) {
      case Applied():
        _firstWrite ??= result.changeSetId;
        if (!form.persisted) _created = true;
        _version =
            result.versionAfter(_sessionTable, form.sessionId) ?? _version;
        _lastSaved = draft;
        state = AsyncData(
          _form.copyWith(
            persisted: true,
            saveState: _timer == null && !_dirty
                ? LogSaveState.idle
                : LogSaveState.saving,
          ),
        );
        return _SaveOutcome.saved;
      case Rejected(failure: VersionConflict() || RowNotFound()):
        _enterConflict();
        return _SaveOutcome.conflict;
      case Rejected():
        _setSaveState(LogSaveState.failed);
        return _SaveOutcome.failed;
    }
  }

  /// PA3: stop, never retry or overwrite; this visit has no Undo.
  void _enterConflict() {
    _timer?.cancel();
    _timer = null;
    _compensationDropped = true;
    _setSaveState(LogSaveState.conflict);
  }

  void _setSaveState(LogSaveState saveState) {
    if (_form.saveState != saveState) {
      state = AsyncData(_form.copyWith(saveState: saveState));
    }
  }

  /// Writes until the newest form is stored, or a write conflicts or
  /// fails (then the form stays as it is).
  Future<_SaveOutcome> _drain() async {
    var outcome = await _save();
    while (outcome == _SaveOutcome.saved &&
        ref.mounted &&
        !_discarding &&
        !_finished &&
        _pending) {
      outcome = await _save();
    }
    return outcome;
  }

  /// Writes any pending change now (leaving, app paused, Retry).
  Future<void> flush() async {
    if (!ref.mounted || state.value == null) return;
    await _drain();
  }

  // Conflict (PA3).

  /// Discards the form's unsaved changes and reopens the session as stored
  /// (an empty new form if it was deleted elsewhere). Autosave resumes;
  /// this visit keeps no Undo.
  Future<void> reload() async {
    final stored = await ref
        .read(workoutRepositoryProvider)
        .session(_form.sessionId);
    if (!ref.mounted) return;
    _compensationDropped = true;
    if (stored == null) {
      _version = null;
      _lastSaved = null;
      state = AsyncData(
        LogFormState(
          sessionId: ref.read(idGeneratorProvider).next(),
          date: _form.date,
          today: _form.today,
          exercises: const [],
        ),
      );
      return;
    }
    state = AsyncData(_opened(stored, _form.today));
  }

  /// Writes the form over whatever is stored now, on the freshly read
  /// version, only because the user tapped it. A session deleted elsewhere
  /// is logged again under new IDs. Autosave resumes; no Undo.
  Future<void> keepMine() async {
    final stored = await ref
        .read(workoutRepositoryProvider)
        .session(_form.sessionId);
    if (!ref.mounted) return;
    _compensationDropped = true;
    if (stored == null) {
      final ids = ref.read(idGeneratorProvider);
      _version = null;
      _lastSaved = null;
      state = AsyncData(
        LogFormState(
          sessionId: ids.next(),
          date: _form.date,
          today: _form.today,
          name: _form.name,
          templateId: _form.templateId,
          startTime: _form.startTime,
          durationMinutes: _form.durationMinutes,
          exercises: [
            for (final card in _form.exercises)
              LogExerciseCard(
                id: ids.next(),
                exerciseId: card.exerciseId,
                sets: [for (final s in card.sets) _reId(s, ids.next())],
              ),
          ],
        ),
      );
    } else {
      _version = stored.ref.expectedVersion;
      _lastSaved = stored.draft;
      state = AsyncData(
        _form.copyWith(persisted: true, saveState: LogSaveState.idle),
      );
    }
    await _drain();
  }

  static LogSetRow _reId(LogSetRow row, String id) => LogSetRow(
    id: id,
    input: row.input,
    hint: row.hint,
    checked: row.checked,
    saved: switch (row.saved) {
      final s? => LoggedSet(
        id,
        s.values,
        inputValue: s.inputValue,
        inputUnit: s.inputUnit,
      ),
      null => null,
    },
  );

  // Leaving (D8, D9).

  /// Ends the visit: writes until the newest form is stored, then deletes a
  /// persisted session left with no checked set (normal inverse undo), or
  /// records the visit's one Undo (a compensation frozen at the last
  /// successful write). A conflict ([VisitConflict]) or a failed write
  /// ([VisitFailed]) keeps the visit open: nothing is lost, the form offers
  /// Reload / Keep mine or Retry / Leave without saving.
  Future<VisitResult> finishVisit() async {
    if (_finished || _discarding || state.value == null) {
      return const VisitUnchanged();
    }
    final link = ref.keepAlive();
    try {
      while (true) {
        if (_form.saveState == LogSaveState.conflict) {
          return const VisitConflict();
        }
        switch (await _drain()) {
          case _SaveOutcome.conflict:
            return const VisitConflict();
          case _SaveOutcome.failed:
            return const VisitFailed();
          case _SaveOutcome.saved:
            break;
        }
        if (!ref.mounted) return const VisitUnchanged();
        if (!(_form.persisted && _form.savedDraft == null)) {
          // Freeze the form before the lookup (no await since the drain):
          // the session as written is final and the offer derives from it.
          _closing = true;
          TemplateUpdateOffer? offer;
          try {
            offer = await _templateOffer();
          } on Exception {
            // No offer: the session is saved either way.
            offer = null;
          }
          return _close(offer: offer);
        }
        // No checked set left: the final delete, serialized with writes.
        final deleted = await _exclusive(_deleteEmpty);
        if (deleted != null) return deleted;
        // A set was checked again while the delete ran: it was undone;
        // save the form instead.
      }
    } finally {
      link.close();
    }
  }

  /// Deletes the persisted session the form left without a checked set.
  /// Returns the visit's result, or `null` when the form got a checked set
  /// meanwhile (the delete is then reverted, and the caller saves again).
  Future<VisitResult?> _deleteEmpty() async {
    final form = _form;
    if (!(form.persisted && form.savedDraft == null)) return null;
    if (_deleteToRestore case final deleted?) {
      // Already deleted (its restore was pending) and still empty: done.
      _deleteToRestore = null;
      _finished = true;
      return VisitDeleted(
        ref
            .read(undoStackProvider)
            .record(deleted, UndoLabel(WorkoutUndoLabels.deleted))
            .id,
      );
    }
    _timer?.cancel();
    _timer = null;
    final ApplyResult result;
    try {
      result = await ref.read(workoutApplyProvider)(
        ChangeSet([
          DeleteWorkoutSession(VersionedId(form.sessionId, _version!)),
        ], origin: Origin.direct),
      );
    } on Exception {
      _setSaveState(LogSaveState.failed);
      return const VisitFailed();
    }
    switch (result) {
      case Applied() when _form.savedDraft != null:
        // Re-checked during the delete: put the session back as it was
        // (its inverse), then the drain writes the form on top.
        _deleteToRestore = result;
        return switch (await _restoreDeleted()) {
          _SaveOutcome.saved => null,
          _SaveOutcome.conflict => const VisitConflict(),
          _SaveOutcome.failed => const VisitFailed(),
        };
      case Applied():
        _finished = true;
        _timer?.cancel();
        _timer = null;
        return VisitDeleted(
          ref
              .read(undoStackProvider)
              .record(result, UndoLabel(WorkoutUndoLabels.deleted))
              .id,
        );
      case Rejected(failure: VersionConflict() || RowNotFound()):
        _enterConflict();
        return const VisitConflict();
      case Rejected():
        _setSaveState(LogSaveState.failed);
        return const VisitFailed();
    }
  }

  /// Puts back the session the final delete removed ([_deleteToRestore]).
  /// A storage failure keeps it pending (the next write or Retry tries
  /// again) and shows the failed state; the form keeps its data.
  Future<_SaveOutcome> _restoreDeleted() async {
    final deleted = _deleteToRestore!;
    final ApplyResult back;
    try {
      back = await ref.read(workoutRevertProvider)(deleted.inverse);
    } on Exception {
      if (ref.mounted) _setSaveState(LogSaveState.failed);
      return _SaveOutcome.failed;
    }
    if (!ref.mounted) return _SaveOutcome.saved;
    if (back is! Applied) {
      _deleteToRestore = null;
      _enterConflict();
      return _SaveOutcome.conflict;
    }
    _deleteToRestore = null;
    _version = back.versionAfter(_sessionTable, _form.sessionId) ?? _version;
    return _SaveOutcome.saved;
  }

  /// Runs [body] as the only write: after the one in flight, and with
  /// later saves waiting for it.
  Future<T> _exclusive<T>(Future<T> Function() body) async {
    for (var running = _inFlight; running != null; running = _inFlight) {
      await running;
    }
    final done = Completer<_SaveOutcome>();
    _inFlight = done.future;
    try {
      return await body();
    } finally {
      _inFlight = null;
      done.complete(_SaveOutcome.saved);
    }
  }

  /// Leaves without writing what the form still holds (the user chose
  /// "Leave without saving" after a failed write). A write already in
  /// flight (a Retry) finishes first and nothing starts after it; the
  /// visit's Undo is frozen at whatever was written.
  Future<VisitResult> discardVisit() async {
    if (_finished || _discarding || state.value == null) {
      return const VisitUnchanged();
    }
    _discarding = true;
    final link = ref.keepAlive();
    try {
      _timer?.cancel();
      _timer = null;
      for (var running = _inFlight; running != null; running = _inFlight) {
        await running;
      }
      if (_deleteToRestore case final deleted?) {
        // The final delete stands (the re-check is what's discarded): its
        // own Undo restores the session.
        _finished = true;
        return VisitDeleted(
          ref
              .read(undoStackProvider)
              .record(deleted, UndoLabel(WorkoutUndoLabels.deleted))
              .id,
        );
      }
      return _close();
    } finally {
      link.close();
    }
  }

  /// The template-update offer of this visit (WO-022, D21): only when it
  /// wrote, the session has a live template, and the saved session
  /// differs from it.
  Future<TemplateUpdateOffer?> _templateOffer() async {
    final templateId = _form.templateId;
    final saved = _lastSaved;
    if (templateId == null || saved == null || _firstWrite == null) {
      return null;
    }
    final templates = await ref.read(workoutTemplatesOnceProvider)();
    if (!ref.mounted) return null;
    final template = templates.where((t) => t.ref.id == templateId).firstOrNull;
    if (template == null) return null;
    final targets = templateUpdateFor(template.draft, saved, _library.typeOf);
    if (targets == null) return null;
    return TemplateUpdateOffer(
      template: template,
      draft: templateWithTargets(
        template.draft,
        targets,
        ref.read(idGeneratorProvider),
      ),
    );
  }

  /// Records the visit's Undo held back by a template-update offer (D21)
  /// and returns its entry ID; `null` when there's none (already recorded,
  /// or dropped by a conflict). Its window starts now.
  String? recordVisitUndo() {
    final compensation = _pendingUndo;
    if (compensation == null) return null;
    _pendingUndo = null;
    return ref
        .read(undoStackProvider)
        .recordCompensation(
          _firstWrite!,
          UndoLabel(
            _baseline == null
                ? WorkoutUndoLabels.saved
                : WorkoutUndoLabels.updated,
          ),
          compensation,
        )
        .id;
  }

  /// Ends the visit and records its Undo (D9); with an [offer], holds the
  /// Undo back for [recordVisitUndo].
  VisitResult _close({TemplateUpdateOffer? offer}) {
    _timer?.cancel();
    _timer = null;
    _finished = true;
    final first = _firstWrite;
    if (first == null) return const VisitUnchanged();
    if (_compensationDropped) {
      return VisitSaved(created: _created, undoId: null, offer: offer);
    }
    final baseline = _baseline;
    final session = VersionedId(_form.sessionId, _version!);
    _pendingUndo = ChangeSet([
      if (baseline == null)
        DeleteWorkoutSession(session)
      else
        UpdateWorkoutSession(session, baseline),
    ], origin: Origin.undo(first));
    if (offer != null) {
      return VisitSaved(created: baseline == null, undoId: null, offer: offer);
    }
    return VisitSaved(created: baseline == null, undoId: recordVisitUndo());
  }

  /// Deletes the session (⋮ Delete, D14) as a direct action with its
  /// inverse undo, and ends the visit. Returns its undo entry ID, or `null`
  /// when there was nothing to delete or it couldn't be deleted (then the
  /// form stays, in conflict or failed).
  Future<String?> deleteSession() async {
    if (_finished || state.value == null) return null;
    final link = ref.keepAlive();
    try {
      _timer?.cancel();
      _timer = null;
      await _inFlight;
      final form = _form;
      if (!form.persisted) {
        _finished = true;
        return null;
      }
      if (form.saveState == LogSaveState.conflict) return null;
      final ApplyResult result;
      try {
        result = await ref.read(workoutApplyProvider)(
          ChangeSet([
            DeleteWorkoutSession(VersionedId(form.sessionId, _version!)),
          ], origin: Origin.direct),
        );
      } on Exception {
        _setSaveState(LogSaveState.failed);
        return null;
      }
      switch (result) {
        case Applied():
          _finished = true;
          return ref
              .read(undoStackProvider)
              .record(result, UndoLabel(WorkoutUndoLabels.deleted))
              .id;
        case Rejected(failure: VersionConflict() || RowNotFound()):
          _enterConflict();
          return null;
        case Rejected():
          _setSaveState(LogSaveState.failed);
          return null;
      }
    } finally {
      link.close();
    }
  }
}

/// What a save attempt ended with.
enum _SaveOutcome {
  /// The newest form is stored (or there was nothing to write).
  saved,

  /// Another editor changed or deleted the session (PA3).
  conflict,

  /// The write was refused or storage failed.
  failed,
}
