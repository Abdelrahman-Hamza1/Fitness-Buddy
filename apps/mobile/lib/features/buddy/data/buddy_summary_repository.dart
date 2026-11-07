import 'package:drift/drift.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/db/db_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'buddy_summary_repository.g.dart';

/// The stored conversation summary (A66 D9). User content: never logged.
final class BuddySummary {
  /// A summary.
  const new({
    required this.text,
    required this.revision,
    required this.watermark,
  });

  /// The text.
  final String text;

  /// Its revision.
  final int revision;

  /// The last summarised chat message.
  final String watermark;

  @override
  String toString() => 'BuddySummary(r$revision)';
}

/// Read-only summary queries; writes are `BuddySummaryOp`s.
final class BuddySummaryRepository {
  /// One profile's database.
  const new(this._db);

  final AppDatabase _db;

  SimpleSelectStatement<$BuddySummariesTable, BuddySummaryRow> get _live =>
      _db.select(_db.buddySummaries)
        ..where((t) => t.deletedAt.isNull())
        ..orderBy([(t) => OrderingTerm.desc(t.revision)])
        ..limit(1);

  static BuddySummary? _of(BuddySummaryRow? row) => row == null
      ? null
      : BuddySummary(
          text: row.summaryText,
          revision: row.revision,
          watermark: row.watermark,
        );

  /// The live summary with the highest revision, or `null`.
  Future<BuddySummary?> current() async => _of(await _live.getSingleOrNull());

  /// [current], re-emitted on every change.
  Stream<BuddySummary?> watch() => _live.watchSingleOrNull().map(_of);
}

/// The summary repository of the open profile.
@Riverpod(keepAlive: true)
BuddySummaryRepository buddySummaryRepository(Ref ref) =>
    BuddySummaryRepository(ref.watch(appDatabaseProvider));
