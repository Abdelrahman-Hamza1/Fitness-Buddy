import 'package:fb_domain/fb_domain.dart';

/// Fixed IDs for diary tests.
const entryA = '0199e3c2-5b1a-7000-8000-00000000000a';
const entryB = '0199e3c2-5b1a-7000-8000-00000000000b';
const entryC = '0199e3c2-5b1a-7000-8000-00000000000c';
const groupG = '0199e3c2-5b1a-7000-8000-0000000000f1';
const copyA = '0199e3c2-5b1b-7000-8000-0000000000aa';
const copyB = '0199e3c2-5b1b-7000-8000-0000000000bb';
const copyG = '0199e3c2-5b1b-7000-8000-0000000000ff';
const savedMeal = '0199e3c2-5b1c-7000-8000-000000000001';

/// The per-100 values of cooked rice, roughly.
final rice100 = Nutrients(
  kcal: 130,
  protein: 2.7,
  carbs: 28,
  fat: 0.3,
  fiber: 0.4,
);

/// A catalog food with database provenance.
EntryFood riceFood({String id = 'usda:169704'}) => EntryFood(
  ref: FoodRef.catalog(id, version: '2026.10.1'),
  names: FoodNames('Rice, cooked', ar: 'رز مطبوخ'),
  per100: rice100,
  provenance: Provenance(source: FoodSource.database),
);

/// [grams] g of a food, typed as grams.
EntryAmount grams(double grams) => EntryAmount(
  input: Quantity(grams, 'g'),
  amount: grams,
  basis: NutrientBasis.per100g,
);

/// A snapshot with [kcal] and simple macros.
Nutrients snapshotOf(
  double kcal, {
  double protein = 1,
  double carbs = 2,
  double fat = 3,
  double fiber = 0.5,
  Map<NutrientKey, double> extras = const {},
}) => Nutrients(
  kcal: kcal,
  protein: protein,
  carbs: carbs,
  fat: fat,
  fiber: fiber,
  extras: extras,
);

/// A stored entry [id] in [slotId] on 2026-10-13 at 13:00 (+03:00).
DiaryEntry entry({
  String id = entryA,
  String slotId = DefaultSlots.lunchId,
  Nutrients? snapshot,
  String? dishGroupId,
  int version = 1,
}) {
  final time = EntryTime(DateTime.utc(2026, 10, 13, 10), 180);
  return DiaryEntry(
    id: id,
    version: version,
    time: time,
    localDate: time.localDate,
    slotId: slotId,
    dishGroupId: dishGroupId,
    food: riceFood(),
    amount: grams(150),
    snapshot: snapshot ?? snapshotOf(195),
  );
}
