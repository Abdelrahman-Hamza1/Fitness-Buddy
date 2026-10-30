import 'package:drift/drift.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/db/db_providers.dart';
import 'package:fb_mobile/features/buddy/data/proposal_mappers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'proposal_repository.g.dart';

/// Read-only proposal queries (A23 D9, PA8). Returns domain
/// [ProposalRecord]s, never drift rows; writes go through
/// `ChangeSetApplier` with `ProposalOp`s. Rows that can't be read are
/// skipped (the error is content-free).
final class ProposalRepository {
  /// One profile's database.
  const new(this._db);

  final AppDatabase _db;

  /// The live record [id], or `null`.
  Future<ProposalRecord?> byId(String id) async =>
      _read(await _live((t) => t.id.equals(id)).get()).firstOrNull;

  /// The live cards bound to assistant message [messageId]'s budget, in
  /// creation order: what restore loads per message (A23 D12).
  Future<List<ProposalRecord>> byBudgetMessage(String messageId) async =>
      _read(await _live((t) => t.budgetMessageId.equals(messageId)).get());

  /// Every live pending card, oldest first (restore, the pending strip).
  Future<List<ProposalRecord>> pending() async => _read(await _pending().get());

  /// [pending], re-emitted on every change.
  Stream<List<ProposalRecord>> watchPending() => _pending().watch().map(_read);

  /// The live confirmed and discarded cards resolved at or after [since]
  /// (all of them without it), oldest resolution first: A26's learning
  /// source. Pending and superseded cards are never returned (`06` §5).
  Future<List<ProposalRecord>> resolved({DateTime? since}) async {
    final query = _db.select(_db.proposals)
      ..where(
        (t) =>
            t.deletedAt.isNull() &
            t.status.isIn([
              ProposalStatus.confirmed.code,
              ProposalStatus.discarded.code,
            ]) &
            (since == null
                ? const Constant(true)
                : t.resolvedAt.isBiggerOrEqualValue(
                    since.toUtc().millisecondsSinceEpoch,
                  )),
      )
      ..orderBy([
        (t) => OrderingTerm(expression: t.resolvedAt),
        (t) => OrderingTerm(expression: t.id),
      ]);
    return _read(await query.get());
  }

  SimpleSelectStatement<$ProposalsTable, ProposalRow> _pending() =>
      _live((t) => t.status.equals(ProposalStatus.pending.code));

  SimpleSelectStatement<$ProposalsTable, ProposalRow> _live(
    Expression<bool> Function($ProposalsTable t) filter,
  ) => _db.select(_db.proposals)
    ..where((t) => t.deletedAt.isNull() & filter(t))
    ..orderBy([
      (t) => OrderingTerm(expression: t.createdAt),
      (t) => OrderingTerm(expression: t.id),
    ]);

  List<ProposalRecord> _read(List<ProposalRow> rows) {
    final records = <ProposalRecord>[];
    for (final row in rows) {
      try {
        records.add(proposalRecordOf(row));
      } on ProposalMappingError {
        // Unreadable rows are skipped; the error is content-free.
      }
    }
    return records;
  }
}

/// Read-only repository composition stays in data (application-db rule).
@Riverpod(keepAlive: true)
ProposalRepository proposalRepository(Ref ref) =>
    ProposalRepository(ref.watch(appDatabaseProvider));
