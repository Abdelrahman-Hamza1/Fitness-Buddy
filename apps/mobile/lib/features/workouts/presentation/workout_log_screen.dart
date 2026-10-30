import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/ids/id_generator.dart';
import 'package:fb_mobile/core/l10n/day_label.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/core/undo/undo_snack_bar.dart';
import 'package:fb_mobile/features/workouts/application/exercise_library.dart';
import 'package:fb_mobile/features/workouts/application/workout_log_controller.dart';
import 'package:fb_mobile/features/workouts/application/workout_log_state.dart';
import 'package:fb_mobile/features/workouts/application/workout_views.dart';
import 'package:fb_mobile/features/workouts/presentation/exercise_log_card.dart';
import 'package:fb_mobile/features/workouts/presentation/exercise_picker_screen.dart';
import 'package:fb_mobile/features/workouts/presentation/workout_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

enum _MenuAction { repeat, delete }

/// The log form (WO-034, A37 D7, D8, D14): a new session (from picking
/// exercises or a Repeat) or an existing one, edited in place. It saves as
/// you type; leaving shows the visit's one Undo. A conflict stops autosave
/// and offers Reload or Keep mine (PA3).
class WorkoutLogScreen extends ConsumerStatefulWidget {
  /// A new session on [date] (today when null) with the picked
  /// [exercises], or a Repeat of [repeatOf].
  const new newSession({
    this.date,
    this.repeatOf,
    this.exercises = const [],
    super.key,
  }) : sessionId = null,
       inToday = false;

  /// Session [sessionId]; [inToday] when opened from Today (no Repeat:
  /// it would switch tabs).
  const new session(String this.sessionId, {this.inToday = false, super.key})
    : date = null,
      repeatOf = null,
      exercises = const [];

  /// The training day of a new session.
  final LocalDate? date;

  /// The session a new one repeats.
  final String? repeatOf;

  /// The exercises a new one starts with.
  final List<String> exercises;

  /// The session to edit.
  final String? sessionId;

  /// Whether it's nested in the Today tab.
  final bool inToday;

  @override
  ConsumerState<WorkoutLogScreen> createState() => _LogState();
}

class _LogState extends ConsumerState<WorkoutLogScreen> {
  late final LogLaunch _launch;
  late final AppLifecycleListener _lifecycle;
  final TextEditingController _name = TextEditingController();
  bool _named = false;
  bool _leaving = false;

  /// Whether the visit ended (the screen is closing).
  bool _ended = false;

