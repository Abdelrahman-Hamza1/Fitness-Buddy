import 'package:drift/drift.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/core/changes/row_ops.dart';
import 'package:fb_mobile/core/db/tables/sync_columns.dart';
import 'package:fb_mobile/core/db/write_guarded.dart';

/// Makes the op handlers over [db], one per op family: the applier calls it
/// with its own database, so a handler can't be bound to another one.
/// Composed by `app/app_scope.dart`; the handlers it makes are stateless
/// and capture no `Ref`.
typedef OpHandlerFactory<D extends WriteGuarded> =
    List<ChangeOpHandler<ChangeOp>> Function(D db);

/// Turns the ops of one family into row writes (A01 D1). One per op family,
/// made for the applier's database by an [OpHandlerFactory].
///
/// [plan] runs inside the change set's transaction: what it reads through
/// [TxReader] (or its own queries) is the current state, including the
/// writes of earlier ops in the same change set (see `RowWriteSession`), but
/// not its own plan's rows, which are written only after it returns. It must
/// not write (the write guard rejects it); it returns the writes as an
/// [OpPlan]. To reject the change set it throws [ChangeRejected].
abstract class ChangeOpHandler<O extends ChangeOp> {
  /// A handler.
  const new();

  /// The [ChangeOp.family] it handles.
  String get family;

  /// The row writes and events of [op].
  Future<OpPlan> plan(O op, TxReader tx, ApplyContext context);

  /// [plan] for an op of any type: an op of [family] that isn't an [O] is
  /// rejected with `InvalidOp('opType')`.
  Future<OpPlan> planOp(ChangeOp op, TxReader tx, ApplyContext context) =>
      op is O
      ? plan(op, tx, context)
      : throw const ChangeRejected(InvalidOp('opType'));
}

/// What one op does: its row writes, in order, and the events to emit after
/// the commit.
final class OpPlan {
  /// [rows] then [events]. [revertEvents] are emitted when the change set
  /// is undone (default none: undo emits only `ChangeSetApplied`).
  new(
    Iterable<RowOp> rows, {
    Iterable<DomainEvent> events = const [],
    Iterable<DomainEvent> revertEvents = const [],
  }) : rows = List.unmodifiable(rows),
       events = List.unmodifiable(events),
       revertEvents = List.unmodifiable(revertEvents);

  /// The row writes, in order. Unmodifiable.
  final List<RowOp> rows;

  /// Emitted after the commit, in order. Unmodifiable.
  final List<DomainEvent> events;

  /// Emitted after an undo of the change set commits. Unmodifiable.
  final List<DomainEvent> revertEvents;
}

/// What a handler knows about the change set being applied.
final class ApplyContext {
  /// The context of change set [changeSetId] from [origin], applied at
  /// [nowUtc] by [clock], with new row IDs from [ids].
  new({
    required this.changeSetId,
    required this.origin,
    required this.nowUtc,
    required this.clock,
    required this.ids,
  });

  /// The ID of the change set being applied.
  final String changeSetId;

  /// Who caused it.
  final Origin origin;

  /// When it's applied (one instant for the whole change set), UTC.
  final DateTime nowUtc;

  /// The clock, for zone offsets.
  final Clock clock;

  /// Where new row IDs (UUIDv7) come from.
  final IdGenerator ids;

  /// The device's local date at [nowUtc] (the diary day, DY-001).
  LocalDate get today => localDateOf(nowUtc, clock.offsetMinutesAt(nowUtc));
}

/// Reads in the change set's transaction, for handlers (tombstones
/// included).
final class TxReader {
  /// Reads through [db] (the caller is in the transaction's zone).
  new(this.db);

  /// The database, for the handler's own reads. Writes through it are
  /// rejected by the write guard.
  final DatabaseConnectionUser db;

  /// Row [id] of [table], tombstone or not, or `null`.
  Future<D?> row<T extends Table, D>(TableInfo<T, D> table, String id) =>
      (db.select(
        table,
      )..where((_) => idColumnOf(table).equals(id))).getSingleOrNull();

  /// Row [id] of [table] if it's live (not a tombstone), or `null`.
  Future<D?> liveRow<T extends Table, D>(TableInfo<T, D> table, String id) =>
      (db.select(table)..where(
            (t) =>
                idColumnOf(table).equals(id) &
                (table.columnsByName['deleted_at']! as GeneratedColumn<int>)
                    .isNull(),
          ))
          .getSingleOrNull();

  /// The sync metadata of row [id] of [table], or `null`.
  Future<SyncMeta?> meta(TableInfo<Table, Object?> table, String id) async {
    final row = await db
        .customSelect(
          'SELECT ${syncColumnNames.join(', ')} '
          'FROM "${table.actualTableName}" WHERE id = ?',
          variables: [Variable.withString(id)],
          readsFrom: {table},
        )
        .getSingleOrNull();
    return row == null ? null : SyncMeta.fromSqlRow(row.data);
  }
}

/// The `id` column of a synced [table].
GeneratedColumn<String> idColumnOf(TableInfo<Table, Object?> table) =>
    table.columnsByName['id']! as GeneratedColumn<String>;
