import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/core/changes/change_providers.dart';
import 'package:fb_mobile/core/ids/id_generator.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/core/undo/undo_stack.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'weigh_in_actions.g.dart';

/// The undo label kinds of weigh-in actions; presentation maps them to
/// text.
enum WeighInKind {
  /// A weigh-in was logged ("Weigh-in saved: 97.4 kg").
  weighInLogged,

  /// Past weigh-ins were added in one go ("12 weigh-ins added", A15b D17).
  weighInsLogged,

  /// A weigh-in was edited.
  weighInUpdated,

  /// A weigh-in was deleted.
  weighInDeleted,

  /// Only the day's trend choice changed (WB-003).
  weighInTrendChosen,
}

/// Why nothing was written. Content-free.
enum WeighInFailure {
  /// The weigh-in or its day changed since it was shown.
  changed,

  /// The weigh-in was deleted meanwhile.
  removed,

  /// The draft was refused (out of range, a bad note, before 1970).
  invalid,

  /// The measured time is in the future.
  future,
}

/// The day's trend choice a save applies with it (WB-003, A14 D3).
final class WeighInTrendPick {
  /// Use this weigh-in for its day ([useThis]) or not; [dayOthers] are the
  /// day's other live weigh-ins at the versions shown.
  new({required this.useThis, required Iterable<WeighIn> dayOthers})
    : dayOthers = List.unmodifiable(dayOthers);

  /// `true`: this weigh-in is the day's trend value. `false`: another one
  /// is (the one the rule would take among [dayOthers]).
  final bool useThis;

  /// The day's other live weigh-ins, as shown. Unmodifiable.
  final List<WeighIn> dayOthers;

  @override
  String toString() => 'WeighInTrendPick($useThis, ${dayOthers.length})';
}

/// What a weigh-in action did. No display text.
sealed class WeighInOutcome {
  const new();
}

/// Written; [undoId] undoes it.
final class WeighInDone extends WeighInOutcome {
  /// The undo handle, label [kind] and its [args].
  const new(this.undoId, this.kind, this.args);

  /// The undo entry's ID.
  final String undoId;

  /// What happened.
  final WeighInKind kind;

  /// Label placeholders (`value`: double, `unit`: MassUnit; `count`: int
  /// for [WeighInKind.weighInsLogged]); user content, never logged.
  final Map<String, Object> args;
}

/// Nothing to write: nothing differs from what is stored.
final class WeighInUnchanged extends WeighInOutcome {
  /// The one value.
  const new();
}

/// Nothing written: the same action is still in flight (a double tap). Its
/// outcome comes from the first one.
final class WeighInPending extends WeighInOutcome {
  /// The one value.
  const new();
}

/// Refused; nothing was written.
final class WeighInFailed extends WeighInOutcome {
  /// Why.
  const new(this.reason);

  /// The content-free reason.
  final WeighInFailure reason;
}

/// Weigh-in commands (A14 D5): every write is one change set through the
/// single writer, pushed to the undo stack as a direct action (UX-030).
/// Session-lived, so an action outlives the sheet that started it. The
/// state is the set of identities with an action in flight (`log` for a
/// new weigh-in, else the weigh-in's ID).
@Riverpod(keepAlive: true)
class WeighInActions extends _$WeighInActions {
  /// The pending key of a new weigh-in.
  static const String logKey = 'log';

  /// The pending key of a batch of past weigh-ins.
  static const String logManyKey = 'logMany';

  @override
  Set<String> build() => const {};

  /// Logs [draft] as a new weigh-in, with the day's trend choice [trend]
  /// in the same change set (the new row is listed at version 1, A14 PA6).
  Future<WeighInOutcome> log(WeighInDraft draft, {WeighInTrendPick? trend}) {
    if (_refusal(draft) case final failed?) return Future.value(failed);
    final id = ref.read(idGeneratorProvider).next();
    return _run(
      {logKey},
      [
        CreateWeighIn(id, draft),
        if (trend != null) _choose(draft.localDate, VersionedId(id, 1), trend),
      ],
      WeighInKind.weighInLogged,
      _args(draft.input),
    );
  }

