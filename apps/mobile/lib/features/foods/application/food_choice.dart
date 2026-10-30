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
    this.personalFood,
    this.guard,
    this.lastUsed,
    this.siblings = const [],
    this.yields,
    this.pendingCreate,
  });

  /// A scanned product not saved yet (A28a D8): logging it creates this
  /// personal food (with [ref]'s ID) and the entry in one change set.
  final PersonalFoodDraft? pendingCreate;

  /// The food snapshot selected for the next log.
  final EntryFood food;

  /// Resolvable units and canonical nutrient basis.
  final FoodMeasures measures;

  /// Current pack metadata, absent for retired or personal IDs.
  final CatalogFood? catalogFood;

  /// Live personal definition observed by the loader.
  final PersonalFood? personalFood;

  /// Version checked inside the write transaction (A09 F2).
  final VersionedId? guard;

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
  FoodState? get state => personalFood?.state ?? catalogFood?.state;

  /// Pack yield group when known.
  String? get yieldGroup => catalogFood?.yieldGroup;

  /// FD-022: prefer last input, then parsed amount, then the entry serving.
  Quantity defaultPortion({
    ParsedAmount? parsed,
    Quantity? lastUsed,
    UnitSystem system = UnitSystem.metric,
  }) {
    final personal = personalFood;
    if (personal == null) {
      return DefaultPortion.choose(
        measures,
        system: system,
        lastUsed: lastUsed ?? this.lastUsed?.amount.input,
        parsed: parsed,
      );
    }
    final entry = personal.entryServing;
    final unit = entry?.unit ?? personal.servings.firstOrNull?.unit;
    var fallback = unit == null ? null : Quantity(1, unit);
    if (entry != null) {
      final resolved = measures.resolve(Quantity(1, entry.unit));
      if (resolved is! Resolved || resolved.amount != entry.amount) {
        // Entry metadata describes the values originally typed. It must not
        // replace a separately defined serving with the same code.
        fallback = Quantity(entry.amount, basis.unitCode);
      }
    }
    final defaultUnit =
        fallback?.unitCode ??
        DefaultPortion.choose(measures, system: system).unitCode;
    final parsedInput = parsed == null
        ? null
        : Quantity(parsed.amount, parsed.unitCode ?? defaultUnit);
    final usableParse =
        parsedInput != null && measures.resolve(parsedInput) is Resolved;
    return DefaultPortion.choose(
      measures,
      system: system,
      lastUsed: lastUsed ?? this.lastUsed?.amount.input,
      parsed: usableParse
          ? ParsedAmount(parsedInput.amount, parsedInput.unitCode)
          : fallback == null
          ? null
          : ParsedAmount(fallback.amount, fallback.unitCode),
    );
  }

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
FoodChoice historyChoice(FoodHistoryItem item, {VersionedId? guard}) =>
    FoodChoice(
      guard: guard,
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
  new(
    this.repository,
    this.history, {
    this.personalFoods,
    this.onlineFood,
    this.scannedFood,
  });

  /// Scanned products not saved yet (A28a D8), by their reserved personal
  /// ID; used only when no live personal row has that ID.
  final FoodChoice? Function(String id)? scannedFood;

  /// Foods seen in online results (A24 D4), used when the pack lacks the ID.
  final CatalogFood? Function(String id)? onlineFood;

  /// Latest live personal rows; an absent row must never fall back unguarded.
  final List<PersonalFood> Function()? personalFoods;

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
    if (ref.food.kind == FoodRefKind.personal) {
      final personal = personalFoods
          ?.call()
          .where((f) => f.id == ref.food.id)
          .firstOrNull;
      return personal == null
          ? scannedFood?.call(ref.food.id!)
          : personalChoice(personal, history: used);
    }
    final food = ref.food.kind == FoodRefKind.catalog
        ? (await repository.foodsByIds([
                ref.food.id!,
              ]))[ref.food.id]?.firstOrNull ??
              onlineFood?.call(ref.food.id!)
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

/// Current personal values and units, guarded by the observed row version.
FoodChoice personalChoice(PersonalFood food, {FoodHistoryItem? history}) =>
    FoodChoice(
      food: EntryFood(
        ref: FoodRef.personal(food.id),
        names: food.names,
        per100: food.per100,
        provenance: Provenance(source: FoodSource.yours),
      ),
      measures: FoodMeasures(
        basis: food.basis,
        servingUnits: [
          for (final s in [
            ...food.servings,
            if (food.entryServing case final entry?)
              if (!food.servings.any((s) => s.unit == entry.unit)) entry,
          ])
            if (food.basis == NutrientBasis.per100g)
              ServingUnit.grams(s.unit, s.amount)
            else
              ServingUnit.milliliters(s.unit, s.amount),
        ],
      ),
      personalFood: food,
      guard: VersionedId(food.id, food.version),
      lastUsed: history,
    );

/// A scanned product that becomes a personal food when logged (A28a D8):
/// the same units and default portion as a saved one, no guard (the food is
/// created in the log's change set), [id] reserved for it.
FoodChoice scannedChoice(String id, PersonalFoodDraft draft) {
  final virtual = personalChoice(
    PersonalFood(id: id, version: 1, draft: draft),
  );
  return FoodChoice(
    food: virtual.food,
    measures: virtual.measures,
    personalFood: virtual.personalFood,
    pendingCreate: draft,
  );
}
