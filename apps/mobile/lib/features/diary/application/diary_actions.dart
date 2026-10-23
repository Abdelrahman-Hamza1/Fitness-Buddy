import 'dart:async';

import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/core/changes/change_providers.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/core/undo/undo_stack.dart';
import 'package:fb_mobile/features/diary/data/diary_day.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'diary_actions.g.dart';

/// Existing single-writer port, injectable for command-race tests.
@Riverpod(keepAlive: true)
Future<ApplyResult> Function(ChangeSet) diaryApply(Ref ref) =>
    ref.watch(changeSetApplierProvider).apply;

/// A dismissed version, owned by the originating day (PA4).
typedef HiddenMark = ({
  String id,
  int version,
  LocalDate originDate,
  DateTime at,
});

/// Typed command failures; presentation owns text.
enum DiaryActionFailure {
  /// The rendered version is stale.
  changed,

  /// The entry was deleted elsewhere.
  removed,

  /// The operation was invalid.
  invalid,
}

/// The completed command kind.
enum DiaryActionKind {
  /// Entry dismissed from the diary.
  entryDeleted,

  /// Entry placed in another slot.
  entryMoved,
}

/// Command result without display text.
sealed class DiaryActionOutcome {
  const new();
}

/// Successful direct action and its Undo handle.
final class DiaryActionDone extends DiaryActionOutcome {
  /// Carries the same structured label recorded in UndoStack.
  const new(this.undoEntryId, this.kind, this.args);

  /// Undo identity.
  final String undoEntryId;

  /// Label kind.
  final DiaryActionKind kind;

  /// Presentation placeholders; never logged.
  final Map<String, Object> args;
}

/// No write, including a duplicate pending command.
final class DiaryActionUnchanged extends DiaryActionOutcome {
  /// No command was applied.
  const new();
}

/// Expected rejection; the last rendered version is never retried.
final class DiaryActionFailed extends DiaryActionOutcome {
  /// Typed rejection reason.
  const new(this.reason);

  /// Why nothing was written.
  final DiaryActionFailure reason;
}

/// Session-owned action state, independent of day-provider lifetimes.
final class DiaryActionsState {
  /// Immutable collections for reactive consumers.
  new({
    Iterable<String> pending = const [],
    Iterable<HiddenMark> hidden = const [],
  }) : pending = Set.unmodifiable(pending),
       hidden = Set.unmodifiable(hidden);

  /// Entries with an in-flight command.
  final Set<String> pending;

  /// Optimistically hidden versions only.
  final Set<HiddenMark> hidden;
}

/// Calls existing A06 ops only; survives eviction of the originating day.
@Riverpod(keepAlive: true)
class DiaryActionsController extends _$DiaryActionsController {
  Timer? _sweep;

  @override
  DiaryActionsState build() {
    ref.onDispose(() => _sweep?.cancel());
    return DiaryActionsState();
  }

  // A single timer avoids retaining a disposal callback for every swipe.
  void _scheduleSweep() {
    _sweep?.cancel();
    if (state.hidden.isEmpty) return;
    final lifetime =
        ref.read(undoStackProvider).window + const Duration(seconds: 10);
    final clock = ref.read(clockProvider);
    final oldest = state.hidden
        .map((m) => m.at)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    final delay = oldest.add(lifetime).difference(clock.nowUtc());
    _sweep = Timer(delay.isNegative ? Duration.zero : delay, () {
      state = DiaryActionsState(
        pending: state.pending,
        hidden: state.hidden.where(
          (m) => clock.nowUtc().difference(m.at) < lifetime,
        ),
      );
      _scheduleSweep();
    });
  }

  /// Only a raw origin-day emission proves that a hidden version is gone.
  void onRaw(LocalDate date, DiaryDay raw) {
    final remaining = state.hidden
        .where(
          (mark) =>
              mark.originDate != date ||
              raw.entries.any(
                (e) => e.id == mark.id && e.version == mark.version,
              ),
        )
        .toSet();
    if (remaining.length != state.hidden.length) {
      state = DiaryActionsState(pending: state.pending, hidden: remaining);
      _scheduleSweep();
    }
  }

  /// Dismisses immediately, but only the applier deletes user data.
  Future<DiaryActionOutcome> deleteEntry(DiaryEntry entry) => _run(entry, null);

  /// Selecting the current slot is a no-op.
  Future<DiaryActionOutcome> moveEntry(DiaryEntry entry, String toSlotId) =>
      toSlotId == entry.slotId
      ? Future.value(const DiaryActionUnchanged())
      : _run(entry, toSlotId);

  Future<DiaryActionOutcome> _run(DiaryEntry entry, String? slot) async {
    if (state.pending.contains(entry.id)) return const DiaryActionUnchanged();
    final clock = ref.read(clockProvider);
    final undo = ref.read(undoStackProvider);
    final apply = ref.read(diaryApplyProvider);
    final mark = (
      id: entry.id,
      version: entry.version,
      originDate: entry.localDate,
      at: clock.nowUtc(),
    );
    state = DiaryActionsState(
      pending: {...state.pending, entry.id},
      hidden: {...state.hidden, if (slot == null) mark},
    );
    _scheduleSweep();
    var succeeded = false;
    try {
      final vid = VersionedId(entry.id, entry.version);
      final result = await apply(
        ChangeSet([
          if (slot == null)
            DeleteEntries([vid])
          else
            MoveEntries([vid], toSlotId: slot),
        ], origin: Origin.direct),
      );
      if (result is Rejected) {
        return DiaryActionFailed(switch (result.failure) {
          VersionConflict() => DiaryActionFailure.changed,
          RowNotFound() => DiaryActionFailure.removed,
          _ => DiaryActionFailure.invalid,
        });
      }
      final kind = slot == null
          ? DiaryActionKind.entryDeleted
          : DiaryActionKind.entryMoved;
      final args = <String, Object>{
        'name': entry.food.names.en,
        'slotId': ?slot,
      };
      final recorded = undo.record(
        result as Applied,
        UndoLabel(kind.name, args: args),
      );
      succeeded = true;
      return DiaryActionDone(recorded.id, kind, Map.unmodifiable(args));
    } finally {
      state = DiaryActionsState(
        pending: state.pending.where((id) => id != entry.id),
        hidden: succeeded ? state.hidden : state.hidden.where((m) => m != mark),
      );
      _scheduleSweep();
    }
  }
}
