import 'dart:async';

import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/core/changes/change_providers.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:flutter/foundation.dart' show immutable;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'undo_stack.g.dart';

/// What an undo entry says it undoes (A01 D17): a typed [key] plus [args],
/// which the presentation layer maps to ARB text (`entriesLogged` with
/// `count` → "3 entries logged"). Never logged: args may name user content.
@immutable
final class UndoLabel {
  /// The label [key] with [args].
  new(this.key, {Map<String, Object> args = const {}})
    : args = Map.unmodifiable(args);

  /// Which text, like `entriesLogged`.
  final String key;

  /// The text's placeholders, like `{'count': 3}`. Unmodifiable.
  final Map<String, Object> args;

  @override
  bool operator ==(Object other) =>
      other is UndoLabel &&
      other.key == key &&
      other.args.length == args.length &&
      args.entries.every((e) => other.args[e.key] == e.value);

  @override
  int get hashCode => Object.hash(
    key,
    Object.hashAllUnordered([
      for (final e in args.entries) Object.hash(e.key, e.value),
    ]),
  );

  @override
  String toString() => 'UndoLabel($key)';
}

/// One undoable change set (A01 D17), undone by its [inverse] or, for a
/// visit of several writes (A37 D9), by a [compensation]: a forward change
/// set whose ops carry the expected versions, so anything changed since is
/// a conflict and nothing is written.
@immutable
final class UndoEntry {
  /// The entry [id] (the change set's ID) for [inverse], applied at
  /// [appliedAt] (UTC).
  const new({
    required this.id,
    required this.label,
    required InverseChangeSet this.inverse,
    required this.appliedAt,
  }) : compensation = null;

  /// The entry [id] (the first change set of the visit) undone by applying
  /// [compensation], whose origin should be `undo:<id>`.
  const new compensating({
    required this.id,
    required this.label,
    required ChangeSet this.compensation,
    required this.appliedAt,
  }) : inverse = null;

  /// The applied change set's ID; [UndoStack.undo] takes it.
  final String id;

  /// What the snackbar says.
  final UndoLabel label;

  /// What undoes it by revert, or `null` for a compensation.
  final InverseChangeSet? inverse;

  /// What undoes it by apply, or `null` for an inverse.
  final ChangeSet? compensation;

  /// When it was applied, UTC; the undo window starts here.
  final DateTime appliedAt;

  @override
  String toString() => 'UndoEntry($id, $label)';
}

/// What [UndoStack.undo] did.
enum UndoOutcome {
  /// The change set was undone.
  undone,

  /// The undo window had passed; nothing was written.
  expired,

  /// A row changed since (or the undo failed otherwise); nothing was
  /// written. The UI says "can't undo" (A08).
  conflict,

  /// No such entry: never pushed, already undone, or pushed out by newer
  /// ones.
  unknown,
}

/// The recent direct actions that can still be undone (A01 D17, UX-030): at
/// most [capacity], each for [window] after it was applied (the snackbar's
/// 5 s plus 1 s of grace for the tap), on the injected [Clock].
///
/// Undo applies the inverse through `revert` (the applier), or a
/// compensation through `apply`; neither pushes an entry of its own: there
/// is no redo.
final class UndoStack {
  /// A stack that undoes with `revert` (`ChangeSetApplier.revert`) or, for
  /// compensating entries, `apply` (`ChangeSetApplier.apply`), and measures
  /// the window with `clock`.
  new({
    required this._revert,
    required this._clock,
    this._apply,
    this.window = undoWindow,
    this.capacity = 5,
  });

  /// The default [window]: 5 s (UX-030) + 1 s grace.
  static const Duration undoWindow = Duration(seconds: 6);

  /// How long an entry can be undone.
  final Duration window;

  /// How many entries it keeps.
  final int capacity;

  final Future<ApplyResult> Function(InverseChangeSet) _revert;
  final Future<ApplyResult> Function(ChangeSet)? _apply;
  final Clock _clock;

  /// Oldest first; may hold expired entries until they're pushed out.
  final List<UndoEntry> _entries = [];
  final StreamController<UndoEntry?> _latest =
      StreamController<UndoEntry?>.broadcast();
  UndoEntry? _lastLatest;
  Timer? _expiry;

