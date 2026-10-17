import 'package:drift/drift.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/db/write_guard.dart';

import '../../../core/db/support/db_support.dart';

/// A UUID-shaped id for fixture row [n].
String fixtureId(int n) =>
    '0199e3c2-5b1a-7c3d-8e4f-${n.toRadixString(16).padLeft(12, '0')}';

/// A diary entry row, as the single writer would insert it (tests insert
/// directly: the op handler is WP3).
DiaryEntriesCompanion entryRow(
  int n, {
  required String date,
  required String slotId,
  int? occurredAtUtc,
  int tzOffsetMin = 0,
  double kcal = 100,
  double protein = 5,
  double carbs = 10,
  double fat = 2,
  double fiber = 1,
  String? dishGroupId,
  int? deletedAt,
  String foodKind = 'catalog',
  String source = 'database',
  bool isEstimate = false,
  String? extrasJson,
  String? estimateRangeJson,
  String? assumptionsJson,
  int wall = 1,
}) => DiaryEntriesCompanion.insert(
  id: fixtureId(n),
  createdAt: 1,
  updatedHlc: hlcAt(wall),
  version: 1,
  deletedAt: Value(deletedAt),
  deviceId: testDevice,
  origin: 'direct',
  foodKind: foodKind,
  foodId: Value(foodKind == 'estimate' ? null : 'food-$n'),
  foodVersion: const Value('1'),
  nameEn: 'Food $n',
  nameAr: const Value('طعام'),
  inputAmount: 100,
  inputUnit: 'g',
  amount: 100,
  amountBasis: 'g',
  per100Kcal: kcal,
  per100ProteinG: protein,
  per100CarbsG: carbs,
  per100FatG: fat,
  per100FiberG: fiber,
  kcal: kcal,
  proteinG: protein,
  carbsG: carbs,
  fatG: fat,
  fiberG: fiber,
  extrasJson: Value(extrasJson),
  source: source,
  isEstimate: isEstimate,
  estimateRangeJson: Value(estimateRangeJson),
  assumptionsJson: Value(assumptionsJson),
  localDate: date,
  occurredAtUtc:
      occurredAtUtc ??
      DateTime.utc(2026, 10, 17, 12).millisecondsSinceEpoch + n,
  tzOffsetMin: tzOffsetMin,
  slotId: slotId,
  dishGroupId: Value(dishGroupId),
);

/// Inserts [rows] in one batch.
Future<void> insertEntries(
  AppDatabase db,
  Iterable<DiaryEntriesCompanion> rows,
) => runAuthorizedWrite(
  () => db.batch((b) => b.insertAll(db.diaryEntries, rows)),
);

/// Marks the entry [n] deleted (a tombstone), as a handler would.
Future<void> tombstoneEntry(AppDatabase db, int n, {int wall = 2}) =>
    runAuthorizedWrite(
      () =>
          (db.update(
            db.diaryEntries,
          )..where((t) => t.id.equals(fixtureId(n)))).write(
            DiaryEntriesCompanion(
              deletedAt: const Value(5),
              version: const Value(2),
              updatedHlc: Value(hlcAt(wall)),
            ),
          ),
    );
