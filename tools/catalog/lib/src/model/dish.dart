import 'package:fb_domain/fb_domain.dart';

/// Names per language (`en`, `ar`, `arabizi`); the first of each list is the
/// display name (A03 D5).
typedef Names = Map<String, List<String>>;

/// The languages a name list can be in.
const nameLanguages = ['en', 'ar', 'arabizi'];

/// A `[lo, hi]` pair from the YAML.
class Range {
  const new(this.lo, this.hi);

  final double lo;
  final double hi;

  bool contains(double value) => lo <= value && value <= hi;

  @override
  String toString() => '[${_n(lo)}, ${_n(hi)}]';
}

String _n(double v) => v == v.roundToDouble() ? v.toInt().toString() : '$v';

class RecipeItem {
  const new({required this.food, required this.grams, this.range});

  /// Catalog ID of the ingredient (`usda:...` or `ref:...`).
  final String food;
  final double grams;
  final Range? range;
}

class Portion {
  const new({required this.g, required this.range});

  final double g;
  final Range range;
}

/// A loggable form of a dish: either a recipe or a `per_100g` block.
class Variant {
  const new({
    required this.slug,
    required this.isDefault,
    required this.names,
    required this.portions,
    this.recipe,
    this.cookedTotalG,
    this.cookedTotalRange,
    this.per100g,
    this.nutrientSource,
    this.sanityOverrideReason,
  });

  /// The variant part of the catalog ID.
  final String slug;
  final bool isDefault;
  final Names names;
  final Map<String, Portion> portions;
  final List<RecipeItem>? recipe;
  final double? cookedTotalG;
  final Range? cookedTotalRange;
  final Nutrients? per100g;
  final String? nutrientSource;
  final String? sanityOverrideReason;
}

class Review {
  const new({
    required this.status,
    required this.reviewedBy,
    required this.sources,
    this.notes = '',
  });

  /// `draft` or `reviewed`.
  final String status;
  final String reviewedBy;
  final List<String> sources;
  final String notes;
}

class ReferenceDish {
  const new({
    required this.file,
    required this.id,
    required this.names,
    required this.state,
    required this.variants,
    required this.portions,
    required this.review,
    this.sanityOverrideReason,
    this.timeMin,
  });

  /// The YAML file it came from (for messages).
  final String file;

  /// `ref:<slug>`.
  final String id;
  final Names names;
  final FoodState state;
  final List<Variant> variants;
  final Map<String, Portion> portions;
  final Review review;
  final String? sanityOverrideReason;
  final double? timeMin;

  String get slug => id.substring('ref:'.length);

  bool get isDraft => review.status == 'draft';

  /// The catalog ID of [variant]: `ref:<slug>/<variant>`.
  String variantId(Variant variant) => '$id/${variant.slug}';

  Variant? get defaultVariant {
    for (final v in variants) {
      if (v.isDefault) return v;
    }
    return null;
  }
}

/// A USDA basic: the selection entry joined with its extract line.
class BasicFood {
  const new({
    required this.file,
    required this.index,
    required this.id,
    required this.names,
    required this.state,
    this.nutrients,
    this.sanityOverrideReason,
  });

  final String file;

  /// Position in the selection's `foods:` list.
  final int index;
  final String id;
  final Names names;
  final FoodState state;

  /// Per-100 g values from the extract; `null` when it has no line for [id].
  final Nutrients? nutrients;
  final String? sanityOverrideReason;
}
