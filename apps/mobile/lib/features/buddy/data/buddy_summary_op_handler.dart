import 'package:drift/drift.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/core/changes/op_handler.dart';
import 'package:fb_mobile/core/changes/row_ops.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/db/natural_id.dart';
import 'package:fb_mobile/core/db/tables/chat_tables.dart';

/// The summary's one row ID: every phone writes the same row.
final String buddySummaryId = naturalId(buddySummaryEntity, 'self');

/// Plans `buddy_summaries` rows inside the applier's transaction (A66 D9).
/// A save is refused (`buddySummaryStale`) when the stored revision moved;
/// the caller drops it (the next compaction asks again).
final class BuddySummaryOpHandler extends ChangeOpHandler<BuddySummaryOp> {
  /// Bound to the applier's database.
  const new(this.db);

  /// Profile database.
  final AppDatabase db;

  @override
  String get family => BuddySummaryOp.familyName;

  @override
  Future<OpPlan> plan(
    BuddySummaryOp op,
    TxReader tx,
    ApplyContext context,
  ) async {
    final live =
        await (tx.db.select(db.buddySummaries)
              ..where((t) => t.deletedAt.isNull())
              ..orderBy([(t) => OrderingTerm.desc(t.revision)]))
            .get();
    switch (op) {
      case SaveBuddySummary():
        if (op.validate() case final invalid?) {
          throw ChangeRejected(InvalidOp(invalid.code));
        }
        final current = live.firstOrNull;
        if ((current?.revision ?? 0) != op.expectedRevision) {
          throw ChangeRejected(InvalidOp(InvalidBuddySummary.stale.code));
        }
        return OpPlan([
          // The one row, revived after a Clear (A66 review, security 2).
          UpsertRow(
            db.buddySummaries,
            BuddySummariesCompanion(
              id: Value(buddySummaryId),
              summaryText: Value(op.text),
              revision: Value(op.revision),
              watermark: Value(op.watermark),
            ),
          ),
          // A competing row (another phone's, or an older build's random
          // ID) is folded in: it goes.
          for (final row in live)
            if (row.id != buddySummaryId)
              TombstoneRow(
                db.buddySummaries,
                row.id,
                expectedVersion: row.version,
                scrub: const BuddySummariesCompanion(summaryText: Value('')),
              ),
        ]);
      case ClearBuddySummary():
        return OpPlan([
          for (final row in live)
            TombstoneRow(
              db.buddySummaries,
              row.id,
              expectedVersion: row.version,
              scrub: const BuddySummariesCompanion(summaryText: Value('')),
            ),
        ]);
    }
  }
}
