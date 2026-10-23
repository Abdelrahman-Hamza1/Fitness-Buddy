import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/foods/data/food_catalog_repository.dart';
import 'package:fb_text/fb_text.dart';
import 'package:flutter/foundation.dart' show immutable;

/// Stable ref used by routes. History refs keep the original pack version.
@immutable
final class FoodChoiceRef {
  /// Creates this structured value.
  const new(this.food);

  /// The food snapshot selected for the next log.
  final FoodRef food;
  @override
  bool operator ==(Object other) =>
      other is FoodChoiceRef && food == other.food;
  @override
  int get hashCode => food.hashCode;
}

/// Data for the amount sheet, with nullable metadata for retired IDs.
final class FoodChoice {
  /// Creates this structured value.
  new({
    required this.food,
    required this.measures,
    this.catalogFood,
    this.lastUsed,
    this.siblings = const [],
    this.yields,
  });

  /// The food snapshot selected for the next log.
  final EntryFood food;

  /// Resolvable units and canonical nutrient basis.
  final FoodMeasures measures;

  /// Current pack metadata, absent for retired or personal IDs.
  final CatalogFood? catalogFood;

  /// Latest snapshot/input for FD-022 defaults.
  final FoodHistoryItem? lastUsed;

  /// Only compatible state alternatives with yield factors (PA12).
  final List<CatalogFood> siblings;

  /// Pack yield factors, used only for the displayed note.
  final YieldConverter? yields;

  /// Absolute estimate ranges describe only the original history amount.
  EntryFood foodForAmount(Resolved amount) {
    final previous = lastUsed?.amount;
    if (food.provenance.range == null ||
        previous == null ||
        (previous.amount == amount.amount && previous.basis == amount.basis)) {
      return food;
    }
    return EntryFood(
      ref: food.ref,
      names: food.names,
      per100: food.per100,
      editedByUser: food.editedByUser,
      provenance: Provenance(
        source: food.provenance.source,
        isEstimate: food.provenance.isEstimate,
        assumptions: food.provenance.assumptions,
      ),
    );
  }

  /// Versioned food identity for the next log.
  FoodRef get ref => food.ref;

  /// English and optional Arabic display names.
  FoodNames get names => food.names;

  /// Nutrients per 100 of the canonical basis.
  Nutrients get per100 => food.per100;

  /// Canonical g or ml basis.
  NutrientBasis get basis => measures.basis;

  /// Known pack state; never inferred for a retired snapshot.
  FoodState? get state => catalogFood?.state;

  /// Pack yield group when known.
  String? get yieldGroup => catalogFood?.yieldGroup;

  /// Stored source badge, retained for snapshot-only foods.
  FoodSource get badge =>
      catalogFood == null && (lastUsed?.editedByUser ?? false)
      ? FoodSource.yours
      : food.provenance.source;

  /// Stored pack sanity verdict, when available.
  CatalogSanity? get sanity => catalogFood?.sanity;

  /// Current catalog version when this choice belongs to the pack.
  int? get packVersion => catalogFood?.packVersion;
}

/// Reuses the exact catalog snapshot/servings for search and the sheet.
FoodChoice catalogChoice(
  CatalogFood food, {
  FoodHistoryItem? history,
  List<CatalogFood> siblings = const [],
  YieldConverter? yields,
}) => FoodChoice(
  food: EntryFood(
    ref: FoodRef.catalog(food.id, version: '${food.packVersion}'),
    names: FoodNames(food.nameEn, ar: food.nameAr),
    per100: food.nutrients,
    provenance: Provenance(
      source: food.badge == CatalogBadge.database
          ? FoodSource.database
          : FoodSource.reference,
    ),
  ),
  measures: food.measures,
  catalogFood: food,
  lastUsed: history,
  siblings: siblings,
  yields: yields,
);

/// Snapshot fallback with a basis-aware reconstructed serving (PA4).
FoodChoice historyChoice(FoodHistoryItem item) => FoodChoice(
  food: EntryFood(
    ref: item.food.ref,
    names: item.food.names,
    per100: item.food.per100,
    provenance: item.food.provenance,
    editedByUser: item.editedByUser,
  ),
  measures: FoodMeasures(
    basis: item.amount.basis,
    servingUnits: [?item.derivedServing],
  ),
  lastUsed: item,
);

/// Loader expands only compatible state siblings with an actual yield factor.
final class FoodChoiceLoader {
  /// Creates this structured value.
  new(this.repository, this.history);

  /// Offline catalog read port.
  final FoodCatalogRepository repository;

  /// Supplies the latest prepared snapshots at load time.
  final List<FoodHistoryItem> Function() history;

  /// Loads metadata or falls back to the latest stored snapshot.
  Future<FoodChoice?> load(FoodChoiceRef ref) async {
    final used = history()
        .where(
          (h) =>
              h.food.ref.kind == ref.food.kind && h.food.ref.id == ref.food.id,
        )
        .firstOrNull;
    final food = ref.food.kind == FoodRefKind.catalog
        ? (await repository.foodsByIds([
            ref.food.id!,
          ]))[ref.food.id]?.firstOrNull
        : null;
    if (food == null) return used == null ? null : historyChoice(used);
    final yields = await repository.yields();
    final group = food.yieldGroup;
    final options = group == null
        ? <CatalogFood>[]
        : await repository.foodsInYieldGroup(group);
    StateSibling<CatalogFood> sibling(CatalogFood f) => StateSibling(
      id: f.id,
      nameKey: identityKey(f.nameEn),
      state: f.state,
      yieldGroup: f.yieldGroup,
      payload: f,
    );
    final siblings = <CatalogFood>[];
    for (final state in FoodState.values) {
      if (group != null &&
          yields.convert(
                amount: Mass.grams(100),
                group: group,
                from: food.state,
                to: state,
              ) !=
              null) {
        siblings.addAll(
          StateSibling.choose(
            picked: sibling(food),
            groupFoods: options.map(sibling),
            stated: state,
          ),
        );
      }
    }
    return catalogChoice(
      food,
      history: used,
      siblings: siblings,
      yields: yields,
    );
  }
}
