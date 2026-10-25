import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/core/ids/id_generator.dart';
import 'package:fb_mobile/core/undo/undo_stack.dart';
import 'package:fb_mobile/features/diary/application/diary_actions.dart';
import 'package:fb_mobile/features/diary/data/diary_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'slot_actions.g.dart';

/// Structured undo label kind, localized by presentation.
enum SlotKind {
  /// Custom meal added.
  slotAdded,

  /// Meal fields changed.
  slotUpdated,

  /// Full order changed.
  slotsReordered,

  /// Source deactivated, contents optionally moved.
  slotRemoved,
}

/// Refusal category; invalid codes are carried separately.
enum SlotFailure {
  /// Observed source or version changed.
  changed,

  /// Source no longer usable.
  removed,

  /// Input or destination invalid.
  invalid,
}

/// No display text in command results.
sealed class SlotOutcome {
  const new();
}

/// Successful command with a recorded undo handle.
final class SlotDone extends SlotOutcome {
  /// Same kind and arguments used by UndoStack.
  const new(this.undoEntryId, this.kind, this.args);

  /// Undo identity.
  final String undoEntryId;

  /// Structured label kind.
  final SlotKind kind;

  /// Private presentation arguments; never logged.
  final Map<String, Object> args;
}

/// No rows changed, including a duplicate pending command.
final class SlotUnchanged extends SlotOutcome {
  /// No effective action.
  const new();
}

/// Typed refusal; callers keep their input and rendered guards.
final class SlotFailed extends SlotOutcome {
  /// Content-free category and optional validation code.
  const new(this.reason, {this.code});

  /// Refusal category.
  final SlotFailure reason;

  /// Handler validation reason.
  final String? code;
}

/// Session-lived commands with reactive per-slot pending identities.
@Riverpod(keepAlive: true)
class SlotActions extends _$SlotActions {
  @override
  Set<String> build() => const {};

  /// Add using a caller-generated UUID and normalized name.
  Future<SlotOutcome> addSlot(String name, {TimeWindow? window}) {
    if (!MealSlotRules.validName(MealSlotRules.normalizeName(name))) {
      return Future.value(
        const SlotFailed(SlotFailure.invalid, code: 'nameInvalid'),
      );
    }
    final id = ref.read(idGeneratorProvider).next();
    return _run(
      AddMealSlot(id, name, window: window),
      [id],
      SlotKind.slotAdded,
      {'name': MealSlotRules.normalizeName(name)},
    );
  }

  /// Save against the version rendered by the editor.
  Future<SlotOutcome> updateSlot(SlotRecord record, MealSlotPatch patch) =>
      _run(
        UpdateMealSlot(record.slot.id, record.version, patch),
        [record.slot.id],
        SlotKind.slotUpdated,
        {'slotId': record.slot.id, 'slot': record.slot},
      );

  /// Full observed set in its dropped order.
  Future<SlotOutcome> reorder(List<SlotRecord> records) => _run(
    ReorderMealSlots(records.map((r) => r.versionedId)),
    records.map((r) => r.slot.id),
    SlotKind.slotsReordered,
    const {},
  );

  /// Remove exactly the shown source into exactly the shown destination.
  Future<SlotOutcome> removeSlot(
    SlotRecord record, {
    required SlotContents shown,
    SlotRecord? moveTo,
  }) => _run(
    RemoveMealSlot(
      record.slot.id,
      record.version,
      expected: shown,
      moveTo: moveTo?.versionedId,
    ),
    [record.slot.id, if (moveTo != null) moveTo.slot.id],
    SlotKind.slotRemoved,
    {
      'slotId': record.slot.id,
      'slot': record.slot,
      'count': shown.entries.length,
      if (moveTo != null) ...{
        'target': moveTo.slot.id,
        'targetSlot': moveTo.slot,
      },
    },
  );

  SlotFailed _failure(ChangeFailure failure) => switch (failure) {
    VersionConflict() ||
    InvalidOp(code: 'sourceChanged') => const SlotFailed(SlotFailure.changed),
    RowNotFound() ||
    InvalidOp(code: 'inactiveSlot') => const SlotFailed(SlotFailure.removed),
    InvalidOp(:final code) => SlotFailed(SlotFailure.invalid, code: code),
    _ => const SlotFailed(SlotFailure.invalid),
  };

  Future<SlotOutcome> _run(
    MealSlotOp op,
    Iterable<String> identities,
    SlotKind kind,
    Map<String, Object> args,
  ) async {
    final ids = identities.toSet();
    if (ids.any(state.contains)) return const SlotUnchanged();
    state = Set.unmodifiable({...state, ...ids});
    try {
      final ApplyResult result;
      try {
        result = await ref.read(diaryApplyProvider)(
          ChangeSet([op], origin: Origin.direct),
        );
      } on ChangeRejected catch (rejection) {
        return _failure(rejection.failure);
      }
      if (result is Rejected) return _failure(result.failure);
      final applied = result as Applied;
      if (applied.inverse.isEmpty) return const SlotUnchanged();
      final undo = ref
          .read(undoStackProvider)
          .record(applied, UndoLabel(kind.name, args: args));
      return SlotDone(undo.id, kind, Map.unmodifiable(args));
    } finally {
      state = Set.unmodifiable(state.difference(ids));
    }
  }
}
