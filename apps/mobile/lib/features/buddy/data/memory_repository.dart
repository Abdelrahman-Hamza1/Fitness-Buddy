import 'package:drift/drift.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/db/db_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'memory_repository.g.dart';

/// Read-only memory queries (A67 D10); writes are `MemoryItemOp`s. User
/// content: never logged.
final class MemoryRepository {
  /// One profile's database.
  const new(this._db);

  final AppDatabase _db;

  SimpleSelectStatement<$MemoryItemsTable, MemoryItemRow> get _live =>
      _db.select(_db.memoryItems)
        ..where((t) => t.deletedAt.isNull())
        ..orderBy([
          (t) => OrderingTerm.desc(t.createdAt),
          (t) => OrderingTerm.desc(t.id),
        ]);

  /// [row] as an item, or `null` when it can't be read.
  static MemoryItem? of(MemoryItemRow row) {
    final origin = MemoryOrigin.fromCode(row.createdFrom);
    if (origin == null ||
        row.memoryKey.isEmpty ||
        row.memoryValue.isEmpty ||
        !isUuid(row.id) ||
        row.version < 1) {
      return null;
    }
    return MemoryItem(
      id: row.id,
      version: row.version,
      kind: row.kind,
      key: row.memoryKey,
      value: row.memoryValue,
      origin: origin,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        row.createdAt,
        isUtc: true,
      ),
    );
  }

  /// Every live item, newest first.
  Future<List<MemoryItem>> all() async => [
    for (final row in await _live.get()) ?of(row),
  ];

  /// [all], re-emitted on every change.
  Stream<List<MemoryItem>> watch() =>
      _live.watch().map((rows) => [for (final r in rows) ?of(r)]);
}

/// The memory repository of the open profile.
@Riverpod(keepAlive: true)
MemoryRepository memoryRepository(Ref ref) =>
    MemoryRepository(ref.watch(appDatabaseProvider));
