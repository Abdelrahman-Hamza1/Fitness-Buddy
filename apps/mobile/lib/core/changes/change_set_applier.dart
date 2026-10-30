import 'package:drift/drift.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/core/changes/op_handler.dart';
import 'package:fb_mobile/core/changes/row_ops.dart';
import 'package:fb_mobile/core/changes/write_gate.dart';
import 'package:fb_mobile/core/db/synced_tables.dart';
import 'package:fb_mobile/core/db/write/row_writer.dart';
import 'package:fb_mobile/core/db/write_guarded.dart';
import 'package:fb_mobile/core/events/domain_event_bus.dart';

/// The single writer of user data (A01, `03` §5.2): applies a [ChangeSet]
/// atomically and returns what undoes it.
///
/// For each change set, one after another (a serial queue, A01 D18): one
/// transaction in which each op's handler plans its row writes and the row
/// writer runs them (preconditions, sync metadata, an HLC per write, the
/// first snapshot of each row), then `sync_state['hlc.last']` (D10). The
/// writer batches the writes (see `RowWriteSession`). After the commit it
/// emits the ops' events and [ChangeSetApplied] on the [DomainEventBus]
/// (D4). Any failure rolls everything back and emits
/// nothing: expected ones come back as [Rejected] (D18), bugs as exceptions.
///
/// It doesn't push undo entries: the caller decides (direct actions do, A08).
final class ChangeSetApplier<D extends WriteGuarded> {
  /// An applier over [db] and its synced [tables], with the handlers
  /// [handlers] makes for [db] (one per op family), the `clock` and the
  /// `ids` for change sets and new rows. `deviceId` gives the install's ID
  /// (the HLC node ID, TD-053), awaited on the first apply. Throws an
  /// `ArgumentError` if two handlers have the same family.
  new({
    required D db,
    required Iterable<SyncedTable<Table, Object?>> tables,
    required OpHandlerFactory<D> handlers,
    required this._clock,
    required this._ids,
    required this._deviceId,
    required this._events,
    this._gate,
    this._profileKey,
    this._generation,
  }) : _db = db,
       _writer = RowWriter(db, tables) {
    for (final handler in handlers(db)) {
      if (_handlers.containsKey(handler.family)) {
        throw ArgumentError.value(
          handler.family,
          'handlers',
          'has two handlers for the family',
        );
      }
      _handlers[handler.family] = handler;
    }
  }

  final D _db;
  final RowWriter _writer;
  final Clock _clock;
  final IdGenerator _ids;
  final Future<String> Function() _deviceId;
  final DomainEventBus _events;

  /// A33 §6: account transitions, read-only kept copies and inactive
  /// profiles may not be written. Checked for apply and revert alike.
  final WriteGate? _gate;

  /// The registry-resolved profile the database belongs to (memoized by its
  /// location); `null` for a pinned location (an explicit switch, tests).
  final Future<String> Function()? _profileKey;

  /// The profile generation this applier was created for (A33 re-check 3).
  final int? _generation;
  final Map<String, ChangeOpHandler<ChangeOp>> _handlers = {};

  HybridLogicalClock? _hlc;
  Future<void> _tail = Future.value();

  /// Applies [changeSet]: all its ops, or none.
  Future<ApplyResult> apply(ChangeSet changeSet) => _serial(
    () => _transact(changeSet.origin, (writes, context) async {
      final reader = TxReader(_db);
      final events = <DomainEvent>[];
      final revertEvents = <DomainEvent>[];
      final revertGuards = <RevertGuard>[];
      for (final op in changeSet.ops) {
        try {
          final handler =
              _handlers[op.family] ??
              (throw const ChangeRejected(InvalidOp('unknownFamily')));
          final plan = await writes.planning(
            () => handler.planOp(op, reader, context),
          );
          for (final row in plan.rows) {
            if (row is RestoreRow) {
              throw const ChangeRejected(InvalidOp('restoreInPlan'));
            }
            writes.write(row);
          }
          events.addAll(plan.events);
          revertEvents.addAll(plan.revertEvents);
          revertGuards.addAll(plan.revertGuards);
        } on Object {
          // The writes queued before the failure run first, so a failure of
          // theirs wins, as if each had run when it was planned.
          await writes.flush();
          rethrow;
        }
      }
      return (events, revertEvents, revertGuards);
    }),
  );

