import 'dart:async';

import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/core/changes/change_providers.dart';
import 'package:fb_mobile/core/ids/id_generator.dart';
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
  /// The selected destination is no longer usable.
  slotRemoved,

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

  /// Logged amount edited.
  amountChanged,

  /// Local time edited.
  timeChanged,

  /// Absolute nutrients edited.
  nutrientEdited,

  /// Source meal copied.
  mealCopied,

  /// Source meal saved.
  mealSaved,

  /// A day marked incomplete (DY-004).
  dayMarkedIncomplete,

  /// A day counted again (its incomplete mark removed).
  dayMarkedComplete,
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

/// Direct commands survive eviction of the originating day.
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

  /// Recomputes from the entry's own per-100, retaining overrides.
  Future<DiaryActionOutcome> changeAmount(DiaryEntry entry, Quantity input) {
    final amount = EntryAmounts.resolve(entry, input);
    if (amount == null) {
      return Future.value(const DiaryActionFailed(DiaryActionFailure.invalid));
    }
    if (amount == entry.amount) {
      return Future.value(const DiaryActionUnchanged());
    }
    return _command(
      [entry.id],
      UpdateDiaryEntry(entry.id, entry.version, EntryPatch(amount: amount)),
      DiaryActionKind.amountChanged,
      {'name': entry.food.names.en},
    );
  }

  /// Changes only local time; stored date, offset and explicit slot survive.
  Future<DiaryActionOutcome> changeTime(DiaryEntry entry, LocalTime time) {
    if (time == entry.time.localDateTime.time) {
      return Future.value(const DiaryActionUnchanged());
    }
    return _command(
      [entry.id],
      UpdateDiaryEntry(entry.id, entry.version, EntryPatch(localTime: time)),
      DiaryActionKind.timeChanged,
      {'name': entry.food.names.en},
    );
  }

  /// Absolute values for the shown amount, validated without display text.
  Future<DiaryActionOutcome> overrideNutrients(
    DiaryEntry entry,
    Map<NutrientField, double> values,
  ) {
    try {
      NutrientOverride.checkValues(values);
      // Domain constructors validate user input with ArgumentError.
      // ignore: avoid_catching_errors
    } on ArgumentError {
      return Future.value(const DiaryActionFailed(DiaryActionFailure.invalid));
    }
    if (entry.amount.amount <= 0) {
      return Future.value(const DiaryActionFailed(DiaryActionFailure.invalid));
    }
    if (entry.editedByUser &&
        values.entries.every(
          (e) =>
              entry.snapshot.valueOf(e.key) == StoragePrecision.round(e.value),
        )) {
      return Future.value(const DiaryActionUnchanged());
    }
    return _command(
      [entry.id],
      OverrideNutrients(entry.id, entry.version, values),
      DiaryActionKind.nutrientEdited,
      {'name': entry.food.names.en, 'field': values.keys.first},
    );
  }

  /// Marks [date] incomplete, or counts it again (DY-004 manual, A16 D11):
  /// one direct change set through the single writer, with Undo. A day
  /// already as asked writes nothing ([DiaryActionUnchanged]); a future day
  /// is refused by the handler ([DiaryActionFailure.invalid]).
  Future<DiaryActionOutcome> markDay(
    LocalDate date, {
    required bool incomplete,
  }) => _command(
    ['day:$date'],
    MarkDay(date, incomplete: incomplete),
    incomplete
        ? DiaryActionKind.dayMarkedIncomplete
        : DiaryActionKind.dayMarkedComplete,
    {'date': date},
  );

  List<DiaryEntry> _entries(SlotSection section) => [
    for (final item in section.items)
      ...switch (item) {
        EntryItem(:final entry) => [entry],
        GroupItem(:final members) => members,
      },
  ];

  /// Pins every shown entry and referenced live group (PA8).
  Future<DiaryActionOutcome> copyMeal(
    SlotSection section,
    LocalDate toDate, {
    String? toSlotId,
  }) {
    final entries = _entries(section);
    if (entries.isEmpty) {
      return Future.value(const DiaryActionFailed(DiaryActionFailure.invalid));
    }
    final date = entries.first.localDate;
    final slot = section.slot?.id;
    if (toDate == date && (toSlotId == null || toSlotId == slot)) {
      return Future.value(const DiaryActionUnchanged());
    }
    final expected = SourceVersions(
      entries: entries.map((e) => VersionedId(e.id, e.version)),
      groups: [
        for (final item in section.items)
          if (item is GroupItem) VersionedId(item.group.id, item.group.version),
      ],
    );
    final ids = ref.read(idGeneratorProvider);
    return _command(
      entries.map((e) => e.id),
      CopyMeal(
        slot == null
            ? MealSource.entries(entries.map((e) => e.id))
            : MealSource.slot(date, slot),
        toDate: toDate,
        toSlotId: toSlotId,
        expected: expected,
        copyIds: {
          for (final e in expected.entries) e.id: ids.next(),
          for (final group in expected.groups)
            if (slot != null || section.entryCopyGroupIds.contains(group.id))
              group.id: ids.next(),
        },
      ),
      DiaryActionKind.mealCopied,
      {'count': entries.length, 'toDate': toDate},
    );
  }

  /// Saves exactly the entries shown; saved items carry no groups.
  Future<DiaryActionOutcome> saveMeal(SlotSection section, String name) {
    final trimmed = name.trim();
    final entries = _entries(section);
    if (trimmed.isEmpty ||
        trimmed.length > 60 ||
        trimmed.contains('\u0000') ||
        entries.isEmpty) {
      return Future.value(const DiaryActionFailed(DiaryActionFailure.invalid));
    }
    return _command(
      entries.map((e) => e.id),
      SaveMeal(
        savedMealId: ref.read(idGeneratorProvider).next(),
        name: trimmed,
        source: MealSource.entries(entries.map((e) => e.id)),
        expected: SourceVersions(
          entries: entries.map((e) => VersionedId(e.id, e.version)),
        ),
      ),
      DiaryActionKind.mealSaved,
      {'name': trimmed},
    );
  }

  DiaryActionFailed _failure(ChangeFailure failure, DiaryActionKind kind) =>
      DiaryActionFailed(switch (failure) {
        InvalidOp(code: 'inactiveSlot' || 'unknownSlot') =>
          DiaryActionFailure.slotRemoved,
        VersionConflict() ||
        InvalidOp(code: 'sourceChanged') => DiaryActionFailure.changed,
        RowNotFound() =>
          kind == DiaryActionKind.mealCopied ||
                  kind == DiaryActionKind.mealSaved
              ? DiaryActionFailure.changed
              : DiaryActionFailure.removed,
        _ => DiaryActionFailure.invalid,
      });

  Future<DiaryActionOutcome> _command(
    Iterable<String> identities,
    DiaryOp op,
    DiaryActionKind kind,
    Map<String, Object> args,
  ) async {
    final ids = identities.toSet();
    if (ids.any(state.pending.contains)) return const DiaryActionUnchanged();
    state = DiaryActionsState(
      pending: {...state.pending, ...ids},
      hidden: state.hidden,
    );
    try {
      final apply = ref.read(diaryApplyProvider);
      final change = ChangeSet([op], origin: Origin.direct);
      final ApplyResult result;
      try {
        result = await apply(change);
      } on ChangeRejected catch (rejection) {
        return _failure(rejection.failure, kind);
      }
      if (result is Rejected) {
        return _failure(result.failure, kind);
      }
      final applied = result as Applied;
      if (applied.inverse.rows.isEmpty) return const DiaryActionUnchanged();
      final undo = ref
          .read(undoStackProvider)
          .record(applied, UndoLabel(kind.name, args: args));
      return DiaryActionDone(undo.id, kind, Map.unmodifiable(args));
    } finally {
      state = DiaryActionsState(
        pending: state.pending.difference(ids),
        hidden: state.hidden,
      );
    }
  }

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
      final kind = slot == null
          ? DiaryActionKind.entryDeleted
          : DiaryActionKind.entryMoved;
      final change = ChangeSet([
        if (slot == null)
          DeleteEntries([vid])
        else
          MoveEntries([vid], toSlotId: slot),
      ], origin: Origin.direct);
      final ApplyResult result;
      try {
        result = await apply(change);
      } on ChangeRejected catch (rejection) {
        return _failure(rejection.failure, kind);
      }
      if (result is Rejected) return _failure(result.failure, kind);
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
