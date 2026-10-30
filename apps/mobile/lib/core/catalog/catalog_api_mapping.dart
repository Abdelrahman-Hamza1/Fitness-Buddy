import 'package:fb_api_client/fb_api_client.dart' as api;
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/catalog/catalog_models.dart';

/// Maps a server catalog food (B07, `GET /v1/foods/search`) to the app's
/// [CatalogFood], the same shape the offline pack yields (A24 D3).
///
/// Returns `null` for foods the app can't show yet: an unknown source (OFF
/// stays out until B10/A28) or an unknown state. `catalogKey` is the stable
/// catalog ID shared with the pack; nutrients are per 100 g (B07 rejects
/// per-100 ml releases).
CatalogFood? catalogFoodFromApi(api.CatalogFood food) {
  final badge = CatalogBadge.fromSource(food.source);
  final state = FoodState.fromCode(food.state);
  if (badge == null || state == null) return null;
  final id = food.catalogKey;
  final isVariant = food.kind == 'variant';
  final slash = id.indexOf('/');
  return CatalogFood(
    id: id,
    kind: isVariant ? CatalogFoodKind.variant : CatalogFoodKind.basic,
    nameEn: food.nameEn,
    nameAr: food.nameAr,
    dishId: isVariant && slash > 0 ? id.substring(0, slash) : null,
    state: state,
    basis: NutrientBasis.per100g,
    nutrients: _nutrients(food.nutrients, food.extras),
    nutrientsLow: food.ranges == null ? null : _nutrients(food.ranges!.low),
    nutrientsHigh: food.ranges == null ? null : _nutrients(food.ranges!.high),
    servingUnits: [
      for (final s in food.servings)
        if (s.g case final g? when g > 0)
          ServingUnit.grams(s.unitCode, g)
        else if (s.ml case final ml? when ml > 0)
          ServingUnit.milliliters(s.unitCode, ml),
    ],
    servingRanges: Map.unmodifiable({
      for (final s in food.servings)
        if ((s.rangeLo, s.rangeHi) case (final lo?, final hi?))
          s.unitCode: (lo, hi),
    }),
    densityGramsPerMl: food.densityGPerMl,
    yieldGroup: food.yieldGroup,
    badge: badge,
    verified: food.verified,
    isDraft: false,
    packVersion: food.catalogVersion,
  );
}

Nutrients _nutrients(api.CatalogNutrients n, [Map<String, double>? extras]) =>
    Nutrients(
      kcal: n.kcal,
      protein: n.proteinG,
      carbs: n.carbsG,
      fat: n.fatG,
      fiber: n.fiberG,
      extras: {
        for (final e in (extras ?? const <String, double>{}).entries)
          ?NutrientKey.fromCode(e.key): e.value,
      },
    );
