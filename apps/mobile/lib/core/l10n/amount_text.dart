import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/domain_labels.dart';
import 'package:fb_mobile/l10n/gen/app_localizations.dart';

// The one place a food weight or volume becomes text (A10 D4, LC-010/011).
//
// The unit rule itself is the pure `FoodAmountDisplay` in fb_domain; this file
// only adds the words. A guard test fails when a presentation file formats a
// food amount any other way. Display never writes: editors open on the
// stored input as typed, never on a converted display value.

/// A number and its unit word: "227 g", "8.5 fl oz", "1 loaf".
String _quantityText(
  AppLocalizations l10n,
  double value,
  String unitCode, {
  required UnitSystem system,
  ServingUnit? serving,
}) => l10n.foodResultServing(
  value,
  unitLabel(l10n, unitCode, value, serving: serving, system: system),
);

/// The amount as the user logged it, shown in [system] (LC-010, PA2): "227 g"
/// for a logged "8 oz" in metric, "1 loaf" as typed. Short: no second
/// quantity. Used by rows, search results, saved meals and messages.
///
/// [basis] is the food's basis; [serving] names a food-specific unit the app
/// has no word for.
String servingText(
  AppLocalizations l10n, {
  required Quantity input,
  required NutrientBasis basis,
  required UnitSystem system,
  ServingUnit? serving,
}) {
  final primary = FoodAmountDisplay.of(
    input: input,
    amount: input.amount,
    basis: basis,
    system: system,
  ).primary;
  return _quantityText(
    l10n,
    primary.value,
    primary.unitCode,
    system: system,
    serving: primary.converted ? null : serving,
  );
}

/// The amount as logged, with the stored canonical amount in [system] after
/// it where that adds information: "1 loaf (2.1 oz)", "250 ml (258 g)", and
/// just "227 g" when the logged unit already is the basis's (A10 D4 (c)).
///
/// [amount] is the canonical amount in the basis unit (grams or millilitres)
/// stored with the entry.
String foodAmountText(
  AppLocalizations l10n, {
  required Quantity input,
  required double amount,
  required NutrientBasis basis,
  required UnitSystem system,
  ServingUnit? serving,
}) {
  final display = FoodAmountDisplay.of(
    input: input,
    amount: amount,
    basis: basis,
    system: system,
  );
  final primary = _quantityText(
    l10n,
    display.primary.value,
    display.primary.unitCode,
    system: system,
    serving: display.primary.converted ? null : serving,
  );
  final secondary = display.secondary;
  return secondary == null
      ? primary
      : l10n.foodAmountWithCanonical(
          primary,
          _quantityText(
            l10n,
            secondary.value,
            secondary.unitCode,
            system: system,
          ),
        );
}

/// The line an amount editor shows under the typed amount (backlog #117):
/// "That's 120 g" for 2 pieces, "That's 258 g" for 250 ml of a food on a
/// per-100 g basis. Null when the typed unit already is the basis's
/// dimension (nothing to add) or when nothing resolved yet. The same rule
/// as the rows' "(120 g)" ([foodAmountText]); the editor keeps the typed
/// value as it is.
String? amountEditorCanonical(
  AppLocalizations l10n,
  NutrientSnapshot? snapshot, {
  required UnitSystem system,
}) {
  final input = snapshot?.input;
  if (snapshot == null || input == null) return null;
  final secondary = FoodAmountDisplay.of(
    input: input,
    amount: snapshot.amount,
    basis: snapshot.basis,
    system: system,
  ).secondary;
  if (secondary == null) return null;
  return l10n.amountEditorCanonical(
    _quantityText(l10n, secondary.value, secondary.unitCode, system: system),
  );
}

/// Whether an editor offering [unitCodes] for a food on [basis] can show
/// an [amountEditorCanonical] line: it then keeps the line's room at all
/// times, so typing, clearing or switching units never moves what is below
/// (UX-045).
bool amountEditorMayResolve(Iterable<String> unitCodes, NutrientBasis basis) =>
    unitCodes.any(
      (code) =>
          FoodAmountDisplay.of(
            input: Quantity(1, code),
            amount: 1,
            basis: basis,
            system: UnitSystem.metric,
          ).secondary !=
          null,
    );

/// A weight in [system]'s food unit: "100 g" or "3.5 oz" (the yield note).
String foodMassText(
  AppLocalizations l10n,
  double grams, {
  required UnitSystem system,
}) {
  final shown = system.showFoodMass(Mass.grams(grams));
  return _quantityText(l10n, shown.value, shown.unitCode, system: system);
}
