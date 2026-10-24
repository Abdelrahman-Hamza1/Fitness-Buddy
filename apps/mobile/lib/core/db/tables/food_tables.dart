// Drift evaluates self-referencing column checks lazily, without recursion.
// ignore_for_file: recursive_getters
import 'package:drift/drift.dart';
import 'package:fb_mobile/core/db/tables/sync_columns.dart';

/// Private definitions; logged snapshots live independently (FD-073).
@DataClassName('PersonalFoodRow')
class PersonalFoods extends Table with SyncColumns {
  /// English name.
  TextColumn get nameEn => text()();

  /// Optional Arabic name.
  TextColumn get nameAr => text().nullable()();

  /// Optional JSON alias list.
  TextColumn get aliasesJson => text().nullable()();

  /// Optional brand.
  TextColumn get brand => text().nullable()();

  /// Optional JSON GTIN list.
  TextColumn get barcodesJson => text().nullable()();

  /// Optional JSON nutrient extras.
  TextColumn get per100ExtrasJson => text().nullable()();

  /// Optional JSON serving definitions.
  TextColumn get servingsJson => text().nullable()();

  /// Original entry serving code.
  TextColumn get entryServingUnit => text().nullable()();

  /// Creation method, open for later steps.
  TextColumn get createdFrom => text()();

  /// Nutrient state code.
  TextColumn get state => text()();

  /// Grams or ml.
  TextColumn get basis => text().check(basis.isIn(const ['g', 'ml']))();

  /// Stored per-100 value.
  RealColumn get per100Kcal =>
      real().check(per100Kcal.isBiggerOrEqualValue(0))();

  /// Stored per-100 value.
  RealColumn get per100ProteinG =>
      real().check(per100ProteinG.isBiggerOrEqualValue(0))();

  /// Stored per-100 value.
  RealColumn get per100CarbsG =>
      real().check(per100CarbsG.isBiggerOrEqualValue(0))();

  /// Stored per-100 value.
  RealColumn get per100FatG =>
      real().check(per100FatG.isBiggerOrEqualValue(0))();

  /// Stored per-100 value.
  RealColumn get per100FiberG =>
      real().check(per100FiberG.isBiggerOrEqualValue(0))();

  /// Original entry serving amount on this basis.
  RealColumn get entryServingAmount => real().nullable()();
  @override
  List<String> get customConstraints => [
    'CHECK ((entry_serving_unit IS NULL) = (entry_serving_amount IS NULL))',
  ];
}

/// Sync registry name (A09 WP1).
const personalFoodEntity = 'personalFood';
