import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/catalog/catalog.dart';

export 'package:fb_mobile/core/catalog/catalog_models.dart';

/// Read-only offline port; application never needs a database handle.
class FoodCatalogRepository {
  /// Creates this structured value.
  new(this.catalog);

  /// Reader of the attached immutable pack.
  final OfflineCatalog catalog;

  /// External pack swaps, including detach and failed replacement.
  Stream<void> get packChanges => catalog.packChanges;

  /// Attached pack version, or null while unavailable.
  Future<int?> packVersion() => catalog.packVersion();

  /// Ordered and bounded name passes; exact rows remain uncapped.
  Future<List<CatalogNameRow>> candidateNames(CandidateQuery query) =>
      catalog.candidateNames(query);

  /// Uncapped aliases for the history vocabulary cache.
  Future<List<CatalogNameRow>> namesForTargets(Iterable<String> ids) =>
      catalog.namesForTargets(ids);

  /// Full food/dish vocabulary for background index builds.
  Future<List<String>> vocabularyKeys() => catalog.vocabularyKeys();

  /// Batched foods and servings, expanding dishes to all variants.
  Future<Map<String, List<CatalogFood>>> foodsByIds(Iterable<String> ids) =>
      catalog.foodsByIds(ids);

  /// The pack food with barcode [code], or null (the pack has no barcodes
  /// until local brands ship, A48).
  Future<CatalogFood?> byBarcode(String code) => catalog.byBarcode(code);

  /// Potential siblings, checked for compatibility by the loader.
  Future<List<CatalogFood>> foodsInYieldGroup(String group) =>
      catalog.foodsInYieldGroup(group);

  /// Pack yield factors, used only for the displayed note.
  Future<YieldConverter> yields() async =>
      YieldConverter(await catalog.yieldFactors());
}
