import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/core/changes/change_providers.dart';
import 'package:fb_mobile/core/ids/id_generator.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/core/undo/undo_stack.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'measurement_actions.g.dart';

/// The undo label kinds of measurement actions; presentation maps them to
/// text.
enum MeasurementKindOfChange {
  /// An entry was logged.
  measurementLogged,

  /// An entry was edited.
  measurementUpdated,

  /// An entry was deleted.
  measurementDeleted,

  /// A custom type was added.
  measurementTypeCreated,

  /// A custom type was renamed.
  measurementTypeRenamed,

  /// A custom type and its entries were deleted.
  measurementTypeDeleted,
}

/// Why nothing was written. Content-free.
enum MeasurementFailure {
  /// The entry, the type or the type's entries changed since shown.
  changed,

  /// The entry or the type was deleted meanwhile.
  removed,

  /// The custom type is missing or deleted.
  unknownType,

  /// Another live type has this name (ignoring case).
  duplicateName,

  /// The measured time is in the future.
  future,

  /// The draft or name was refused (range, unit, before 1970, the type
  /// changed, an undo guard).
  invalid,
}

/// What a measurement action did. No display text.
sealed class MeasurementOutcome {
  const new();
}

/// Written; [undoId] undoes it. [id] is the row it wrote (a new entry or
/// type).
final class MeasurementDone extends MeasurementOutcome {
  /// The undo handle, label [kind] and the written row [id].
  const new(this.undoId, this.kind, this.id);

  /// The undo entry's ID.
  final String undoId;

  /// What happened.
  final MeasurementKindOfChange kind;

  /// The entry or type the action wrote.
  final String id;
}

/// Nothing to write: nothing differs from what is stored.
final class MeasurementUnchanged extends MeasurementOutcome {
  /// The one value.
  const new();
}

/// Nothing written: the same action is still in flight (a double tap).
final class MeasurementPending extends MeasurementOutcome {
  /// The one value.
  const new();
}

/// Refused; nothing was written.
final class MeasurementFailed extends MeasurementOutcome {
  /// Why.
  const new(this.reason);

  /// The content-free reason.
  final MeasurementFailure reason;
}

/// Measurement commands (A15b D15): every write is one change set through
/// the single writer, pushed to the undo stack as a direct action (UX-030).
/// Session-lived, so an action outlives the sheet that started it. The
/// state is the set of identities with an action in flight ([logKey] /
/// [createTypeKey] for new rows, else the row's ID).
@Riverpod(keepAlive: true)
class MeasurementActions extends _$MeasurementActions {
  /// The pending key of a new entry.
  static const String logKey = 'log';

  /// The pending key of a new custom type.
  static const String createTypeKey = 'createType';

  @override
  Set<String> build() => const {};

  /// Logs [draft] as a new entry.
  Future<MeasurementOutcome> log(MeasurementDraft draft) {
    if (_refusal(draft) case final failed?) return Future.value(failed);
    final id = ref.read(idGeneratorProvider).next();
    return _run(
      {logKey},
      [CreateMeasurement(id, draft)],
      MeasurementKindOfChange.measurementLogged,
      id,
    );
  }

  /// Saves [draft] over [measurement] (at the version shown). Nothing
  /// changed is [MeasurementUnchanged] and adds no undo entry (PA3).
  Future<MeasurementOutcome> update(
    Measurement measurement,
    MeasurementDraft draft,
  ) {
    if (draft == measurement.draft) {
      return Future.value(const MeasurementUnchanged());
    }
    if (_refusal(draft) case final failed?) return Future.value(failed);
    return _run(
      {measurement.id},
      [UpdateMeasurement(measurement.id, measurement.version, draft)],
      MeasurementKindOfChange.measurementUpdated,
      measurement.id,
    );
  }

  /// Deletes [measurement] at the version shown (undo revives it).
  Future<MeasurementOutcome> delete(Measurement measurement) => _run(
    {measurement.id},
    [DeleteMeasurement(measurement.versionedId)],
    MeasurementKindOfChange.measurementDeleted,
    measurement.id,
  );

  /// Adds a custom type named [name].
  Future<MeasurementOutcome> createType(String name) {
    final id = ref.read(idGeneratorProvider).next();
    return _run(
      {createTypeKey},
      [CreateMeasurementType(id, name)],
      MeasurementKindOfChange.measurementTypeCreated,
      id,
    );
  }

  /// Renames [type] (at the version shown) to [name].
  Future<MeasurementOutcome> renameType(MeasurementType type, String name) =>
      _run(
        {type.id},
        [RenameMeasurementType(type.id, type.version, name)],
        MeasurementKindOfChange.measurementTypeRenamed,
        type.id,
      );

  /// Deletes [type] with exactly its live [entries] as shown (undo revives
  /// them all).
  Future<MeasurementOutcome> deleteType(
    MeasurementType type,
    Iterable<Measurement> entries,
  ) => _run(
    {type.id},
    [
      DeleteMeasurementType(type.versionedId, [
        for (final m in entries) m.versionedId,
      ]),
    ],
    MeasurementKindOfChange.measurementTypeDeleted,
    type.id,
  );

  MeasurementFailed? _refusal(MeasurementDraft draft) {
    if (draft.validate() != null) {
      return const MeasurementFailed(MeasurementFailure.invalid);
    }
    if (draft.isInFuture(ref.read(clockProvider).nowUtc())) {
      return const MeasurementFailed(MeasurementFailure.future);
    }
    return null;
  }

  static MeasurementFailed _failure(ChangeFailure failure) =>
      MeasurementFailed(switch (failure) {
        VersionConflict() ||
        InvalidOp(code: 'sourceChanged') => MeasurementFailure.changed,
        RowNotFound() => MeasurementFailure.removed,
        InvalidOp(code: 'unknownType') => MeasurementFailure.unknownType,
        InvalidOp(code: 'duplicateName') => MeasurementFailure.duplicateName,
        InvalidOp(code: 'future') => MeasurementFailure.future,
        _ => MeasurementFailure.invalid,
      });

  Future<MeasurementOutcome> _run(
    Set<String> keys,
    List<ChangeOp> ops,
    MeasurementKindOfChange kind,
    String id,
  ) async {
    if (keys.any(state.contains)) return const MeasurementPending();
    state = Set.unmodifiable({...state, ...keys});
    try {
      final ApplyResult result;
      try {
        result = await ref
            .read(changeSetApplierProvider)
            .apply(ChangeSet(ops, origin: Origin.direct));
      } on ChangeRejected catch (rejection) {
        return _failure(rejection.failure);
      }
      if (result is Rejected) return _failure(result.failure);
      final applied = result as Applied;
      if (applied.inverse.isEmpty) return const MeasurementUnchanged();
      // The label carries no values or names (user content stays out of
      // the undo stack's labels); the snack bar has its own text.
      final undo = ref
          .read(undoStackProvider)
          .record(applied, UndoLabel(kind.name));
      return MeasurementDone(undo.id, kind, id);
    } finally {
      if (ref.mounted) state = Set.unmodifiable(state.difference(keys));
    }
  }
}