  /// Logs [drafts] (the weight history's included rows, see
  /// `WeighInBatchCheck`) as new weigh-ins in **one** change set with one
  /// undo entry (A15b D17). Any refused draft refuses the whole batch and
  /// nothing is written. Throws an `ArgumentError` for none or more than
  /// `WeighInBatchCheck.maxRows`.
  Future<WeighInOutcome> logMany(List<WeighInDraft> drafts) {
    for (final draft in drafts) {
      if (_refusal(draft) case final failed?) return Future.value(failed);
    }
    final generator = ref.read(idGeneratorProvider);
    final ops = WeighInBatch.ops(drafts, [
      for (final _ in drafts) generator.next(),
    ]);
    return _run(
      {logManyKey},
      ops,
      WeighInKind.weighInsLogged,
      {'count': drafts.length},
    );
  }

  /// Saves [draft] over [weighIn] (at the version shown), with the trend
  /// choice [trend] for the draft's day. Only a changed trend choice is a
  /// [WeighInKind.weighInTrendChosen]; nothing changed is
  /// [WeighInUnchanged].
  Future<WeighInOutcome> update(
    WeighIn weighIn,
    WeighInDraft draft, {
    WeighInTrendPick? trend,
  }) {
    if (_refusal(draft) case final failed?) return Future.value(failed);
    final same = draft == weighIn.draft;
    if (same && trend == null) {
      return Future.value(const WeighInUnchanged());
    }
    // The update bumps the row's version once; the choice sees that write.
    final after = VersionedId(weighIn.id, weighIn.version + (same ? 0 : 1));
    return _run(
      {weighIn.id},
      [
        if (!same) UpdateWeighIn(weighIn.id, weighIn.version, draft),
        if (trend != null) _choose(draft.localDate, after, trend),
      ],
      same ? WeighInKind.weighInTrendChosen : WeighInKind.weighInUpdated,
      _args(draft.input),
    );
  }

  /// Deletes [weighIn] at the version shown (a tombstone; undo revives it).
  Future<WeighInOutcome> delete(WeighIn weighIn) => _run(
    {weighIn.id},
    [DeleteWeighIn(weighIn.versionedId)],
    WeighInKind.weighInDeleted,
    _args(weighIn.input),
  );

  WeighInFailed? _refusal(WeighInDraft draft) {
    if (draft.validate() != null) {
      return const WeighInFailed(WeighInFailure.invalid);
    }
    if (draft.isInFuture(ref.read(clockProvider).nowUtc())) {
      return const WeighInFailed(WeighInFailure.future);
    }
    return null;
  }

  /// The choice op: this weigh-in ([self], at its version after the save)
  /// or the one the rule takes among the others.
  static ChooseTrendWeighIn _choose(
    LocalDate day,
    VersionedId self,
    WeighInTrendPick trend,
  ) {
    final others = [for (final w in trend.dayOthers) w.versionedId];
    final chosen = trend.useThis || trend.dayOthers.isEmpty
        ? self
        : DayChoice.of(trend.dayOthers).single.versionedId;
    return ChooseTrendWeighIn(
      day,
      chosen: chosen,
      dayWeighIns: [...others, self],
    );
  }

  static Map<String, Object> _args(WeighInInput input) => {
    'value': input.value,
    'unit': input.unit,
  };

  static WeighInFailed _failure(ChangeFailure failure) =>
      WeighInFailed(switch (failure) {
        VersionConflict() ||
        InvalidOp(code: 'sourceChanged') => WeighInFailure.changed,
        RowNotFound() => WeighInFailure.removed,
        InvalidOp(code: 'future') => WeighInFailure.future,
        _ => WeighInFailure.invalid,
      });

  Future<WeighInOutcome> _run(
    Set<String> keys,
    List<ChangeOp> ops,
    WeighInKind kind,
    Map<String, Object> args,
  ) async {
    if (keys.any(state.contains)) return const WeighInPending();
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
      if (applied.inverse.isEmpty) return const WeighInUnchanged();
      final undo = ref
          .read(undoStackProvider)
          .record(applied, UndoLabel(kind.name, args: args));
      return WeighInDone(undo.id, kind, Map.unmodifiable(args));
    } finally {
      if (ref.mounted) state = Set.unmodifiable(state.difference(keys));
    }
  }
}
