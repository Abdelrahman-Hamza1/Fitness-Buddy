import 'package:drift/drift.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/core/changes/op_handler.dart';
import 'package:fb_mobile/core/changes/row_ops.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/db/tables/body_tables.dart';
import 'package:fb_mobile/features/body/data/weigh_in_mappers.dart';

/// Turns `WeighInOp`s into `weigh_ins` row writes, inside the applier's
/// transaction (A14 D3, D5, D6). Reads at most once per op. No custom
/// events: `ChangeSetApplied(entities: {'weighIn'})` tells subscribers.
///
/// Rejections: `RowNotFound` / `VersionConflict` for a row that is gone or
/// changed; `InvalidOp('invalidDraft')` for a draft outside the local-write
/// bounds, `InvalidOp('time')` for a time before 1970 (PA9),
/// `InvalidOp('future')` for a time more than 5 minutes after the apply
/// time, `InvalidOp('sourceChanged')` when a day's weigh-ins differ from the
/// ones a `ChooseTrendWeighIn` lists.
final class WeighInOpHandler extends ChangeOpHandler<WeighInOp> {
  /// Bound to the applier's database.
  const new(this.db);

  /// The profile database.
  final AppDatabase db;

  @override
  String get family => WeighInOp.familyName;

  @override
  Future<OpPlan> plan(WeighInOp op, TxReader tx, ApplyContext context) async =>
      switch (op) {
        CreateWeighIn(:final id, :final draft) => OpPlan([
          InsertRow(
            db.weighIns,
            _columns(draft, context).copyWith(id: Value(id)),
          ),
        ]),
        UpdateWeighIn() => await _update(op, tx, context),
        DeleteWeighIn(:final weighIn) => OpPlan([
          TombstoneRow(
            db.weighIns,
            weighIn.id,
            expectedVersion: weighIn.expectedVersion,
          ),
        ]),
        ChooseTrendWeighIn() => await _choose(op, tx),
      };

  Future<OpPlan> _update(
    UpdateWeighIn op,
    TxReader tx,
    ApplyContext context,
  ) async {
    final row = await tx.liveRow(db.weighIns, op.id);
    if (row == null) {
      throw ChangeRejected(RowNotFound(entity: weighInEntity, id: op.id));
    }
    if (row.version != op.expectedVersion) {
      throw ChangeRejected(
        VersionConflict(
          entity: weighInEntity,
          id: op.id,
          expected: op.expectedVersion,
          actual: row.version,
        ),
      );
    }
    if (_draftOf(row) == op.draft) return OpPlan(const []);
    var columns = _columns(op.draft, context);
    // A move to another day drops the day's trend choice (D3).
    if (row.preferredForDay && op.draft.localDate.toString() != row.localDate) {
      columns = columns.copyWith(preferredForDay: const Value(false));
    }
    return OpPlan([
      UpdateRow(
        db.weighIns,
        op.id,
        columns,
        expectedVersion: op.expectedVersion,
      ),
    ]);
  }

  Future<OpPlan> _choose(ChooseTrendWeighIn op, TxReader tx) async {
    final rows =
        await (tx.db.select(db.weighIns)..where(
              (t) =>
                  t.localDate.equals(op.day.toString()) & t.deletedAt.isNull(),
            ))
            .get();
    // Only the rows the app can read: the user never saw the others (the
    // lists leave them out) and the trend skips them.
    final readable = [
      for (final row in rows)
        if (_draftOf(row) != null) row,
    ];
    // Exactly the rows the user saw, at the versions shown (A08b rule).
    final live = {for (final row in readable) VersionedId(row.id, row.version)};
    if (live.length != op.dayWeighIns.length ||
        !live.containsAll(op.dayWeighIns)) {
      throw const ChangeRejected(InvalidOp('sourceChanged'));
    }
    return OpPlan([
      for (final row in readable)
        if (row.preferredForDay != (row.id == op.chosen?.id))
          UpdateRow(
            db.weighIns,
            row.id,
            WeighInsCompanion(preferredForDay: Value(row.id == op.chosen?.id)),
            expectedVersion: row.version,
          ),
    ]);
  }

  /// [draft]'s columns, or a rejection for a draft a local write can't save.
  WeighInsCompanion _columns(WeighInDraft draft, ApplyContext context) {
    switch (draft.validate()) {
      case null:
        break;
      case WeighInIssue.time:
        throw const ChangeRejected(InvalidOp('time'));
      case _:
        throw const ChangeRejected(InvalidOp('invalidDraft'));
    }
    if (draft.isInFuture(context.nowUtc)) {
      throw const ChangeRejected(InvalidOp('future'));
    }
    return weighInColumns(draft);
  }

  /// The stored content as a draft, or `null` for a row the domain can't
  /// read (any edit then counts as a change).
  WeighInDraft? _draftOf(WeighInRow row) {
    try {
      return weighInOf(row).draft;
    } on WeighInMappingError {
      return null;
    }
  }
}