  @override
  void initState() {
    super.initState();
    final visit = ref.read(idGeneratorProvider).next();
    final today = ref.read(workoutTodayProvider);
    _launch = switch (widget.sessionId) {
      final id? => EditLog(id, visitId: visit),
      null => NewLog(
        visitId: visit,
        date: widget.date ?? today,
        repeatOf: widget.repeatOf,
        exercises: widget.exercises,
      ),
    };
    // D8: the pending save is written when the app goes to the background.
    _lifecycle = AppLifecycleListener(
      onStateChange: (state) {
        if (state == AppLifecycleState.paused) unawaited(_controller.flush());
      },
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _name.dispose();
    super.dispose();
  }

  WorkoutLogController get _controller =>
      ref.read(workoutLogControllerProvider(_launch).notifier);

  Future<void> _addExercises() async {
    final picked = await pickExercises(context);
    if (!mounted || picked.isEmpty) return;
    await _controller.addExercises(picked);
  }

  /// Leaves once everything is written; returns whether it left. A
  /// conflict or a failed write keeps the form open with its banner.
  Future<bool> _leave() async {
    final navigator = ref.read(appNavigatorProvider);
    if (!await _exitVisit()) return false;
    navigator.pop();
    return true;
  }

  /// The visit's exit path, without closing the screen: writes everything,
  /// finishes the visit (its Undo or the zero-set delete) and shows the
  /// feedback. Returns whether the visit ended, so the caller may close the
  /// screen: Done, the system back, or a re-tap of the tab (A45 D12, through
  /// [UnsavedEditsGuard]). A conflict or a failed write returns false and
  /// keeps the form with its banner.
  Future<bool> _exitVisit() async {
    if (_leaving) return false;
    _leaving = true;
    final result = await _controller.finishVisit();
    return _end(result);
  }

  /// "Leave without saving" after a failed write (waits for a running
  /// Retry).
  Future<void> _discard() async {
    if (_leaving) return;
    _leaving = true;
    final navigator = ref.read(appNavigatorProvider);
    final result = await _controller.discardVisit();
    if (_end(result)) navigator.pop();
  }

  /// Shows [result]'s feedback; returns whether the visit ended.
  bool _end(VisitResult result) {
    if (result is VisitConflict || result is VisitFailed) {
      // The banner offers the way out; nothing was lost.
      _leaving = false;
      return false;
    }
    _ended = true;
    if (!mounted) return true;
    final l10n = context.l10n;
    switch (result) {
      case VisitSaved(:final created, undoId: final undoId?):
        showUndoFeedback(
          context,
          message: created ? l10n.workoutSaved : l10n.workoutUpdated,
          undoEntryId: undoId,
        );
      case VisitSaved(:final created):
        showFbSnackBar(
          context,
          created ? l10n.workoutSaved : l10n.workoutUpdated,
        );
      case VisitDeleted(:final undoId):
        showUndoFeedback(
          context,
          message: l10n.workoutDeleted,
          undoEntryId: undoId,
        );
      case VisitUnchanged() || VisitConflict() || VisitFailed():
        break;
    }
    return true;
  }

  Future<void> _menu(LogFormState form) async {
    final l10n = context.l10n;
    final action = await showFbSheet<_MenuAction>(
      context,
      builder: (sheet) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!widget.inToday && form.persisted)
            FbListRow(
              title: l10n.workoutsRepeat,
              onTap: () => Navigator.of(sheet).pop(_MenuAction.repeat),
            ),
          FbListRow(
            title: l10n.workoutLogDelete,
            onTap: () => Navigator.of(sheet).pop(_MenuAction.delete),
          ),
        ],
      ),
    );
    if (!mounted || action == null) return;
    // Read before leaving: the screen is gone after its pop.
    final navigator = ref.read(appNavigatorProvider);
    switch (action) {
      case _MenuAction.repeat:
        final id = form.sessionId;
        if (await _leave()) navigator.push(WorkoutLogRoute(repeat: id));
      case _MenuAction.delete:
        if (_leaving) return;
        _leaving = true;
        final undoId = await _controller.deleteSession();
        if (!mounted) return;
        if (undoId == null &&
            (ref.read(workoutLogControllerProvider(_launch)).value?.persisted ??
                false)) {
          // It changed or couldn't be deleted: the form stays, with its
          // banner.
          _leaving = false;
          return;
        }
        if (undoId != null) {
          showUndoFeedback(
            context,
            message: l10n.workoutDeleted,
            undoEntryId: undoId,
          );
        }
        navigator.pop();
    }
  }

  Future<void> _pickDate(LogFormState form) async {
    final picked = await showFbDatePicker(
      context,
      initialDate: DateTime(form.date.year, form.date.month, form.date.day),
      lastDate: DateTime(form.today.year, form.today.month, form.today.day),
    );
    if (picked == null || !mounted) return;
    _controller.changeDate(LocalDate(picked.year, picked.month, picked.day));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final async = ref.watch(workoutLogControllerProvider(_launch));
    final library =
        ref.watch(exerciseLibraryProvider).value ?? ExerciseLibrary.empty;
    final prs = ref.watch(workoutPrsProvider).value;
    final form = async.value;
    if (form != null && !_named) {
      _named = true;
      _name.text = form.name;
    }
    final editing = _launch is EditLog;
    // The visit always has an exit path to run (its Undo, the zero-set
    // delete, pending writes): back and tab re-taps go through it (A45 D12).
    return UnsavedEditsGuard(
      dirty: !_ended,
      confirmDiscard: _exitVisit,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            editing ? l10n.workoutLogEditTitle : l10n.workoutLogNewTitle,
          ),
          actions: [
            if (form != null && (form.persisted || editing))
              FbIconButton(
                key: const ValueKey('workout-log-menu'),
                icon: FbIcons.more,
                tooltip: l10n.workoutLogMenu,
                onPressed: () => _menu(form),
              ),
          ],
        ),
        body: switch (async) {
          AsyncError() when form == null => FbEmptyState(
            icon: FbIcons.error,
            title: l10n.workoutLogEditTitle,
            message: l10n.workoutSessionGone,
          ),
          _ when form == null => const SizedBox.shrink(),
          _ => ListView(
            padding: const EdgeInsetsDirectional.all(FbSpace.s4),
            children: [
              if (form.saveState == LogSaveState.conflict) ...[
                FbInlineBanner(
                  key: const ValueKey('workout-conflict'),
                  kind: FbInlineBannerKind.info,
                  message: l10n.workoutConflict,
                  actionLabel: l10n.workoutConflictReload,
                  onAction: () => unawaited(_reload()),
                  actionBelow: true,
                ),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: FbButton.text(
                    key: const ValueKey('workout-conflict-keep'),
                    label: l10n.workoutConflictKeep,
                    onPressed: () => unawaited(_controller.keepMine()),
                  ),
                ),
                const SizedBox(height: FbSpace.s2),
              ],
              if (form.saveState == LogSaveState.failed) ...[
                FbInlineBanner(
                  key: const ValueKey('workout-save-failed'),
                  kind: FbInlineBannerKind.error,
                  message: l10n.workoutSaveFailed,
                  actionLabel: l10n.workoutSaveRetry,
                  onAction: () => unawaited(_controller.flush()),
                  actionBelow: true,
                ),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: FbButton.text(
                    key: const ValueKey('workout-save-discard'),
                    label: l10n.workoutSaveDiscard,
                    onPressed: () => unawaited(_discard()),
                  ),
                ),
                const SizedBox(height: FbSpace.s2),
              ],
              Semantics(
                label: l10n.workoutLogDate,
                child: FbListRow(
                  key: const ValueKey('workout-log-date'),
                  leading: const Icon(FbIcons.calendar),
                  title: dayLabel(context, form.date, form.today),
                  onTap: () => unawaited(_pickDate(form)),
                ),
              ),
              FbTextField(
                key: const ValueKey('workout-log-name'),
                controller: _name,
                label: l10n.workoutLogName,
                hint: l10n.sessionTitle(
                  SessionNaming.titleOf(
                    null,
                    library.namingOf(form.savedDraft?.exercises ?? const []),
                  ),
                ),
                maxLength: WorkoutLimits.nameMax,
                onChanged: _controller.rename,
              ),
              const SizedBox(height: FbSpace.s2),
              for (final (i, card) in form.exercises.indexed)
                ExerciseLogCard(
                  key: ValueKey(card.id),
                  card: card,
                  index: i,
                  count: form.exercises.length,
                  library: library,
                  controller: _controller,
                  prs: prs,
                ),
              FbButton.secondary(
                key: const ValueKey('workout-log-add-exercises'),
                label: l10n.workoutLogAddExercises,
                icon: FbIcons.add,
                expand: true,
                onPressed: () => unawaited(_addExercises()),
              ),
            ],
          ),
        },
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsetsDirectional.all(FbSpace.s4),
            child: FbButton.primary(
              key: const ValueKey('workout-log-done'),
              label: l10n.workoutLogDone,
              expand: true,
              onPressed: () => unawaited(_leave()),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _reload() async {
    await _controller.reload();
    if (!mounted) return;
    _name.text =
        ref.read(workoutLogControllerProvider(_launch)).value?.name ?? '';
  }
}
