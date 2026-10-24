import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/core/undo/undo_stack.dart';

/// Content-free reasons presentation can explain.
enum PersonalFoodFailure {
  /// The observed row version changed.
  changed,

  /// The source row is no longer live.
  removed,

  /// The input or operation was refused.
  invalid,

  /// The merged collections exceed their bounds.
  tooMany,

  /// The two foods use different nutrient bases.
  basisMismatch,
}

/// Direct action label keys.
enum PersonalFoodKind {
  /// A personal definition was saved.
  personalFoodSaved,

  /// A personal definition was deleted.
  personalFoodDeleted,

  /// Two personal definitions were merged.
  personalFoodsMerged,
}

/// Every refusal is a value; unexpected storage/programming errors propagate.
sealed class PersonalFoodOutcome {
  const new();
}

/// Successful write and its undo label arguments (never logged).
final class PersonalFoodDone extends PersonalFoodOutcome {
  /// Creates this structured value.
  const new(this.undoId, this.kind, this.args, {this.foodId});

  /// Undo-stack identity of the successful direct action.
  final String undoId;

  /// Typed undo label kind.
  final PersonalFoodKind kind;

  /// Presentation placeholders; never logged.
  final Map<String, Object> args;

  /// Resulting food identity for opening its amount sheet.
  final String? foodId;
}

/// No writes: nothing differs from what is stored.
final class PersonalFoodUnchanged extends PersonalFoodOutcome {
  /// Creates this structured value.
  const new();
}

/// No writes: the same food already has an action in flight (a duplicate
/// tap). Its outcome comes from that first action.
final class PersonalFoodPending extends PersonalFoodOutcome {
  /// Creates this structured value.
  const new();
}

/// An expected refusal with no partial write.
final class PersonalFoodFailed extends PersonalFoodOutcome {
  /// Creates this structured value.
  const new(this.reason);

  /// Content-free reason nothing was written.
  final PersonalFoodFailure reason;
}

/// Application commands use only the single writer, including atomic merges.
final class PersonalFoodActions {
  /// Creates this structured value.
  new({required this.apply, required this.undoStack, required this.ids});

  /// The single-writer application port.
  final Future<ApplyResult> Function(ChangeSet) apply;

  /// Direct action undo history.
  final UndoStack undoStack;

  /// ID source for newly created definitions.
  final IdGenerator ids;
  final Set<String> _pending = {};

  /// Creates one validated definition with Undo.
  Future<PersonalFoodOutcome> create(PersonalFoodDraft draft) {
    if (draft.validate() != null) {
      return Future.value(
        const PersonalFoodFailed(PersonalFoodFailure.invalid),
      );
    }
    final id = ids.next();
    return _run(
      {'create'},
      [CreatePersonalFood(id, draft)],
      PersonalFoodKind.personalFoodSaved,
      {'name': draft.names.en},
      foodId: id,
    );
  }

  /// Updates the observed version, preserving no-op saves.
  Future<PersonalFoodOutcome> update(
    PersonalFood food,
    PersonalFoodDraft draft,
  ) {
    final newValues = draft.per100 != food.per100 || draft.basis != food.basis;
    if ((newValues ? draft.validate() : draft.validateWire()) != null) {
      return Future.value(
        const PersonalFoodFailed(PersonalFoodFailure.invalid),
      );
    }
    if (draft == food.draft) return Future.value(const PersonalFoodUnchanged());
    return _run(
      {food.id},
      [UpdatePersonalFood(food.id, food.version, draft)],
      PersonalFoodKind.personalFoodSaved,
      {'name': draft.names.en},
      foodId: food.id,
    );
  }

  /// Deletes only the observed live definition.
  Future<PersonalFoodOutcome> delete(PersonalFood food) => _run(
    {food.id},
    [DeletePersonalFood(VersionedId(food.id, food.version))],
    PersonalFoodKind.personalFoodDeleted,
    {'name': food.names.en},
  );

  /// Merges and relinks both families in one atomic change set.
  Future<PersonalFoodOutcome> merge(
    PersonalFood survivor,
    PersonalFood merged,
  ) {
    if (survivor.id == merged.id) {
      return Future.value(
        const PersonalFoodFailed(PersonalFoodFailure.invalid),
      );
    }
    return _run(
      {survivor.id, merged.id},
      [
        MergePersonalFoods(
          survivor: VersionedId(survivor.id, survivor.version),
          merged: VersionedId(merged.id, merged.version),
        ),
        RelinkFoodRefs(
          from: FoodRef.personal(merged.id),
          to: FoodRef.personal(survivor.id),
        ),
      ],
      PersonalFoodKind.personalFoodsMerged,
      {'merged': merged.names.en, 'survivor': survivor.names.en},
      foodId: survivor.id,
    );
  }

  PersonalFoodFailed _failure(ChangeFailure failure) =>
      PersonalFoodFailed(switch (failure) {
        VersionConflict() => PersonalFoodFailure.changed,
        RowNotFound() => PersonalFoodFailure.removed,
        InvalidOp(code: 'tooMany') => PersonalFoodFailure.tooMany,
        InvalidOp(code: 'basisMismatch') => PersonalFoodFailure.basisMismatch,
        _ => PersonalFoodFailure.invalid,
      });

  Future<PersonalFoodOutcome> _run(
    Set<String> keys,
    List<ChangeOp> ops,
    PersonalFoodKind kind,
    Map<String, Object> args, {
    String? foodId,
  }) async {
    if (keys.any(_pending.contains)) return const PersonalFoodPending();
    _pending.addAll(keys);
    try {
      final ApplyResult result;
      try {
        result = await apply(ChangeSet(ops, origin: Origin.direct));
      } on ChangeRejected catch (rejection) {
        return _failure(rejection.failure);
      }
      if (result is Rejected) return _failure(result.failure);
      final applied = result as Applied;
      if (applied.inverse.isEmpty) return const PersonalFoodUnchanged();
      final undo = undoStack.record(applied, UndoLabel(kind.name, args: args));
      return PersonalFoodDone(
        undo.id,
        kind,
        Map.unmodifiable(args),
        foodId: foodId,
      );
    } finally {
      _pending.removeAll(keys);
    }
  }
}
