import 'package:drift/drift.dart' show DatabaseConnectionUser;
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/changes/row_ops.dart';
import 'package:flutter/foundation.dart' show immutable;

/// What applying a change set gave (A01 D18): [Applied] or [Rejected].
/// Expected failures are values, never exceptions.
sealed class ApplyResult {
  const new _();
}

/// The change set committed.
final class Applied extends ApplyResult {
  /// The change set [changeSetId] committed; [inverse] undoes it and
  /// [events] were emitted after the commit, in that order.
  new({
    required this.changeSetId,
    required this.inverse,
    required Iterable<DomainEvent> events,
  }) : events = List.unmodifiable(events),
       super._();

  /// The ID the applier gave the change set (a UUIDv7).
  final String changeSetId;

  /// The change set that restores what this one changed (A01 D2, D3).
  final InverseChangeSet inverse;

  /// The events emitted after the commit (the ops' events, then
  /// [ChangeSetApplied]). Unmodifiable.
  final List<DomainEvent> events;

  /// The version row [id] of [table] (its SQL name) has after this change
  /// set, or `null` if it didn't write the row (A37 D9). Read from
  /// [inverse]: each of its rows expects the version this change set left.
  int? versionAfter(String table, String id) {
    for (final row in inverse.rows) {
      if (row.id != id || row.table.actualTableName != table) continue;
      return switch (row) {
        RestoreRow(:final expectedVersion) => expectedVersion,
        TombstoneRow(:final expectedVersion) => expectedVersion,
        _ => null,
      };
    }
    return null;
  }

  @override
  String toString() => 'Applied($changeSetId)';
}

/// Nothing was written: the change set was rolled back.
final class Rejected extends ApplyResult {
  /// The change set was rejected because of [failure].
  const new(this.failure) : super._();

  /// Why.
  final ChangeFailure failure;

  @override
  String toString() => 'Rejected($failure)';
}

/// Why a change set was rejected (A01 D18). Carries entity names, row IDs,
/// versions and codes only, never row values (no user content in logs).
@immutable
sealed class ChangeFailure {
  const new _();
}

/// A row's version wasn't the one the op expected: it changed since it was
/// read (or, for an undo, since the change set it undoes).
final class VersionConflict extends ChangeFailure {
  /// Row [id] of [entity] is at version [actual], not [expected].
  const new({
    required this.entity,
    required this.id,
    required this.expected,
    required this.actual,
  }) : super._();

  /// The entity wire name.
  final String entity;

  /// The row.
  final String id;

  /// The version the op expected.
  final int expected;

  /// The row's version.
  final int actual;

  @override
  bool operator ==(Object other) =>
      other is VersionConflict &&
      other.entity == entity &&
      other.id == id &&
      other.expected == expected &&
      other.actual == actual;

  @override
  int get hashCode =>
      Object.hash(VersionConflict, entity, id, expected, actual);

  @override
  String toString() => 'VersionConflict($entity, $id, v$expected != v$actual)';
}

/// The op needs a live row that doesn't exist (or is a tombstone).
final class RowNotFound extends ChangeFailure {
  /// No live row [id] of [entity].
  const new({required this.entity, required this.id}) : super._();

  /// The entity wire name.
  final String entity;

  /// The row.
  final String id;

  @override
  bool operator ==(Object other) =>
      other is RowNotFound && other.entity == entity && other.id == id;

  @override
  int get hashCode => Object.hash(RowNotFound, entity, id);

  @override
  String toString() => 'RowNotFound($entity, $id)';
}

/// The op or its row writes are malformed (a programming error, or a stale
/// proposal): no handler for its family, a write to a table that doesn't
/// sync, a handler writing sync metadata, …. [code] names which.
final class InvalidOp extends ChangeFailure {
  /// The op is invalid for the reason [code] (camelCase, no values).
  const new(this.code) : super._();

  /// The reason, like `unknownFamily`.
  final String code;

  @override
  bool operator ==(Object other) => other is InvalidOp && other.code == code;

  @override
  int get hashCode => Object.hash(InvalidOp, code);

  @override
  String toString() => 'InvalidOp($code)';
}

/// The database refused a write: a duplicate ID or a constraint of the
/// table. [code] names which.
final class ConstraintViolation extends ChangeFailure {
  /// A constraint failed, of the kind [code] (`duplicateId`, `unique`,
  /// `notNull`, `check`, `foreignKey`, `primaryKey`, `constraint`).
  const new(this.code) : super._();

  /// The kind of constraint.
  final String code;

  @override
  bool operator ==(Object other) =>
      other is ConstraintViolation && other.code == code;

  @override
  int get hashCode => Object.hash(ConstraintViolation, code);

  @override
  String toString() => 'ConstraintViolation($code)';
}

/// Thrown inside a change set's transaction to reject it with [failure]:
/// the applier rolls back and returns [Rejected]. Op handlers throw it too
/// (a referenced row is missing, an op makes no sense in the current
/// state).
final class ChangeRejected implements Exception {
  /// Reject the change set because of [failure].
  const new(this.failure);

  /// Why.
  final ChangeFailure failure;

  @override
  String toString() => 'ChangeRejected($failure)';
}

/// The database failed a change set's write for a reason other than a
/// constraint (disk full, I/O, a corrupt file, …): thrown by the applier,
/// after the rollback. Carries SQLite's extended result code only, never the
/// statement or its values (no user content in logs).
final class DatabaseWriteException implements Exception {
  /// SQLite failed with [extendedResultCode]; `debugCause` is the original
  /// error, kept in debug builds only.
  new(this.extendedResultCode, {Object? debugCause}) {
    assert(() {
      _debugCause = debugCause;
      return true;
    }(), 'keeps the cause in debug builds only');
  }

  /// SQLite's extended result code, like 13 (`SQLITE_FULL`).
  final int extendedResultCode;

  /// The original error, for the debugger: `null` in release builds. It
  /// quotes the row values, so it's never part of [toString].
  Object? get debugCause => _debugCause;
  Object? _debugCause;

  @override
  String toString() => 'DatabaseWriteException(sqlite $extendedResultCode)';
}

/// A read-only precondition, checked inside the undo transaction before writes.
/// Throw [ChangeRejected] when a semantic invariant changed without a row edit.
typedef RevertGuard = Future<void> Function(
  DatabaseConnectionUser db,
  List<RowOp> inverseRows,
);

/// The change set that undoes the change set [changeSetId] (A01 D2, D3):
/// its row writes, in apply order (the original's in reverse), and the
/// events to emit when it's applied.
///
/// Made only by the applier; applied with `ChangeSetApplier.revert`, with
/// the origin `undo:<changeSetId>`.
final class InverseChangeSet {
  /// The inverse of [changeSetId]: [rows] then [events].
  new({
    required this.changeSetId,
    required Iterable<RowOp> rows,
    Iterable<DomainEvent> events = const [],
    Iterable<RevertGuard> guards = const [],
  }) : guards = List.unmodifiable(guards),
       rows = List.unmodifiable(rows),
       events = List.unmodifiable(events);

  /// The change set this undoes.
  final String changeSetId;

  /// The row writes. Unmodifiable.
  final List<RowOp> rows;

  /// The events the handlers asked for on revert (`OpPlan.revertEvents`).
  /// Unmodifiable.
  final List<DomainEvent> events;

  /// Transactional preconditions supplied by the handlers.
  final List<RevertGuard> guards;

  /// Whether reverting writes nothing.
  bool get isEmpty => rows.isEmpty;

  @override
  String toString() => 'InverseChangeSet($changeSetId, ${rows.length} rows)';
}