  /// Adds [entry], dropping the oldest beyond [capacity].
  void push(UndoEntry entry) {
    _entries.add(entry);
    while (_entries.length > capacity) {
      _entries.removeAt(0);
    }
    _changed();
  }

  /// Pushes [applied] with [label], applied now.
  UndoEntry record(Applied applied, UndoLabel label) {
    final entry = UndoEntry(
      id: applied.changeSetId,
      label: label,
      inverse: applied.inverse,
      appliedAt: _clock.nowUtc(),
    );
    push(entry);
    return entry;
  }

  /// Pushes an entry [id] undone by [compensation] (A37 D9), applied now.
  UndoEntry recordCompensation(
    String id,
    UndoLabel label,
    ChangeSet compensation,
  ) {
    final entry = UndoEntry.compensating(
      id: id,
      label: label,
      compensation: compensation,
      appliedAt: _clock.nowUtc(),
    );
    push(entry);
    return entry;
  }

  /// The entries that can still be undone, newest first.
  List<UndoEntry> get entries => [
    for (final e in _entries.reversed)
      if (!_isExpired(e)) e,
  ];

  /// The newest entry, if it can still be undone.
  UndoEntry? get latest {
    if (_entries.isEmpty) return null;
    final newest = _entries.last;
    return _isExpired(newest) ? null : newest;
  }

  /// [latest] now and whenever it changes (a push, an undo, an expiry).
  Stream<UndoEntry?> watchLatest() => Stream.multi((listener) {
    listener.add(latest);
    final sub = _latest.stream.listen(listener.add);
    listener.onCancel = sub.cancel;
  });

  /// Undoes entry [entryId] (see [UndoOutcome]). The entry is gone after
  /// this, whatever the outcome.
  Future<UndoOutcome> undo(String entryId) async {
    final index = _entries.indexWhere((e) => e.id == entryId);
    if (index < 0) return UndoOutcome.unknown;
    final entry = _entries.removeAt(index);
    _changed();
    if (_isExpired(entry)) return UndoOutcome.expired;
    final result = switch (entry) {
      UndoEntry(:final inverse?) => await _revert(inverse),
      UndoEntry(:final compensation?) => await _applyCompensation(compensation),
      _ => throw StateError('an undo entry needs an inverse or a compensation'),
    };
    return switch (result) {
      Applied() => UndoOutcome.undone,
      Rejected() => UndoOutcome.conflict,
    };
  }

  Future<ApplyResult> _applyCompensation(ChangeSet compensation) {
    final apply = _apply;
    if (apply == null) {
      throw StateError('a compensating entry needs an apply callback');
    }
    return apply(compensation);
  }

  /// Stops the expiry timer and ends [watchLatest]'s streams.
  void dispose() {
    _expiry?.cancel();
    unawaited(_latest.close());
  }

  bool _isExpired(UndoEntry entry) =>
      _clock.nowUtc().difference(entry.appliedAt) >= window;

  /// Emits [latest] if it changed and schedules the next expiry check.
  void _changed() {
    _expiry?.cancel();
    final current = latest;
    if (!identical(current, _lastLatest)) {
      _lastLatest = current;
      if (!_latest.isClosed) _latest.add(current);
    }
    if (current != null) {
      final left = window - _clock.nowUtc().difference(current.appliedAt);
      _expiry = Timer(left, _changed);
    }
  }
}

/// The app's [UndoStack]. A02's snackbar undoes with
/// `ref.read(undoStackProvider).undo(entry.id)`.
@Riverpod(keepAlive: true)
UndoStack undoStack(Ref ref) {
  final applier = ref.watch(changeSetApplierProvider);
  final stack = UndoStack(
    revert: applier.revert,
    apply: applier.apply,
    clock: ref.watch(clockProvider),
  );
  ref.onDispose(stack.dispose);
  return stack;
}

/// The newest entry that can still be undone, `null` once it expires: what
/// the undo snackbar shows (A02, A08).
@riverpod
Stream<UndoEntry?> latestUndo(Ref ref) =>
    ref.watch(undoStackProvider).watchLatest();
