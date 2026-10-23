import 'package:fb_design_system/fb_design_system.dart' show FbSource;
import 'package:fb_domain/fb_domain.dart';
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
      'slice' => l10n.unitSlice(count),
      'wedge' => l10n.unitWedge(count),
      'container' => l10n.unitContainer(count),
      'ladle' => l10n.unitLadle(count),
      _ => null,
    };

/// The label of unit [code] for [count] of it. A code with no word shows
/// "portion", with the size of [serving] when the food gives one.
String unitLabel(
  AppLocalizations l10n,
  String code,
  num count, {
  ServingUnit? serving,
}) =>
    knownUnitLabel(l10n, code, count) ??
    (serving == null
        ? l10n.unitPortion(count)
        : l10n.unitPortionSized(
            count,
            serving.amount,
            serving.basis == NutrientBasis.per100g ? l10n.unitG : l10n.unitMl,
          ));