  /// Applies [inverse], undoing its change set (A01 D3), with the origin
  /// `undo:<changeSetId>`. A row changed since gives
  /// [Rejected]([VersionConflict]) and nothing is written. An inverse holds
  /// only restores and tombstones (what [apply] makes): any other row write
  /// gives [Rejected]([InvalidOp]) `notInverse`. Semantic guards run read-only
  /// inside the same transaction before any inverse writes.
  Future<ApplyResult> revert(InverseChangeSet inverse) => _serial(
    () => _transact(Origin.undo(inverse.changeSetId), (writes, _) async {
      for (final guard in inverse.guards) {
        await writes.planning(() => guard(_db, inverse.rows));
      }
      for (final row in inverse.rows) {
        if (row is! RestoreRow && row is! TombstoneRow) {
          throw const ChangeRejected(InvalidOp('notInverse'));
        }
        writes.write(row);
      }
      return (inverse.events, const <DomainEvent>[], const <RevertGuard>[]);
    }),
  );

  /// Completes when every apply/revert queued so far has finished (A33 §6:
  /// a transition suspends writes, then waits for this before switching).
  Future<void> idle() => _tail;

  /// Runs [body] after every earlier call has finished.
  Future<T> _serial<T>(Future<T> Function() body) {
    final result = _tail.then((_) => body());
    _tail = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  Future<ApplyResult> _transact(
    Origin origin,
    Future<(List<DomainEvent>, List<DomainEvent>, List<RevertGuard>)> Function(
      RowWriteSession writes,
      ApplyContext context,
    )
    body,
  ) async {
    // Inside the serialized entry shared by apply and revert (A33 §6), so a
    // transition that suspends writes and then awaits [idle] can't race a
    // queued write.
    if (_gate case final gate?) {
      final profile = await _profileKey?.call();
      if (await gate.denial(profile, generation: _generation)
          case final reason?) {
        return Rejected(InvalidOp(reason));
      }
    }
    final hlc = _hlc ?? await _restoreHlc();
    final changeSetId = _ids.next();
    final now = _clock.nowUtc();
    final writes = _writer.session(
      hlc: hlc,
      origin: origin.toText(),
      nowMs: now.millisecondsSinceEpoch,
    );
    final context = ApplyContext(
      changeSetId: changeSetId,
      origin: origin,
      nowUtc: now,
      clock: _clock,
      ids: _ids,
    );
    final (List<DomainEvent>, List<DomainEvent>, List<RevertGuard>) planned;
    try {
      planned = await _db.transaction(() async {
        final result = await body(writes, context);
        await writes.finish();
        return result;
      });
    } on ChangeRejected catch (rejection) {
      return Rejected(rejection.failure);
    }
    if (writes.lastHlc != null) {
      // The outbox is written by triggers, which drift's stream invalidation
      // doesn't see.
      _db.notifyUpdates({const TableUpdate('sync_outbox')});
    }
    final (events, revertEvents, revertGuards) = planned;
    // After the commit, in op order (A01 D4).
    final emitted = [
      ...events,
      ChangeSetApplied(
        changeSetId: changeSetId,
        origin: origin,
        entities: writes.entities,
      ),
    ]..forEach(_events.emit);
    return Applied(
      changeSetId: changeSetId,
      inverse: InverseChangeSet(
        changeSetId: changeSetId,
        rows: writes.inverseRows(),
        events: revertEvents,
        guards: revertGuards,
      ),
      events: emitted,
    );
  }

  /// The HLC, continuing from `sync_state['hlc.last']` (A01 D10).
  Future<HybridLogicalClock> _restoreHlc() async {
    final deviceId = await _deviceId();
    final stored = await _db
        .customSelect("SELECT value FROM sync_state WHERE key = 'hlc.last'")
        .getSingleOrNull();
    final last = stored == null
        ? null
        : Hlc.tryParse(stored.read<String>('value'));
    return _hlc ??= HybridLogicalClock(
      clock: _clock,
      deviceId: deviceId,
      last: last,
    );
  }
}
