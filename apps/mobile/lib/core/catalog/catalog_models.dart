import 'package:fb_domain/fb_domain.dart';

export 'catalog_city.dart';

/// What a catalog food is (pack schema v1, A05 D5).
enum CatalogFoodKind {
  /// A USDA basic ingredient.
  basic,

  /// A variant of a reference dish.
  variant,
}

/// Where a catalog food's numbers come from, as the app labels it (FD-010,
/// A05 PA2): `usda` shows as the database badge, `reference` as the
/// reference badge.
enum CatalogBadge {
  /// A USDA FoodData Central basic.
  database,

  /// A researched reference dish.
  reference;

  /// The badge of a pack `source` value, or `null` for an unknown source.
  static CatalogBadge? fromSource(String source) => switch (source) {
    'usda' => database,
    'reference' => reference,
    _ => null,
  };
}

/// One food of the bundled catalog pack: a basic or a dish variant, with the
/// numbers per 100 g (or 100 ml) already computed by the catalog build.
final class CatalogFood {
  /// A food. [nutrients] are per 100 of [basis].
  const new({
    required this.id,
    required this.kind,
    required this.nameEn,
    required this.nameAr,
    required this.dishId,
    required this.state,
    required this.basis,
    required this.nutrients,
    required this.servingUnits,
    required this.densityGramsPerMl,
    required this.yieldGroup,
    required this.badge,
    required this.verified,
    required this.isDraft,
    required this.packVersion,
    this.sanity = CatalogSanity.ok,
    this.isDefaultVariant = false,
  });

  /// The catalog ID: `usda:...`, or `ref:<dish>/<variant>`.
  final String id;

  /// Basic or dish variant.
  final CatalogFoodKind kind;

  /// The English name.
  final String nameEn;

  /// The Arabic name, when the catalog has one.
  final String? nameAr;

  /// The dish a variant belongs to; `null` for a basic.
  final String? dishId;

  /// Raw, cooked, dry, ...
  final FoodState state;

  /// Per 100 g or per 100 ml.
  final NutrientBasis basis;

  /// Per 100 g or 100 ml, by [basis].
  final Nutrients nutrients;

  /// The food's own units (cup, plate, piece, ...), grams or ml each.
  final List<ServingUnit> servingUnits;

  /// Grams per millilitre, when known.
  final double? densityGramsPerMl;

  /// The FD-060 yield group (`rice`), when the food has one.
  final String? yieldGroup;

  /// The source badge (database or reference).
  final CatalogBadge badge;

  /// Whether a person checked the values against the source.
  final bool verified;

  /// A draft dish (only in dev packs built with drafts).
  final bool isDraft;

  /// The `catalog_version` of the pack this was read from.
  final int packVersion;

  /// Pack verdict, including reviewed waivers.
  final CatalogSanity sanity;

  /// Whether the dish selects this variant by default.
  final bool isDefaultVariant;

  /// The food's measures for the amount resolver.
  FoodMeasures get measures => FoodMeasures(
    basis: basis,
    servingUnits: servingUnits,
    densityGramsPerMl: densityGramsPerMl,
  );
}

/// One data source credited in the About screen (`meta.attribution`).
final class CatalogAttribution {
  /// Creates an entry.
  const new({
    required this.id,
    required this.name,
    required this.licence,
    required this.url,
    required this.credit,
    required this.usedFor,
    this.status = 'active',
  });

  /// Reads one `data/attribution.yaml` source entry.
  new fromJson(Map<String, Object?> json)
    : id = '${json['id']}',
      name = '${json['name']}',
      licence = '${json['licence']}',
      url = '${json['url']}',
      credit = '${json['credit']}',
      usedFor = '${json['used_for']}',
      status = json['status'] as String? ?? 'inactive';

  /// Stable source ID.
  final String id;

  /// Display name.
  final String name;

  /// Licence text.
  final String licence;

  /// Source URL.
  final String url;

  /// The credit line.
  final String credit;

  /// Pack source lifecycle; About includes only active sources.
  final String status;

  /// What the source is used for.
  final String usedFor;
}

/// The attached pack's version and credits.
final class CatalogInfo {
  /// Creates the info.
  const new({required this.packVersion, required this.attribution});

  /// The pack's `catalog_version`.
  final int packVersion;

  /// The credited sources.
  final List<CatalogAttribution> attribution;
}

/// The pack's stored sanity verdict (a waiver is not a computed failure).
/// The pack sanity verdict.
enum CatalogSanity {
  /// Passed the pack check.
  ok,

  /// Requires a displayed sanity note.
  warn,

  /// A reviewed override accepted the discrepancy.
  waived,
}

/// Ordered retrieval pass. Exact rows are never capped (PA10).
enum CandidatePass {
  /// Uncapped full-key equality.
  exact,

  /// Up to 500 full-key prefixes.
  prefix,

  /// Up to 300 rows ordered by matched-word count.
  token,
}

/// Already-normalized query and optional whole-word fuzzy corrections.
final class CandidateQuery {
  /// Creates this structured value.
  const new(this.key, {this.corrections = const {}});

  /// Normalized search key.
  final String key;

  /// Nearest whole-word corrections keyed by the original token.
  final Map<String, List<String>> corrections;
}

/// A name matched by a bounded retrieval pass.
final class CatalogNameRow {
  /// Creates this structured value.
  const new({
    required this.rowid,
    required this.targetId,
    required this.lang,
    required this.key,
    required this.isDisplay,
    required this.wordHits,
    required this.pass,
  });

  /// Stable SQLite name-row identity within this pack.
  final int rowid;

  /// Catalog food or dish target; exercises are excluded.
  final String targetId;

  /// Pack name language code.
  final String lang;

  /// Normalized search key.
  final String key;

  /// Whether this is a display name rather than an alias.
  final bool isDisplay;

  /// Number of query tokens matching word prefixes or fuzzy corrections.
  final int wordHits;

  /// Earliest retrieval pass that selected this row.
  final CandidatePass pass;
}
