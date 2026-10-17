import 'dart:async';

import 'package:drift/drift.dart';

/// The zone key that marks an authorized write scope. Library-private: only
/// [runAuthorizedWrite] can set it.
final Object _writeToken = Object();

/// Runs [body] in a scope where [WriteGuard] lets writes through.
///
/// Only the single writer may call this (A01 D11): the row writer
/// (`core/db/write/`), the database's own catalog attach, the seed helper
/// and, from A34, sync's remote apply (also in `core/db/`).
/// `tools/app_check` keeps everything else out (A01 D12). drift's
/// `transaction()` forks the zone it's called in, so a transaction started
/// inside [body] stays authorized, and one started outside stays guarded
/// even if [body] runs inside it.
Future<T> runAuthorizedWrite<T>(Future<T> Function() body) =>
    runZoned(body, zoneValues: {_writeToken: true});

/// Whether the current zone is inside [runAuthorizedWrite].
bool get isWriteAuthorized => Zone.current[_writeToken] == true;

/// The zone key of the read barrier of [runWithReadBarrier].
final Object _readBarrierKey = Object();

/// Runs [body] so that each read it makes through a [WriteGuard]ed database
/// first awaits [barrier] (why: `RowWriteSession`). [barrier] itself runs
/// outside the barrier (its own reads don't wait on it).
Future<T> runWithReadBarrier<T>(
  Future<void> Function() barrier,
  Future<T> Function() body,
) => runZoned(body, zoneValues: {_readBarrierKey: barrier});

/// Whether [sql] only reads: one `SELECT` or `VALUES` statement (or a
/// `WITH …` one that doesn't insert, update or delete), without
/// `RETURNING`. Comments, string literals and quoted names are ignored;
/// anything else (`PRAGMA`, several statements, …) counts as a write, so the
/// guard fails closed.
bool isReadOnlyStatement(String sql) {
  final code = sql.replaceAll(_literalsAndComments, ' ').toUpperCase();
  final words = _word.allMatches(code).map((m) => m[0]!).toList();
  if (words.isEmpty ||
      code.replaceFirst(_trailingSemicolon, '').contains(';')) {
    return false;
  }
  return switch (words.first) {
    'SELECT' || 'VALUES' => !words.contains('RETURNING'),
    // `replace(…)` is also a function; `REPLACE INTO` is the statement.
    'WITH' =>
      !words.any(_writeWords.contains) &&
          !_replaceInto.hasMatch(words.join(' ')),
    _ => false,
  };
}

final RegExp _literalsAndComments = RegExp(
  r"""'(?:[^']|'')*'|"(?:[^"]|"")*"|`(?:[^`]|``)*`|\[[^\]]*\]|--[^\n]*|/\*[\s\S]*?(?:\*/|$)""",
);
final RegExp _word = RegExp(r'[A-Z_][A-Z0-9_$]*');
final RegExp _trailingSemicolon = RegExp(r';\s*$');
final RegExp _replaceInto = RegExp(r'\bREPLACE INTO\b');
const Set<String> _writeWords = {'INSERT', 'UPDATE', 'DELETE', 'RETURNING'};

/// A write reached the database outside the single writer (A01 D11).
///
/// A programming error, thrown in debug and release alike. Carries only the
/// kind of statement, never its SQL or arguments (no user content in logs).
final class UnauthorizedWriteError extends Error {
  /// A [kind] write (`insert`, `update`, `delete`, `custom`, `batch`, or
  /// `select-write` for a write run as a query) was rejected.
  new(this.kind);

  /// The kind of statement that was rejected.
  final String kind;

  @override
  String toString() =>
      'UnauthorizedWriteError: a $kind statement ran outside the '
      'ChangeSetApplier (only core/db/write may write user data)';
}

/// The runtime half of "only the applier writes" (A01 D11): rejects every
/// write statement unless it runs inside [runAuthorizedWrite], including
/// writes run as queries (`RETURNING`, see [isReadOnlyStatement]). Reads are
/// never blocked; inside [runWithReadBarrier] they wait for its barrier.
///
/// Migrations and `beforeOpen` don't pass through it: drift runs them on the
/// inner executor it's opening (spike in A01 WP2, `test/core/db/`).
final class WriteGuard extends QueryInterceptor {
  /// The guard; stateless.
  new();

  Future<R> _check<R>(String kind, Future<R> Function() run) {
    if (!isWriteAuthorized) return Future.error(UnauthorizedWriteError(kind));
    return run();
  }

  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    // drift runs `insertReturning`, `writeReturning`, `goAndReturn`,
    // `customWriteReturning` and any `customSelect` here: a statement that
    // isn't a plain read is a write.
    if (!isWriteAuthorized && !isReadOnlyStatement(statement)) {
      return Future.error(UnauthorizedWriteError('select-write'));
    }
    final barrier = Zone.current[_readBarrierKey];
    if (barrier is! Future<void> Function()) {
      return executor.runSelect(statement, args);
    }
    return runZoned(
      barrier,
      zoneValues: {_readBarrierKey: null},
    ).then((_) => executor.runSelect(statement, args));
  }

  @override
  Future<int> runInsert(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) => _check('insert', () => executor.runInsert(statement, args));

  @override
  Future<int> runUpdate(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) => _check('update', () => executor.runUpdate(statement, args));

  @override
  Future<int> runDelete(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) => _check('delete', () => executor.runDelete(statement, args));

  @override
  Future<void> runCustom(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) => _check('custom', () => executor.runCustom(statement, args));

  @override
  Future<void> runBatched(
    QueryExecutor executor,
    BatchedStatements statements,
  ) => _check('batch', () => executor.runBatched(statements));
}
