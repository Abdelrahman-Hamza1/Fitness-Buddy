import 'package:fb_design_system/fb_design_system.dart' show FbSource;
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/catalog/catalog_models.dart' show CatalogCity;
import 'package:fb_mobile/l10n/gen/app_localizations.dart';

// Words for domain values, shared by every feature that shows them (A08 D18):
// moved out of `features/foods/presentation/` so `diary`, `today` and `foods`
// need no feature-to-feature import.

/// The name of [slot]: its own name when the user gave one, else the word
/// for its default key.
String slotLabel(AppLocalizations l10n, MealSlot slot) =>
    slot.name ??
    switch (slot.defaultKey) {
      'breakfast' => l10n.todaySlotBreakfast,
      'lunch' => l10n.todaySlotLunch,
      'snacks' => l10n.todaySlotSnacks,
      'dinner' => l10n.todaySlotDinner,
      final key? => key,
      null => '',
    };

/// The design system's badge for a food's [source] (FD-010).
FbSource fbSourceOf(FoodSource source) => switch (source) {
  FoodSource.yours => FbSource.yours,
  FoodSource.database => FbSource.database,
  FoodSource.reference => FbSource.referenceDish,
  FoodSource.estimate => FbSource.estimate,
};

/// The name of an optional nutrient (FD-002).
String nutrientKeyLabel(AppLocalizations l10n, NutrientKey key) =>
    switch (key) {
      NutrientKey.sugar => l10n.foodNutrientSugar,
      NutrientKey.saturatedFat => l10n.foodNutrientSaturatedFat,
      NutrientKey.transFat => l10n.foodNutrientTransFat,
      NutrientKey.sodium => l10n.foodNutrientSodium,
      NutrientKey.cholesterol => l10n.foodNutrientCholesterol,
      NutrientKey.alcohol => l10n.foodNutrientAlcohol,
    };

/// The name of an editable nutrient (AI-072): the five core ones and the
/// optional ones.
String nutrientLabel(AppLocalizations l10n, NutrientField field) =>
    switch (field) {
      NutrientField.kcal => l10n.foodNutrientEnergy,
      NutrientField.protein => l10n.foodNutrientProtein,
      NutrientField.carbs => l10n.foodNutrientCarbs,
      NutrientField.fat => l10n.foodNutrientFat,
      NutrientField.fiber => l10n.foodNutrientFiber,
      NutrientField.sugar => l10n.foodNutrientSugar,
      NutrientField.saturatedFat => l10n.foodNutrientSaturatedFat,
      NutrientField.transFat => l10n.foodNutrientTransFat,
      NutrientField.sodium => l10n.foodNutrientSodium,
      NutrientField.cholesterol => l10n.foodNutrientCholesterol,
      NutrientField.alcohol => l10n.foodNutrientAlcohol,
    };

/// The words for unit codes (A07 D8, LC-011).
///
/// Codes are free text in the data (`slice`, `wedge`, `small_plate`, ...), so
/// this is one switch from code to ARB string. [knownUnitLabel] is `null` for
/// a code with no word; [unitLabel] then falls back to "portion" with the
/// size it holds. A test checks that every code in the fixture pack and the
/// bundled pack has its own word.
String? knownUnitLabel(AppLocalizations l10n, String code, num count) =>
    switch (code) {
      'g' => l10n.unitG,
      'kg' => l10n.unitKg,
      'oz' => l10n.unitOz,
      'lb' => l10n.unitLb,
      'ml' => l10n.unitMl,
      'l' => l10n.unitL,
      'fl_oz' => l10n.unitFlOz,
      'tbsp' => l10n.unitTbsp,
      'tsp' => l10n.unitTsp,
      'cup' => l10n.unitCup(count),
      'piece' => l10n.unitPiece(count),
      'loaf' => l10n.unitLoaf(count),
      'plate' => l10n.unitPlate(count),
      'small_plate' => l10n.unitSmallPlate(count),
      'large_plate' => l10n.unitLargePlate(count),
      'glass' => l10n.unitGlass(count),
      'sandwich' => l10n.unitSandwich(count),
      'disc' => l10n.unitDisc(count),
      'serving' => l10n.unitServing(count),
      'can' => l10n.unitCan(count),
      'bowl' => l10n.unitBowl(count),
      'small_bowl' => l10n.unitSmallBowl(count),
      'half' => l10n.unitHalf(count),
      'half_loaf' => l10n.unitHalfLoaf(count),
      'large_piece' => l10n.unitLargePiece(count),
      'small_piece' => l10n.unitSmallPiece(count),
      'large_sandwich' => l10n.unitLargeSandwich(count),
      'small_sandwich' => l10n.unitSmallSandwich(count),
      'meal' => l10n.unitMeal(count),
      'pan' => l10n.unitPan(count),
      'two_pieces' => l10n.unitTwoPieces(count),
      'slice' => l10n.unitSlice(count),
      'wedge' => l10n.unitWedge(count),
      'container' => l10n.unitContainer(count),
      'ladle' => l10n.unitLadle(count),
      _ => null,
    };

/// The label of unit [code] for [count] of it. A code with no word shows
/// "portion", with the size of [serving] when the food gives one. That size is
/// shown in [system]'s unit ("portion (2.1 oz)", A10 D4); a [serving] needs a
/// [system].
String unitLabel(
  AppLocalizations l10n,
  String code,
  num count, {
  ServingUnit? serving,
  UnitSystem? system,
}) {
  final known = knownUnitLabel(l10n, code, count);
  if (known != null) return known;
  if (serving == null) return l10n.unitPortion(count);
  assert(system != null, 'a sized portion label needs the unit system');
  final unitSystem = system ?? UnitSystem.metric;
  final size = serving.basis == NutrientBasis.per100g
      ? unitSystem.showFoodMass(Mass.grams(serving.amount))
      : unitSystem.showVolume(Volume.milliliters(serving.amount));
  return l10n.unitPortionSized(
    count,
    size.value,
    knownUnitLabel(l10n, size.unitCode, size.value) ?? size.unitCode,
  );
}

/// A city's name (LC-033): the English name first, then the Arabic one when
/// the pack has it, e.g. "Nablus · نابلس". One place for the picker rows, the
/// City row on Me and the "City set" message.
String cityLabel(AppLocalizations l10n, CatalogCity city) {
  final arabic = city.nameAr;
  return arabic == null || arabic.isEmpty
      ? city.nameEn
      : l10n.cityName(city.nameEn, arabic);
}

/// The country shown under a city's name (LC-033): the name for Palestine,
/// Jordan and the region the owner's cities come from, else the ISO code.
String countryLabel(AppLocalizations l10n, String code) => switch (code) {
  'PS' => l10n.countryPS,
  'JO' => l10n.countryJO,
  'EG' => l10n.countryEG,
  'TR' => l10n.countryTR,
  'IQ' => l10n.countryIQ,
  'SA' => l10n.countrySA,
  'SY' => l10n.countrySY,
  'AE' => l10n.countryAE,
  'OM' => l10n.countryOM,
  'QA' => l10n.countryQA,
  'YE' => l10n.countryYE,
  'LB' => l10n.countryLB,
  'KW' => l10n.countryKW,
  'BH' => l10n.countryBH,
  'MA' => l10n.countryMA,
  _ => code,
};
