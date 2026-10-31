import 'package:fb_catalog/src/compute/dish_nutrients.dart';
import 'package:fb_catalog/src/model/dish.dart';
import 'package:fb_catalog/src/model/issue.dart';

/// Open Food Facts URLs are not allowed as a source (C-5).
final offSourcePattern = RegExp(r'openfoodfacts\.', caseSensitive: false);

/// What `validateCatalog` found.
class ValidationReport {
  /// Problems that fail the build.
  final errors = <CatalogIssue>[];

  /// Sanity warnings (A03 D7): reported, the build continues.
  final warnings = <CatalogIssue>[];

  /// Sanity failures waived by a reviewed `sanity_override`, with the reason.
  final overrides = <CatalogIssue>[];

  /// Per-100 g of every variant that resolved, by `ref:<dish>/<variant>`.
  final computed = <String, DishPer100>{};
}

/// Whether [food] (`usda:...`, `ref:dish` or `ref:dish/variant`) exists.
/// When the selection failed to load ([basicsLoaded] false), `usda:`
/// references aren't checked: the root cause is already reported, and
/// every recipe line would otherwise repeat it (#66).
bool foodResolves(
  String food,
  Set<String> basicIds,
  List<ReferenceDish> dishes, {
  bool basicsLoaded = true,
}) {
  if (food.startsWith('usda:')) return !basicsLoaded || basicIds.contains(food);
  final slash = food.indexOf('/');
  final dishId = slash < 0 ? food : food.substring(0, slash);
  for (final d in dishes) {
    if (d.id != dishId) continue;
    return slash < 0 || d.variants.any((v) => d.variantId(v) == food);
  }
  return false;
}
