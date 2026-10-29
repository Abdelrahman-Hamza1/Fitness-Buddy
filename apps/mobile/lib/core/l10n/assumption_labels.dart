import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/amount_text.dart';
import 'package:fb_mobile/l10n/gen/app_localizations.dart';

// Stored assumption codes as words (A21 PA3, TD-084, A22 D17). Used by the
// diary's item details and Buddy's cards, so it lives in core: no feature
// imports another for it.

/// The words for stored assumption [raw]. An unknown or malformed code, or
/// legacy raw text, shows the one generic label: never the stored string
/// (it may be model text). Masses are shown in [system].
String assumptionText(
  AppLocalizations l10n,
  String raw, {
  UnitSystem system = UnitSystem.metric,
}) => switch (AssumptionCode.parse(raw)) {
  YieldAssumption(
    :final fromState,
    :final toState,
    :final fromGrams,
    :final toGrams,
  ) =>
    l10n.assumptionYield(
      foodMassText(l10n, fromGrams, system: system),
      _state(l10n, fromState),
      foodMassText(l10n, toGrams, system: system),
      _state(l10n, toState),
    ),
  OilAssumption(:final all) =>
    all ? l10n.assumptionOilAll : l10n.assumptionOilMost,
  final ShareAssumption share => l10n.assumptionShare(
    (share.share * 100).round(),
  ),
  OriginAssumption(:final origin) => switch (origin) {
    ProposalChoiceOrigin.stated => l10n.assumptionOriginStated,
    ProposalChoiceOrigin.savedDefault => l10n.assumptionOriginSavedDefault,
    ProposalChoiceOrigin.fallback => l10n.assumptionOriginFallback,
    ProposalChoiceOrigin.userAdjusted => l10n.assumptionOriginUserAdjusted,
  },
  null => l10n.assumptionGeneric,
};

/// The codes worth a line on a card: what a number rests on (yield, share,
/// oil). Where a choice came from is already on its chip.
bool isCardAssumption(String raw) => switch (AssumptionCode.parse(raw)) {
  YieldAssumption() || ShareAssumption() || OilAssumption() => true,
  _ => false,
};

String _state(AppLocalizations l10n, FoodState state) => switch (state) {
  FoodState.raw => l10n.assumptionStateRaw,
  FoodState.cooked => l10n.assumptionStateCooked,
  FoodState.dry => l10n.assumptionStateDry,
  FoodState.drained => l10n.assumptionStateDrained,
  FoodState.fried => l10n.assumptionStateFried,
  FoodState.asSold => l10n.assumptionStateAsSold,
};
