// The `.check(column…)` idiom reads the getter being declared, which the
// analyzer takes for recursion; drift evaluates it lazily, so it's fine.
// ignore_for_file: recursive_getters

import 'package:drift/drift.dart';
import 'package:fb_mobile/core/db/tables/sync_columns.dart';

/// The diary's synced tables (A06 §3.2, `05` §1). No SQL foreign keys
/// between synced tables (A01 D19): the ops keep references valid.
///
/// Wire entity names are the `*Entity` constants below.

/// The meal slots (DY-010): Breakfast, Lunch, Dinner, Snacks, and the ones
/// the user adds (A10).
@DataClassName('MealSlotRow')
class MealSlots extends Table with SyncColumns {
  /// `breakfast` … for a default slot, `null` for a custom one.
  TextColumn get defaultKey => text().nullable()();

  /// The user's name, `null` for a default slot not renamed (the UI shows
  /// the label for [defaultKey]). User content.
  TextColumn get name => text().nullable()();

  /// The position in the day, lowest first.
  IntColumn get sortOrder => integer()();

  /// The window start, minutes after local midnight (0-1439), or `null`.
  IntColumn get windowStartMin => integer().nullable()();

  /// The window end (exclusive), or `null`. Both bounds or neither.
  IntColumn get windowEndMin => integer().nullable()();

  /// `normal` or `ramadan`.
  TextColumn get mode => text().check(mode.isIn(const ['normal', 'ramadan']))();

  /// Whether the slot is in use.
  BoolColumn get active => boolean()();

  @override
  List<String> get customConstraints => [
    'CHECK ((window_start_min IS NULL) = (window_end_min IS NULL))',
    _windowRange,
  ];
}

const String _windowRange =
    'CHECK (window_start_min IS NULL OR (window_start_min BETWEEN 0 AND 1439 '
    'AND window_end_min BETWEEN 0 AND 1439 '
    'AND window_start_min <> window_end_min))';

/// Dish groups (DY-024): entries logged together as one dish. A group and
/// its live entries share the date and the slot (A06 D1).
@DataClassName('DishGroupRow')
class DishGroups extends Table with SyncColumns {
  /// The dish name. User content.
  TextColumn get name => text()();

  /// The diary day, `YYYY-MM-DD`.
  TextColumn get localDate => text()();

  /// The meal slot's id.
  TextColumn get slotId => text()();
}

/// What a food was logged as: the columns an entry and a saved meal item
/// share (A06 D3-D5). Names, per-100 values and the snapshot belong to the
/// row, so nothing outside it can change a logged value (FD-073).
mixin FoodValueColumns on Table {
  /// `catalog`, `personal`, `estimate` (A27 adds `batch`).
  TextColumn get foodKind => text()();

  /// The food's opaque id, `null` for an estimate.
  TextColumn get foodId => text().nullable()();

  /// The catalog pack version at log time (opaque), or `null`.
  TextColumn get foodVersion => text().nullable()();

  /// The English name. User or catalog content.
  TextColumn get nameEn => text()();

  /// The Arabic name, when there is one.
  TextColumn get nameAr => text().nullable()();

  /// The amount as typed.
  RealColumn get inputAmount => real()();

  /// The unit as typed.
  TextColumn get inputUnit => text()();

  /// The canonical amount, grams or ml.
  RealColumn get amount => real()();

  /// `g` or `ml`.
  TextColumn get amountBasis =>
      text().check(amountBasis.isIn(const ['g', 'ml']))();

  /// Per-100 kcal.
  RealColumn get per100Kcal => real()();

  /// Per-100 protein, g.
  RealColumn get per100ProteinG => real()();

  /// Per-100 carbs, g.
  RealColumn get per100CarbsG => real()();

  /// Per-100 fat, g.
  RealColumn get per100FatG => real()();

  /// Per-100 fiber, g.
  RealColumn get per100FiberG => real()();

  /// Per-100 extras as JSON (`{"sugar": 1.2}`), or `null`.
  TextColumn get per100ExtrasJson => text().nullable()();

  /// The snapshot kcal for [amount].
  RealColumn get kcal => real().check(kcal.isBiggerOrEqualValue(0))();

  /// The snapshot protein, g.
  RealColumn get proteinG => real().check(proteinG.isBiggerOrEqualValue(0))();

  /// The snapshot carbs, g.
  RealColumn get carbsG => real().check(carbsG.isBiggerOrEqualValue(0))();

  /// The snapshot fat, g.
  RealColumn get fatG => real().check(fatG.isBiggerOrEqualValue(0))();

  /// The snapshot fiber, g.
  RealColumn get fiberG => real().check(fiberG.isBiggerOrEqualValue(0))();

  /// The snapshot extras as JSON, or `null`.
  TextColumn get extrasJson => text().nullable()();

  /// The badge: `yours`, `database`, `reference`, `estimate`.
  TextColumn get source => text()();

  /// Whether the values are estimated.
  BoolColumn get isEstimate => boolean()();

  /// `{"lowKcal": …, "highKcal": …}` for an estimate with a range.
  TextColumn get estimateRangeJson => text().nullable()();

  /// The assumptions behind the values, a JSON list of strings.
  TextColumn get assumptionsJson => text().nullable()();
}

/// A logged food (DY-001..003, DY-021..024).
@DataClassName('DiaryEntryRow')
class DiaryEntries extends Table with SyncColumns, FoodValueColumns {
  /// The diary day, `YYYY-MM-DD`; fixed at log time from the stored offset
  /// (DY-002).
  TextColumn get localDate => text()();

  /// When it was eaten, UTC ms.
  IntColumn get occurredAtUtc => integer()();

  /// The zone offset where it was eaten, minutes ahead of UTC.
  IntColumn get tzOffsetMin =>
      integer().check(tzOffsetMin.isBetweenValues(-720, 840))();

  /// The meal slot's id.
  TextColumn get slotId => text()();

  /// The dish group's id, or `null`.
  TextColumn get dishGroupId => text().nullable()();
}

/// The user's marks on a day (DY-004). One row per date, with the natural id
/// `dayMark:<YYYY-MM-DD>` (A06 D11).
@DataClassName('DayMarkRow')
class DayMarks extends Table with SyncColumns {
  /// The day, `YYYY-MM-DD`.
  TextColumn get localDate => text()();

  /// Whether the day is marked incomplete.
  BoolColumn get incomplete => boolean()();

  /// Whether a Ramadan day is marked not fasting (A41).
  BoolColumn get notFasting => boolean().withDefault(const Constant(false))();
}

/// A saved meal (DY-023, DY-031); the UI is A09.
@DataClassName('SavedMealRow')
class SavedMeals extends Table with SyncColumns {
  /// The meal's name. User content.
  TextColumn get name => text()();
}

/// One food of a saved meal, with its snapshot.
@DataClassName('SavedMealItemRow')
class SavedMealItems extends Table with SyncColumns, FoodValueColumns {
  /// The saved meal's id.
  TextColumn get savedMealId => text()();

  /// The position in the meal.
  IntColumn get sortOrder => integer()();
}

/// The entity wire names of the diary tables (sync contract).
const String mealSlotEntity = 'mealSlot';

/// See [mealSlotEntity].
const String dishGroupEntity = 'dishGroup';

/// See [mealSlotEntity].
const String diaryEntryEntity = 'diaryEntry';

/// See [mealSlotEntity].
const String dayMarkEntity = 'dayMark';

/// See [mealSlotEntity].
const String savedMealEntity = 'savedMeal';

/// See [mealSlotEntity].
const String savedMealItemEntity = 'savedMealItem';
