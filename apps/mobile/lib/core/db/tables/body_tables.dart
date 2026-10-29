// Drift evaluates self-referencing column checks lazily, without recursion.
// ignore_for_file: recursive_getters
import 'package:drift/drift.dart';
import 'package:fb_mobile/core/db/tables/sync_columns.dart';

/// Weigh-ins (WB-003, A14 D7). The CHECKs are only as strict as the sync
/// wire: the local-write bounds (20–500 kg, note length) live in the
/// handler, so synced rows are never rejected (the A12 convention).
@DataClassName('WeighInRow')
class WeighIns extends Table with SyncColumns {
  /// When it was measured, UTC ms (≥ 0, the wire's minimum; A14 PA9).
  IntColumn get measuredAtUtc =>
      integer().check(measuredAtUtc.isBiggerOrEqualValue(0))();

  /// The zone offset where it was measured, minutes ahead of UTC.
  IntColumn get tzOffsetMin =>
      integer().check(tzOffsetMin.isBetweenValues(-720, 840))();

  /// The day, `YYYY-MM-DD`, from the stored offset (DY-002).
  TextColumn get localDate => text()();

  /// The canonical value in kg, rounded once to storage precision.
  RealColumn get kg => real().check(kg.isBiggerOrEqualValue(0))();

  /// The value as typed (TD-017).
  RealColumn get inputValue =>
      real().check(inputValue.isBiggerOrEqualValue(0))();

  /// The unit as typed: `kg` or `lb`.
  TextColumn get inputUnit =>
      text().check(inputUnit.isIn(const ['kg', 'lb']))();

  /// The optional note. User content.
  TextColumn get note => text().nullable()();

  /// The user picked it for the trend on its day (WB-003, A14 D3).
  BoolColumn get preferredForDay =>
      boolean().withDefault(const Constant(false))();
}

/// The sync entity name of [WeighIns] (contract `weighIn`).
const weighInEntity = 'weighIn';
